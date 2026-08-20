/// YIN fundamental-frequency estimator.
///
/// Pure Dart (no Flutter imports) so it can run inside an isolate and in
/// fast unit tests. Implements the YIN algorithm (de Cheveigne & Kawahara,
/// 2002): difference function, cumulative mean normalized difference,
/// absolute threshold with local-minimum descent, and parabolic
/// interpolation of the lag. Plain autocorrelation or FFT peak picking is
/// deliberately avoided: both are prone to octave errors on low bass
/// strings (B0 and below).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../core/constants.dart';

class PitchEstimate {
  const PitchEstimate({
    required this.frequencyHz,
    required this.confidence,
    required this.rms,
  });

  /// Estimated fundamental in Hz, or null when no periodicity was found.
  final double? frequencyHz;

  /// 1 - d'(tau_best); close to 1 for clean periodic signals.
  final double confidence;

  /// Root mean square of the analyzed window (0..1 for normalized input).
  final double rms;

  static const PitchEstimate none =
      PitchEstimate(frequencyHz: null, confidence: 0.0, rms: 0.0);
}

class YinPitchDetector {
  YinPitchDetector({
    this.sampleRate = kSampleRate,
    this.bufferSize = kBufferSize,
    this.threshold = kYinThreshold,
    this.minFrequency = kMinFrequency,
    this.maxFrequency = kMaxFrequency,
  })  : _window = bufferSize ~/ 2,
        _cmnd = Float64List(bufferSize ~/ 2) {
    _maxTau = math.min(_window - 1, sampleRate ~/ minFrequency);
    _minTau = math.max(2, sampleRate ~/ maxFrequency);
  }

  final int sampleRate;
  final int bufferSize;
  final double threshold;
  final double minFrequency;
  final double maxFrequency;

  final int _window;
  final Float64List _cmnd;
  late final int _maxTau;
  late final int _minTau;

  /// Analyzes [buffer] (length >= [bufferSize], values ~[-1, 1]).
  PitchEstimate detect(Float64List buffer) {
    final n = bufferSize;
    if (buffer.length < n) return PitchEstimate.none;

    // RMS and mean (DC) over the analyzed window.
    var sum = 0.0;
    var sumSq = 0.0;
    for (var i = 0; i < n; i++) {
      final v = buffer[i];
      sum += v;
      sumSq += v * v;
    }
    final mean = sum / n;
    final rms = math.sqrt(math.max(0.0, sumSq / n - mean * mean));
    if (rms <= 1e-6) {
      return PitchEstimate(frequencyHz: null, confidence: 0.0, rms: rms);
    }

    // Difference function + cumulative mean normalized difference, computed
    // together to keep one pass per tau. d(tau) uses a window of length W.
    final w = _window;
    _cmnd[0] = 1.0;
    var runningSum = 0.0;
    var bestTau = -1;
    var bestValue = double.infinity;
    // The first contiguous region of lags whose CMND stays below the
    // threshold ("dip"). Tracking the minimum across the whole dip (instead
    // of stopping at the first local minimum) is what makes the estimate
    // robust to noise; stopping at the FIRST dip (not the global minimum)
    // is what prevents subharmonic/octave errors.
    var inDip = false;
    var dipTau = -1;
    var dipValue = double.infinity;

    for (var tau = 1; tau <= _maxTau; tau++) {
      var d = 0.0;
      for (var i = 0; i < w; i++) {
        final delta = (buffer[i] - mean) - (buffer[i + tau] - mean);
        d += delta * delta;
      }
      runningSum += d;
      final cmnd = runningSum > 0 ? d * tau / runningSum : 1.0;
      _cmnd[tau] = cmnd;

      if (tau >= _minTau) {
        if (cmnd < bestValue) {
          bestValue = cmnd;
          bestTau = tau;
        }
        if (cmnd < threshold) {
          inDip = true;
          if (cmnd < dipValue) {
            dipValue = cmnd;
            dipTau = tau;
          }
        } else if (inDip) {
          break; // first below-threshold dip ended
        }
      }
    }
    if (dipTau > 0) {
      bestTau = dipTau;
      bestValue = dipValue;
    }

    if (bestTau < 0) {
      return PitchEstimate(frequencyHz: null, confidence: 0.0, rms: rms);
    }

    final confidence = (1.0 - bestValue).clamp(0.0, 1.0).toDouble();

    // Parabolic interpolation around the minimum for sub-sample lag
    // precision; without it, low-note accuracy in cents is unacceptable.
    var tauEstimate = bestTau.toDouble();
    if (bestTau > _minTau && bestTau < _maxTau) {
      final s0 = _cmnd[bestTau - 1];
      final s1 = _cmnd[bestTau];
      final s2 = _cmnd[bestTau + 1];
      final denom = 2.0 * (s0 - 2.0 * s1 + s2);
      if (denom.abs() > 1e-12) {
        final adjustment = (s0 - s2) / denom;
        if (adjustment.abs() <= 1.0) {
          tauEstimate = bestTau + adjustment;
        }
      }
    }

    final frequency = sampleRate / tauEstimate;
    if (frequency < minFrequency || frequency > maxFrequency) {
      return PitchEstimate(frequencyHz: null, confidence: confidence, rms: rms);
    }
    return PitchEstimate(
      frequencyHz: frequency,
      confidence: confidence,
      rms: rms,
    );
  }
}
