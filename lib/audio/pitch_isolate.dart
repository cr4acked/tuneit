/// Long-lived analysis isolate.
///
/// The UI isolate forwards raw PCM16 chunks here; this isolate decodes,
/// high-pass filters, windows the signal (4096 samples, 50% hop) and runs
/// YIN, sending back compact `[hz, confidence, rms]` triples. The UI thread
/// never does DSP work.
library;

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../core/constants.dart';
import 'pitch_detector.dart';

class PitchEngine {
  PitchEngine._(this._isolate, this._commands, this._results, this._port);

  final Isolate _isolate;
  final SendPort _commands;
  final StreamController<PitchEstimate> _results;
  final ReceivePort _port;

  Stream<PitchEstimate> get results => _results.stream;

  static Future<PitchEngine> spawn() async {
    final port = ReceivePort();
    final results = StreamController<PitchEstimate>.broadcast();
    final ready = Completer<SendPort>();

    port.listen((Object? message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
      } else if (message is Float64List && message.length == 3) {
        if (!results.isClosed) {
          results.add(
            PitchEstimate(
              frequencyHz: message[0] < 0 ? null : message[0],
              confidence: message[1],
              rms: message[2],
            ),
          );
        }
      }
    });

    final isolate = await Isolate.spawn(
      _isolateMain,
      port.sendPort,
      debugName: 'pitch-analysis',
    );
    final commands = await ready.future;
    return PitchEngine._(isolate, commands, results, port);
  }

  /// Forwards a raw PCM16 little-endian chunk from the recorder.
  void addPcm16(Uint8List bytes) => _commands.send(bytes);

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _port.close();
    _results.close();
  }
}

void _isolateMain(SendPort main) {
  final port = ReceivePort();
  main.send(port.sendPort);

  final detector = YinPitchDetector();
  // Sample queue between hops. Grows by incoming chunks, shrinks by kHopSize.
  final queue = <double>[];
  final window = Float64List(kBufferSize);
  int? pendingByte;

  // One-pole DC-blocking high-pass (~20 Hz): y[n] = x[n] - x[n-1] + r*y[n-1].
  const r = 0.99715;
  var prevX = 0.0;
  var prevY = 0.0;

  port.listen((Object? message) {
    if (message is! Uint8List) return;
    var bytes = message;
    if (pendingByte != null) {
      final joined = Uint8List(bytes.length + 1);
      joined[0] = pendingByte!;
      joined.setRange(1, joined.length, bytes);
      bytes = joined;
      pendingByte = null;
    }
    final evenLength = bytes.length & ~1;
    if (evenLength != bytes.length) pendingByte = bytes[bytes.length - 1];

    final bd = ByteData.view(bytes.buffer, bytes.offsetInBytes, evenLength);
    for (var i = 0; i < evenLength; i += 2) {
      final x = bd.getInt16(i, Endian.little) / 32768.0;
      final y = x - prevX + r * prevY;
      prevX = x;
      prevY = y;
      queue.add(y);
    }

    while (queue.length >= kBufferSize) {
      for (var i = 0; i < kBufferSize; i++) {
        window[i] = queue[i];
      }
      final est = detector.detect(window);
      main.send(
        Float64List.fromList(
          [est.frequencyHz ?? -1.0, est.confidence, est.rms],
        ),
      );
      queue.removeRange(0, kHopSize);
    }
  });
}
