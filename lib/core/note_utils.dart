/// Note math: MIDI <-> Hz <-> names, cents.
///
/// Pure Dart: no Flutter imports. All frequencies are computed from the
/// calibrated A4, never hardcoded, so changing A4 shifts every tuning.
library;

import 'dart:math' as math;

const List<String> kSharpNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

const List<String> kFlatNames = [
  'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
];

/// f(midi) = a4 * 2^((midi - 69) / 12)
double midiToHz(num midi, {double a4Hz = 440.0}) {
  return a4Hz * math.pow(2.0, (midi - 69) / 12.0).toDouble();
}

/// Fractional MIDI number for a frequency.
double hzToMidi(double hz, {double a4Hz = 440.0}) {
  return 69.0 + 12.0 * (math.log(hz / a4Hz) / math.ln2);
}

/// Nearest MIDI note for a frequency.
int nearestMidi(double hz, {double a4Hz = 440.0}) {
  return hzToMidi(hz, a4Hz: a4Hz).round();
}

/// Signed offset of [detectedHz] from [targetHz] in cents.
double centsBetween(double detectedHz, double targetHz) {
  return 1200.0 * (math.log(detectedHz / targetHz) / math.ln2);
}

/// Scientific pitch name, e.g. midi 40 -> "E2", midi 61 -> "C#4" / "Db4".
String midiNoteName(int midi, {bool flats = false}) {
  final names = flats ? kFlatNames : kSharpNames;
  return '${names[midi % 12]}${(midi ~/ 12) - 1}';
}

/// Note letter without octave, e.g. midi 61 -> "C#".
String midiPitchClass(int midi, {bool flats = false}) {
  final names = flats ? kFlatNames : kSharpNames;
  return names[midi % 12];
}

/// Octave part of the scientific name, e.g. midi 40 -> 2.
int midiOctave(int midi) => (midi ~/ 12) - 1;

/// Parses "E2", "A#1", "Db3" into a MIDI number. Returns null on bad input.
int? parseNote(String text) {
  final match = RegExp(r'^([A-Ga-g])([#b]?)(-?\d)$').firstMatch(text.trim());
  if (match == null) return null;
  const base = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  var semitone = base[match.group(1)!.toUpperCase()]!;
  final accidental = match.group(2)!;
  if (accidental == '#') semitone += 1;
  if (accidental == 'b') semitone -= 1;
  final octave = int.parse(match.group(3)!);
  final midi = 12 * (octave + 1) + semitone;
  return (midi >= 0 && midi <= 127) ? midi : null;
}

/// Parses a space-separated list, e.g. "E2 A2 D3 G3 B3 E4".
List<int> parseNotes(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map((s) {
        final midi = parseNote(s);
        if (midi == null) {
          throw FormatException('Bad note "$s" in "$text"');
        }
        return midi;
      })
      .toList(growable: false);
}
