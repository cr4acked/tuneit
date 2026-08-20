import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneit/audio/pitch_detector.dart';
import 'package:tuneit/core/constants.dart';
import 'package:tuneit/core/note_utils.dart';

Float64List sine(double freq,
    {int n = kBufferSize, int sr = kSampleRate, double amp = 0.4}) {
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = amp * math.sin(2 * math.pi * freq * i / sr + 0.3);
  }
  return out;
}

/// Guitar-like pluck with strong 2nd/3rd harmonics — classic octave-error bait.
Float64List harmonics(double freq, {int n = kBufferSize, int sr = kSampleRate}) {
  const partials = [(1, 1.0), (2, 0.9), (3, 0.6), (4, 0.3), (5, 0.15)];
  final out = Float64List(n);
  var peak = 0.0;
  for (var i = 0; i < n; i++) {
    var v = 0.0;
    for (final (k, a) in partials) {
      v += a * math.sin(2 * math.pi * freq * k * i / sr + 0.1 * k);
    }
    out[i] = v;
    peak = math.max(peak, v.abs());
  }
  for (var i = 0; i < n; i++) {
    out[i] = 0.35 * out[i] / peak;
  }
  return out;
}

void main() {
  final yin = YinPitchDetector();

  test('pure sines: every string note B0..E4 within +/-1 cent', () {
    for (var midi = 23; midi <= 64; midi++) {
      final f = midiToHz(midi);
      final est = yin.detect(sine(f));
      expect(est.frequencyHz, isNotNull, reason: 'midi $midi: no pitch');
      final err = centsBetween(est.frequencyHz!, f);
      expect(err.abs(), lessThan(1.0),
          reason: 'midi $midi f=$f err=$err cents');
      expect(est.confidence, greaterThan(0.9));
    }
  });

  test('works at calibrated A4 = 435 and 445', () {
    for (final a4 in [435.0, 445.0]) {
      final f = midiToHz(40, a4Hz: a4);
      final est = yin.detect(sine(f));
      expect(centsBetween(est.frequencyHz!, f).abs(), lessThan(1.0));
    }
  });

  test('harmonic-rich low strings: no octave errors', () {
    for (final midi in [23, 26, 28, 30, 33, 35, 38, 40, 43, 45]) {
      final f = midiToHz(midi);
      final est = yin.detect(harmonics(f));
      expect(est.frequencyHz, isNotNull, reason: 'midi $midi');
      final err = centsBetween(est.frequencyHz!, f);
      // An octave error would be +/-1200 cents; require < 5.
      expect(err.abs(), lessThan(5.0),
          reason: 'midi $midi got ${est.frequencyHz}');
    }
  });

  test('sine + white noise at 20 dB SNR stays far from octave errors', () {
    final rng = math.Random(42);
    for (final midi in [28, 40, 45, 55]) {
      final f = midiToHz(midi);
      final buf = sine(f);
      final noiseAmp = 0.4 / math.sqrt(2) / 10.0; // ~20 dB below signal RMS
      for (var i = 0; i < buf.length; i++) {
        buf[i] += noiseAmp * (rng.nextDouble() * 2 - 1) * math.sqrt(3.0);
      }
      final est = yin.detect(buf);
      expect(est.frequencyHz, isNotNull);
      // Single-frame noise floor at this SNR is a few cents; the app's
      // median + EMA smoothing tightens it further. The hard requirement
      // here is "right note, right octave": a semitone error would be 100
      // cents and an octave error 1200.
      expect(centsBetween(est.frequencyHz!, f).abs(), lessThan(15.0),
          reason: 'midi $midi');
      expect(est.confidence, greaterThan(kMinConfidence));
    }
  });

  test('silence returns no tone', () {
    final est = yin.detect(Float64List(kBufferSize));
    expect(est.frequencyHz, isNull);
    expect(est.confidence, 0.0);
  });

  test('low-level noise is not reported as a confident pitch', () {
    final rng = math.Random(7);
    final buf = Float64List(kBufferSize);
    for (var i = 0; i < buf.length; i++) {
      buf[i] = (rng.nextDouble() * 2 - 1) * 1e-4;
    }
    final est = yin.detect(buf);
    // Either no pitch, or too low a confidence to pass the gate.
    expect(
      est.frequencyHz == null || est.confidence < kMinConfidence,
      isTrue,
    );
  });

  test('short buffer returns no tone', () {
    expect(yin.detect(Float64List(100)).frequencyHz, isNull);
  });
}
