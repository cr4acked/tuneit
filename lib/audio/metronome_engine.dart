import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'tone_generator.dart';
import 'wav_audio_source.dart';

/// Metronome playback.
///
/// Sound timing never touches Dart timers: the whole pattern (several bars,
/// >= 5 s) is rendered as one sample-exact PCM buffer and looped by the
/// audio engine, so drift is bounded by beat-length rounding (< 5 ms/min,
/// proven in tests). A [Stopwatch] provides the visual beat phase only.
class MetronomeEngine {
  // Created lazily so constructing the engine never touches the platform.
  AudioPlayer? _player;
  final Stopwatch _stopwatch = Stopwatch();

  bool _running = false;
  bool get isRunning => _running;

  Future<void> start({
    required int bpm,
    required int beatsPerBar,
    required int subdivisions,
    required bool accentFirst,
  }) async {
    final samples = renderMetronomeBar(
      bpm: bpm,
      beatsPerBar: beatsPerBar,
      subdivisions: subdivisions,
      accentFirst: accentFirst,
    );
    final wav = pcm16ToWav(samples);
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setAudioSource(WavAudioSource(wav));
    await player.setLoopMode(LoopMode.one);
    _stopwatch
      ..reset()
      ..start();
    _running = true;
    unawaited(player.play());
  }

  Future<void> stop() async {
    _running = false;
    _stopwatch.stop();
    await _player?.stop();
  }

  /// Beat index [0, beatsPerBar) for the visual pulse.
  int currentBeat({required int bpm, required int beatsPerBar}) {
    if (!_running) return 0;
    final beatMs = 60000.0 / bpm;
    return (_stopwatch.elapsedMilliseconds / beatMs).floor() % beatsPerBar;
  }

  Future<void> dispose() async {
    await _player?.dispose();
  }
}
