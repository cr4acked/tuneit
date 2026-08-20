import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_capture.dart';
import '../audio/pitch_detector.dart';
import '../audio/pitch_isolate.dart';
import '../audio/tone_generator.dart';
import '../audio/wav_audio_source.dart';
import '../core/constants.dart';
import '../core/note_utils.dart';
import '../data/custom_tunings_repository.dart';
import '../data/instruments.dart';
import '../data/models.dart';
import 'settings_controller.dart';

enum TunerStatus { idle, starting, listening, denied }

enum TunerMode { auto, manual, chromatic }

/// Central tuner state machine: microphone -> isolate -> smoothed pitch ->
/// target selection -> gauge state. All DSP happens off the UI thread; this
/// controller only consumes ready [PitchEstimate]s (also injectable in
/// tests via [ingest]).
class TunerController extends ChangeNotifier {
  TunerController({
    required this.settings,
    required CustomTuningsRepository customRepo,
    this.microphoneAvailable = true,
  }) : _customRepo = customRepo {
    _customTunings = _customRepo.load();
    _restoreLastSelection();
    settings.addListener(_onSettingsChanged);
  }

  final SettingsController settings;
  final CustomTuningsRepository _customRepo;

  /// False in headless/widget tests: [start] then skips all platform work
  /// while [ingest] keeps functioning.
  final bool microphoneAvailable;

  // -- Audio plumbing -------------------------------------------------------

  AudioCapture? _capture;
  PitchEngine? _engine;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<PitchEstimate>? _resultSub;
  // Created lazily: keeps construction platform-free (unit/widget tests).
  AudioPlayer? _tonePlayer;
  StreamSubscription<PlayerState>? _toneStateSub;

  // -- Public state ---------------------------------------------------------

  TunerStatus status = TunerStatus.idle;
  TunerMode mode = TunerMode.auto;

  late InstrumentType instrument;
  late TuningPreset tuning;
  List<TuningPreset> _customTunings = [];
  List<TuningPreset> get customTunings => List.unmodifiable(_customTunings);

  int manualStringIndex = 0;

  /// Smoothed detected frequency, or null when no reliable signal.
  double? displayHz;

  /// Offset from the target in cents (unclamped), or null.
  double? displayCents;

  /// MIDI note currently targeted, or null.
  int? targetMidi;

  /// Index of the string being tuned (null in chromatic mode / no signal).
  int? activeStringIndex;

  /// Strings already brought in tune during this session.
  final Set<int> tunedStrings = <int>{};

  /// Which string's reference tone is playing, if any.
  int? playingToneIndex;

  bool get hasSignal => displayHz != null;

  bool get isInTune =>
      displayCents != null && displayCents!.abs() <= settings.inTuneCents;

  // -- Smoothing state ------------------------------------------------------

  final List<double> _median = [];
  double? _ema;
  int _emptyFrames = 0;
  int _inTuneStreak = 0;
  bool _wasInTune = false;
  int? _lastTargetMidi;

  // -- Lifecycle ------------------------------------------------------------

  void _restoreLastSelection() {
    final repo = settings.repo;
    instrument = instrumentById(repo.lastInstrumentId ?? 'guitar_6');
    final saved = repo.lastTuningId;
    tuning = (saved != null
            ? presetById(instrument, saved) ?? _customById(saved)
            : null) ??
        instrument.tunings.first;
  }

