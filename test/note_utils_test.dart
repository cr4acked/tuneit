import 'package:flutter_test/flutter_test.dart';
import 'package:tuneit/core/note_utils.dart';

void main() {
  group('midi <-> Hz', () {
    test('A4 = 440 by default', () {
      expect(midiToHz(69), closeTo(440.0, 1e-9));
    });

    test('E2 (guitar low E)', () {
      expect(midiToHz(40), closeTo(82.4069, 1e-3));
    });

    test('B0 (5-string bass)', () {
      expect(midiToHz(23), closeTo(30.8677, 1e-3));
    });

    test('round trip midi -> hz -> midi for all playable notes', () {
      for (var midi = 12; midi <= 100; midi++) {
        final hz = midiToHz(midi);
        expect(hzToMidi(hz), closeTo(midi.toDouble(), 1e-9));
        expect(nearestMidi(hz), midi);
      }
    });

    test('A4 calibration shifts everything proportionally', () {
      for (final a4 in [435.0, 437.5, 442.0, 445.0]) {
        expect(midiToHz(69, a4Hz: a4), closeTo(a4, 1e-9));
        // E2 keeps the same ratio to A4.
        expect(
          midiToHz(40, a4Hz: a4) / midiToHz(69, a4Hz: a4),
          closeTo(midiToHz(40) / 440.0, 1e-12),
        );
      }
    });
  });

  group('cents', () {
    test('same frequency -> 0 cents', () {
      expect(centsBetween(440, 440), closeTo(0, 1e-12));
    });

    test('semitone = 100 cents', () {
      expect(centsBetween(midiToHz(70), midiToHz(69)), closeTo(100, 1e-9));
    });

    test('octave = 1200 cents', () {
      expect(centsBetween(880, 440), closeTo(1200, 1e-9));
    });

    test('flat string is negative', () {
      expect(centsBetween(80, midiToHz(40)), lessThan(0));
    });
  });

  group('note names', () {
    test('sharps', () {
      expect(midiNoteName(40), 'E2');
      expect(midiNoteName(61), 'C#4');
      expect(midiNoteName(23), 'B0');
      expect(midiNoteName(34), 'A#1');
    });

    test('flats', () {
      expect(midiNoteName(61, flats: true), 'Db4');
      expect(midiNoteName(34, flats: true), 'Bb1');
    });

    test('octave boundaries', () {
      expect(midiNoteName(12), 'C0');
      expect(midiNoteName(11), 'B-1');
      expect(midiOctave(69), 4);
    });
  });

  group('parseNote', () {
    test('parses valid notes', () {
      expect(parseNote('E2'), 40);
      expect(parseNote('A#1'), 34);
      expect(parseNote('Db4'), 61);
      expect(parseNote('B0'), 23);
      expect(parseNote('C#3'), 49);
    });

    test('round trips names', () {
      for (var midi = 12; midi <= 100; midi++) {
        expect(parseNote(midiNoteName(midi)), midi);
        expect(parseNote(midiNoteName(midi, flats: true)), midi);
      }
    });

    test('rejects garbage', () {
      expect(parseNote('H2'), isNull);
      expect(parseNote('E'), isNull);
      expect(parseNote(''), isNull);
      expect(parseNote('X#9'), isNull);
    });

    test('parseNotes parses a tuning line', () {
      expect(parseNotes('E2 A2 D3 G3 B3 E4'), [40, 45, 50, 55, 59, 64]);
      expect(() => parseNotes('E2 XX'), throwsFormatException);
    });
  });
}
