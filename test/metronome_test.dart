import 'package:flutter_test/flutter_test.dart';
import 'package:tuneit/audio/tone_generator.dart';
import 'package:tuneit/core/constants.dart';

void main() {
  test('drift stays under 5 ms per minute for every BPM 30..300', () {
    for (var bpm = kBpmMin; bpm <= kBpmMax; bpm++) {
      final drift = metronomeDriftMs(bpm: bpm, seconds: 60.0);
      expect(drift, lessThan(5.0), reason: 'bpm $bpm drift $drift ms');
    }
  });

  test('bar buffer length is sample-exact', () {
    for (final (bpm, beats) in [(60, 4), (120, 3), (177, 7), (300, 2)]) {
      final samplesPerBeat = (kSampleRate * 60.0 / bpm).round();
      final bar = renderMetronomeBar(
        bpm: bpm,
        beatsPerBar: beats,
        minSeconds: 0, // single bar
      );
      expect(bar.length % (samplesPerBeat * beats), 0,
          reason: 'bpm $bpm beats $beats');
    }
  });

  test('buffer repeats to at least minSeconds', () {
    final bar = renderMetronomeBar(bpm: 240, beatsPerBar: 2, minSeconds: 5.0);
    expect(bar.length, greaterThanOrEqualTo(5.0 * kSampleRate));
  });

  test('accented first beat is louder than the others', () {
    final samplesPerBeat = (kSampleRate * 60.0 / 120).round();
    final bar = renderMetronomeBar(
      bpm: 120,
      beatsPerBar: 4,
      accentFirst: true,
      minSeconds: 0,
    );
    int peakAt(int start) {
      var p = 0;
      for (var i = start; i < start + 2000 && i < bar.length; i++) {
        if (bar[i].abs() > p) p = bar[i].abs();
      }
      return p;
    }

    expect(peakAt(0), greaterThan(peakAt(samplesPerBeat)));
  });

  test('subdivisions add clicks between beats', () {
    final samplesPerBeat = (kSampleRate * 60.0 / 120).round();
    final plain = renderMetronomeBar(
      bpm: 120,
      beatsPerBar: 2,
      subdivisions: 1,
      minSeconds: 0,
    );
    final eighths = renderMetronomeBar(
      bpm: 120,
      beatsPerBar: 2,
      subdivisions: 2,
      minSeconds: 0,
    );
    final mid = samplesPerBeat ~/ 2;
    int peakAround(List<int> buf, int center) {
      var p = 0;
      for (var i = center; i < center + 1000 && i < buf.length; i++) {
        if (buf[i].abs() > p) p = buf[i].abs();
      }
      return p;
    }

    expect(peakAround(eighths, mid), greaterThan(peakAround(plain, mid) + 500));
  });

  test('no clipping even where clicks overlap', () {
    final bar = renderMetronomeBar(
      bpm: 300,
      beatsPerBar: 12,
      subdivisions: 4,
      minSeconds: 0,
    );
    for (final s in bar) {
      expect(s, inInclusiveRange(-32768, 32767));
    }
  });
}
