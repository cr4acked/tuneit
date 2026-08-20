import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneit/audio/tone_generator.dart';
import 'package:tuneit/core/constants.dart';

void main() {
  group('WAV container', () {
    test('header is valid RIFF/WAVE PCM16 mono', () {
      final samples = Int16List.fromList(List.filled(1000, 123));
      final wav = pcm16ToWav(samples);
      expect(wav.length, 44 + 2000);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
      final bd = ByteData.view(wav.buffer);
      expect(bd.getUint32(4, Endian.little), 36 + 2000); // RIFF size
      expect(bd.getUint16(20, Endian.little), 1); // PCM
      expect(bd.getUint16(22, Endian.little), 1); // mono
      expect(bd.getUint32(24, Endian.little), kSampleRate);
      expect(bd.getUint32(28, Endian.little), kSampleRate * 2); // byte rate
      expect(bd.getUint16(32, Endian.little), 2); // block align
      expect(bd.getUint16(34, Endian.little), 16); // bits
      expect(bd.getUint32(40, Endian.little), 2000); // data size
      // Payload round-trips.
      expect(bd.getInt16(44, Endian.little), 123);
    });
  });

  group('reference tone', () {
    test('length matches requested duration', () {
      final tone = renderReferenceTone(frequencyHz: 110, seconds: 2.0);
      expect(tone.length, (2.0 * kSampleRate).round());
    });

    test('no clipping and click-free edges', () {
      final tone = renderReferenceTone(frequencyHz: 82.4069);
      var peak = 0;
      for (final s in tone) {
        if (s.abs() > peak) peak = s.abs();
      }
      expect(peak, lessThanOrEqualTo(32767));
      expect(peak, greaterThan(3000)); // audible
      expect(tone.first.abs(), lessThan(300));
      expect(tone.last.abs(), lessThan(300));
    });

    test('fundamental period is present (autocorrelation sanity)', () {
      const freq = 110.0;
      final tone = renderReferenceTone(frequencyHz: freq, seconds: 0.5);
      final period = (kSampleRate / freq).round();
      // Compare the signal to itself shifted by one period over 4 periods.
      var num = 0.0;
      var den = 0.0;
      for (var i = 0; i < period * 4; i++) {
        num += tone[i] * tone[i + period] * 1.0;
        den += tone[i] * tone[i] * 1.0;
      }
      expect(num / den, greaterThan(0.7));
    });

    test('very high fundamental drops inaudible harmonics gracefully', () {
      final tone = renderReferenceTone(frequencyHz: 1300, seconds: 0.1);
      var peak = 0;
      for (final s in tone) {
        if (s.abs() > peak) peak = s.abs();
      }
      expect(peak, lessThanOrEqualTo(32767));
      expect(peak, greaterThan(1000));
    });
  });
}
