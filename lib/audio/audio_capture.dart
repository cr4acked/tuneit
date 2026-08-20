import 'dart:typed_data';

import 'package:record/record.dart';

import '../core/constants.dart';

/// Thin wrapper around the `record` plugin: raw PCM16 mono stream at 44.1 kHz.
/// AGC / echo cancellation / noise suppression are disabled — they distort
/// exactly the signal a tuner needs.
class AudioCapture {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<Stream<Uint8List>> start() {
    return _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: kSampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
  }

  Future<void> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}
