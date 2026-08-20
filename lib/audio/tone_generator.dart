/// Runtime audio synthesis: reference tones and metronome clicks.
///
/// Pure Dart. No audio assets ship with the app — every sound is rendered
/// into an in-memory PCM16 WAV (44-byte header + data), which keeps the
/// binary small and the app fully offline.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../core/constants.dart';

/// Wraps PCM16 mono samples into a valid in-memory WAV file.
Uint8List pcm16ToWav(Int16List samples, {int sampleRate = kSampleRate}) {
  final dataLength = samples.length * 2;
  final bytes = Uint8List(44 + dataLength);
  final bd = ByteData.view(bytes.buffer);

  void writeAscii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes[offset + i] = s.codeUnitAt(i);
    }
  }

  writeAscii(0, 'RIFF');
  bd.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little); // fmt chunk size
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  bd.setUint16(32, 2, Endian.little); // block align
  bd.setUint16(34, 16, Endian.little); // bits per sample
  writeAscii(36, 'data');
  bd.setUint32(40, dataLength, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bd.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return bytes;
}

/// Renders a plucked-string-like reference tone: a sum of harmonics with
/// decaying amplitudes (1.0 / 0.5 / 0.25 / 0.12) and a click-free envelope
/// (10 ms attack, exponential decay, 50 ms release). A bare sine is much
/// harder to match by ear.
Int16List renderReferenceTone({
  required double frequencyHz,
  double seconds = 2.0,
  int sampleRate = kSampleRate,
  double gain = 0.45,
}) {
  const harmonicAmps = [1.0, 0.5, 0.25, 0.12];
  final n = (seconds * sampleRate).round();
  final attackSamples = (0.010 * sampleRate).round();
  final releaseSamples = (0.050 * sampleRate).round();
  final nyquistSafe = sampleRate * 0.45;
  final out = Int16List(n);

  // Normalization: worst-case peak is the sum of used harmonic amplitudes.
  var ampSum = 0.0;
  for (var k = 0; k < harmonicAmps.length; k++) {
    if (frequencyHz * (k + 1) < nyquistSafe) ampSum += harmonicAmps[k];
  }
  if (ampSum <= 0) ampSum = 1.0;
  final scale = gain / ampSum;
  final decayTau = seconds / 1.2;

  for (var i = 0; i < n; i++) {
    final tSec = i / sampleRate;
    var v = 0.0;
    for (var k = 0; k < harmonicAmps.length; k++) {
      final f = frequencyHz * (k + 1);
      if (f >= nyquistSafe) break;
      v += harmonicAmps[k] * math.sin(2.0 * math.pi * f * tSec);
    }
    var env = math.exp(-tSec / decayTau);
    if (i < attackSamples) env *= i / attackSamples;
    final tail = n - 1 - i;
    if (tail < releaseSamples) env *= tail / releaseSamples;
    out[i] = (v * scale * env * 32767.0).round().clamp(-32768, 32767).toInt();
  }
  return out;
}

/// Renders one or more bars of metronome clicks as a single loopable
/// buffer. Timing inside the buffer is sample-exact, which is why the
/// metronome does not use `Timer.periodic` for sound at all: the audio
/// pipeline clocks itself. The pattern is repeated until the buffer is at
/// least [minSeconds] long so that loop points are rare.
Int16List renderMetronomeBar({
  required int bpm,
  required int beatsPerBar,
  int subdivisions = 1,
  bool accentFirst = true,
  int sampleRate = kSampleRate,
  double minSeconds = 5.0,
}) {
  final samplesPerBeat = (sampleRate * 60.0 / bpm).round();
  final barSamples = samplesPerBeat * beatsPerBar;
  var bars = (minSeconds * sampleRate / barSamples).ceil();
  if (bars < 1) bars = 1;
  final out = Int16List(barSamples * bars);

  void addClick(int startSample, double freq, double amp) {
    const lengthSec = 0.040;
    const tau = 0.012;
    final len = (lengthSec * sampleRate).round();
    for (var i = 0; i < len; i++) {
      final idx = startSample + i;
      if (idx >= out.length) break;
      final tSec = i / sampleRate;
      var env = math.exp(-tSec / tau);
      if (i < 32) env *= i / 32.0; // click-free onset
      final v = amp * env * math.sin(2.0 * math.pi * freq * tSec);
      final mixed = out[idx] + (v * 32767.0).round();
      out[idx] = mixed.clamp(-32768, 32767).toInt();
    }
  }

  for (var bar = 0; bar < bars; bar++) {
    final barStart = bar * barSamples;
    for (var beat = 0; beat < beatsPerBar; beat++) {
      final beatStart = barStart + beat * samplesPerBeat;
      final isAccent = accentFirst && beat == 0;
      addClick(beatStart, isAccent ? 1760.0 : 1320.0, isAccent ? 0.85 : 0.6);
      for (var s = 1; s < subdivisions; s++) {
        final offset = (samplesPerBeat * s / subdivisions).round();
        addClick(beatStart + offset, 880.0, 0.3);
      }
    }
  }
  return out;
}

/// Absolute drift between the sample-quantized beat grid and the ideal
/// grid after [seconds] of playback, in milliseconds. Used by tests to
/// prove the metronome stays under 5 ms/min.
double metronomeDriftMs({
  required int bpm,
  required double seconds,
  int sampleRate = kSampleRate,
}) {
  final idealSamplesPerBeat = sampleRate * 60.0 / bpm;
  final actualSamplesPerBeat = idealSamplesPerBeat.roundToDouble();
  final beats = seconds * bpm / 60.0;
  final driftSamples = (actualSamplesPerBeat - idealSamplesPerBeat) * beats;
  return driftSamples.abs() / sampleRate * 1000.0;
}