  TuningPreset? _customById(String id) {
    for (final t in _customTunings) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _onSettingsChanged() {
    // A4 changed -> cents shift; just repaint from current values.
    notifyListeners();
  }

  /// Test hook: force a status without touching any platform channel.
  @visibleForTesting
  void debugSetStatus(TunerStatus value) {
    status = value;
    notifyListeners();
  }

  Future<void> start() async {
    if (!microphoneAvailable) return;
    if (status == TunerStatus.listening || status == TunerStatus.starting) {
      return;
    }
    status = TunerStatus.starting;
    notifyListeners();
    try {
      _capture ??= AudioCapture();
      final granted = await _capture!.hasPermission();
      if (!granted) {
        status = TunerStatus.denied;
        notifyListeners();
        return;
      }
      _engine ??= await PitchEngine.spawn();
      _resultSub ??= _engine!.results.listen(ingest);
      final stream = await _capture!.start();
      final engine = _engine!;
      _micSub = stream.listen(engine.addPcm16);
      status = TunerStatus.listening;
    } catch (_) {
      // Missing plugin (tests) or platform failure: degrade gracefully,
      // reference tones remain available.
      status = TunerStatus.denied;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _capture?.stop();
    } catch (_) {}
    if (status != TunerStatus.denied) status = TunerStatus.idle;
    _resetSmoothing();
    displayHz = null;
    displayCents = null;
    activeStringIndex = null;
    notifyListeners();
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    _micSub?.cancel();
    _resultSub?.cancel();
    _toneStateSub?.cancel();
    _engine?.dispose();
    _capture?.dispose();
    _tonePlayer?.dispose();
    super.dispose();
  }

  // -- Selection ------------------------------------------------------------

  void selectTuning(InstrumentType newInstrument, TuningPreset newTuning) {
    instrument = newInstrument;
    tuning = newTuning;
    manualStringIndex = 0;
    tunedStrings.clear();
    _resetSmoothing();
    settings.repo.saveLastSelection(newInstrument.id, newTuning.id);
    settings.repo.pushRecent(newInstrument.id, newTuning.id);
    notifyListeners();
  }

  void setMode(TunerMode newMode) {
    mode = newMode;
    _resetSmoothing();
    notifyListeners();
  }

  void selectString(int index) {
    manualStringIndex = index;
    mode = TunerMode.manual;
    _resetSmoothing();
    notifyListeners();
  }

  // -- Custom tunings -------------------------------------------------------

  Future<void> saveCustomTuning(TuningPreset preset) async {
    final index = _customTunings.indexWhere((t) => t.id == preset.id);
    if (index >= 0) {
      _customTunings[index] = preset;
    } else {
      _customTunings = [..._customTunings, preset];
    }
    await _customRepo.save(_customTunings);
    notifyListeners();
  }

  Future<void> deleteCustomTuning(String id) async {
    _customTunings = _customTunings.where((t) => t.id != id).toList();
    await _customRepo.save(_customTunings);
    if (tuning.id == id) {
      tuning = instrument.tunings.first;
    }
    notifyListeners();
  }

  List<TuningPreset> customTuningsFor(InstrumentType inst) {
    return _customTunings
        .where((t) => t.stringCount == inst.stringCount)
        .toList();
  }

  // -- Reference tones ------------------------------------------------------

  Future<void> toggleReferenceTone(int stringIndex) async {
    if (playingToneIndex == stringIndex) {
      await stopReferenceTone();
      return;
    }
    final midi = tuning.midiNotes[stringIndex];
    final hz = midiToHz(midi, a4Hz: settings.a4Hz);
    playingToneIndex = stringIndex;
    notifyListeners();
    try {
      final player = _tonePlayer ??= AudioPlayer();
      final wav = pcm16ToWav(renderReferenceTone(frequencyHz: hz));
      _toneStateSub ??= player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          playingToneIndex = null;
          notifyListeners();
        }
      });
      await player.stop();
      await player.setAudioSource(WavAudioSource(wav));
      unawaited(player.play());
    } catch (_) {
      playingToneIndex = null;
      notifyListeners();
    }
  }

  Future<void> stopReferenceTone() async {
    if (playingToneIndex != null) {
      playingToneIndex = null;
      notifyListeners();
    }
    try {
      await _tonePlayer?.stop();
    } catch (_) {}
  }

  // -- Pitch pipeline -------------------------------------------------------

  void _resetSmoothing() {
    _median.clear();
    _ema = null;
    _emptyFrames = 0;
    _inTuneStreak = 0;
    _wasInTune = false;
    _lastTargetMidi = null;
  }

  /// Consumes one pitch estimate. Public so widget tests can drive the
  /// tuner without a microphone.
  void ingest(PitchEstimate estimate) {
    // While a reference tone plays, ignore the mic: the tuner must not
    // measure its own speaker output.
    if (playingToneIndex != null) return;

    final gate = settings.gateRms;
    final hz = estimate.frequencyHz;
    if (hz == null || estimate.confidence < kMinConfidence ||
        estimate.rms < gate) {
      _emptyFrames++;
      if (_emptyFrames > 6 && displayHz != null) {
        displayHz = null;
        displayCents = null;
        activeStringIndex = null;
        _resetSmoothing();
        notifyListeners();
      }
      return;
    }
    _emptyFrames = 0;

    // Median-of-3 to kill single-frame outliers, then EMA for the needle.
    _median.add(hz);
    if (_median.length > kMedianWindow) _median.removeAt(0);
    final sorted = [..._median]..sort();
    final med = sorted[sorted.length ~/ 2];
    if (_ema == null || centsBetween(med, _ema!).abs() > 120) {
      // New note (or first frame): snap instead of gliding, so the needle
      // reacts within one hop (< 150 ms).
      _ema = med;
    } else {
      _ema = _ema! + kSmoothingAlpha * (med - _ema!);
    }
    final smoothHz = _ema!;
    displayHz = smoothHz;

    final a4 = settings.a4Hz;
    switch (mode) {
      case TunerMode.chromatic:
        targetMidi = nearestMidi(smoothHz, a4Hz: a4);
        activeStringIndex = null;
      case TunerMode.manual:
        activeStringIndex = manualStringIndex;
        targetMidi = tuning.midiNotes[manualStringIndex];
      case TunerMode.auto:
        var bestIndex = 0;
        var bestAbsCents = double.infinity;
        for (var i = 0; i < tuning.midiNotes.length; i++) {
          final c =
              centsBetween(smoothHz, midiToHz(tuning.midiNotes[i], a4Hz: a4))
                  .abs();
          if (c < bestAbsCents) {
            bestAbsCents = c;
            bestIndex = i;
          }
        }
        activeStringIndex = bestIndex;
        targetMidi = tuning.midiNotes[bestIndex];
    }

    displayCents = centsBetween(smoothHz, midiToHz(targetMidi!, a4Hz: a4));

    if (targetMidi != _lastTargetMidi) {
      _inTuneStreak = 0;
      _wasInTune = false;
      _lastTargetMidi = targetMidi;
    }

    final inTune = displayCents!.abs() <= settings.inTuneCents;
    if (inTune) {
      _inTuneStreak++;
      if (!_wasInTune) {
        _wasInTune = true;
        if (settings.haptic) {
          HapticFeedback.mediumImpact();
        }
      }
      if (_inTuneStreak >= kTunedFramesRequired &&
          activeStringIndex != null) {
        tunedStrings.add(activeStringIndex!);
      }
    } else {
      _inTuneStreak = 0;
      _wasInTune = false;
    }

    notifyListeners();
  }
}
