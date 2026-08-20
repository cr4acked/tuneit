import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Feeds an in-memory WAV buffer to just_audio without touching the disk.
class WavAudioSource extends StreamAudioSource {
  WavAudioSource(this._bytes) : super(tag: 'in-memory-wav');

  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(_bytes.sublist(from, to)),
      contentType: 'audio/wav',
    );
  }
}
