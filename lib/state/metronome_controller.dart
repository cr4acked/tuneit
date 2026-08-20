import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/metronome_engine.dart';
import '../core/constants.dart';

class TimeSignature {
  const TimeSignature(this.beats, this.unit);

  final int beats;
  final int unit;

  String get label => '$beats/$unit';
}

const kTimeSignatures = [
  TimeSignature(2, 4),
  TimeSignature(3, 4),
  TimeSignature(4, 4),
  TimeSignature(5, 4),
  TimeSignature(6, 8),
  TimeSignature(7, 8),
  TimeSignature(12, 8),
];

class MetronomeController extends ChangeNotifier {
  MetronomeController() : _engine = MetronomeEngine();

  final MetronomeEngine _engine;

  int _bpm = 120;
  int get bpm => _bpm;

  TimeSignature _signature = kTimeSignatures[2]; // 4/4
  TimeSignature get signature => _signature;

  int _subdivisions = 1;
  int get subdivisions => _subdivisions;

  bool _accentFirst = true;
  bool get accentFirst => _accentFirst;

  bool _hapticPulse = false;
  bool get hapticPulse => _hapticPulse;

  bool _running = false;
  bool get isRunning => _running;

  int _visualBeat = 0;
  int get visualBeat => _visualBeat;

  Timer? _uiTimer; // visual pulse only; audio timing lives in the engine
  Timer? _restartDebounce;
  final List<int> _tapTimesMs = [];
  final Stopwatch _tapWatch = Stopwatch()..start();

  set bpm(int value) {
    _bpm = value.clamp(kBpmMin, kBpmMax).toInt();
    _scheduleRestart();
    notifyListeners();
  }

  set signature(TimeSignature value) {
    _signature = value;
    _scheduleRestart();
    notifyListeners();
  }

  set subdivisions(int value) {
    _subdivisions = value.clamp(1, 4).toInt();
    _scheduleRestart();
    notifyListeners();
  }

  set accentFirst(bool value) {
    _accentFirst = value;
    _scheduleRestart();
    notifyListeners();
  }

  set hapticPulse(bool value) {
    _hapticPulse = value;
    notifyListeners();
  }

  /// Tap tempo: average interval over the last 4 taps.
  void tap() {
    final now = _tapWatch.elapsedMilliseconds;
    if (_tapTimesMs.isNotEmpty && now - _tapTimesMs.last > 2500) {
      _tapTimesMs.clear();
    }
    _tapTimesMs.add(now);
    while (_tapTimesMs.length > 4) {
      _tapTimesMs.removeAt(0);
    }
    if (_tapTimesMs.length >= 2) {
      final span = _tapTimesMs.last - _tapTimesMs.first;
      final avgMs = span / (_tapTimesMs.length - 1);
      if (avgMs > 0) {
        bpm = (60000.0 / avgMs).round();
      }
    }
  }

  Future<void> toggle() => _running ? stop() : start();

  Future<void> start() async {
    _running = true;
    notifyListeners();
    await _engine.start(
      bpm: _bpm,
      beatsPerBar: _signature.beats,
      subdivisions: _subdivisions,
      accentFirst: _accentFirst,
    );
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final beat = _engine.currentBeat(bpm: _bpm, beatsPerBar: _signature.beats);
      if (beat != _visualBeat) {
        _visualBeat = beat;
        if (_hapticPulse) {
          if (beat == 0 && _accentFirst) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.lightImpact();
          }
        }
        notifyListeners();
      }
    });
  }

  Future<void> stop() async {
    _running = false;
    _uiTimer?.cancel();
    _uiTimer = null;
    _restartDebounce?.cancel();
    _visualBeat = 0;
    notifyListeners();
    await _engine.stop();
  }

  void _scheduleRestart() {
    if (!_running) return;
    _restartDebounce?.cancel();
    _restartDebounce = Timer(const Duration(milliseconds: 250), () {
      if (_running) start();
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _restartDebounce?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
