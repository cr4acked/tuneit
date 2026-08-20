import 'package:flutter_test/flutter_test.dart';
import 'package:tuneit/data/instruments.dart';
import 'package:tuneit/data/models.dart';

void main() {
  test('catalog is not empty and covers all planned instruments', () {
    final ids = kInstruments.map((i) => i.id).toSet();
    expect(ids, {
      'guitar_6',
      'guitar_7',
      'guitar_8',
      'baritone_6',
      'guitar_12',
      'bass_4',
      'bass_5',
      'bass_6',
    });
  });

  test('every preset has the right number of notes', () {
    for (final inst in kInstruments) {
      for (final t in inst.tunings) {
        expect(t.midiNotes.length, inst.stringCount,
            reason: '${t.id} on ${inst.id}');
      }
    }
  });

  test('preset ids are globally unique', () {
    final seen = <String>{};
    for (final inst in kInstruments) {
      for (final t in inst.tunings) {
        expect(seen.add(t.id), isTrue, reason: 'duplicate id ${t.id}');
      }
    }
  });

  test('names are unique within each instrument', () {
    for (final inst in kInstruments) {
      final names = <String>{};
      for (final t in inst.tunings) {
        expect(names.add(t.name), isTrue,
            reason: 'duplicate name "${t.name}" in ${inst.id}');
      }
    }
  });

  test('notes ascend from thickest to thinnest (unless flagged)', () {
    for (final inst in kInstruments) {
      for (final t in inst.tunings) {
        if (t.nonMonotonic) continue;
        for (var i = 1; i < t.midiNotes.length; i++) {
          expect(t.midiNotes[i], greaterThan(t.midiNotes[i - 1]),
              reason: '${t.id}: ${t.fullLabel()}');
        }
      }
    }
  });

  test('all notes are in a playable range (F#0..E5)', () {
    for (final inst in kInstruments) {
      for (final t in inst.tunings) {
        for (final n in t.midiNotes) {
          expect(n, inInclusiveRange(18, 76), reason: t.id);
        }
      }
    }
  });

  test('every instrument has a standard tuning first in its list', () {
    for (final inst in kInstruments) {
      expect(inst.tunings.first.category, TuningCategory.standard,
          reason: inst.id);
    }
  });

  test('spot checks against known tunings', () {
    final g6 = instrumentById('guitar_6');
    expect(presetById(g6, 'guitar_6.standard_e')!.fullLabel(),
        'E2 A2 D3 G3 B3 E4');
    expect(presetById(g6, 'guitar_6.drop_c')!.fullLabel(),
        'C2 G2 C3 F3 A3 D4');
    expect(presetById(g6, 'guitar_6.dadgad')!.fullLabel(),
        'D2 A2 D3 G3 A3 D4');
    final b5 = instrumentById('bass_5');
    expect(presetById(b5, 'bass_5.standard_b')!.fullLabel(),
        'B0 E1 A1 D2 G2');
    final g7 = instrumentById('guitar_7');
    expect(presetById(g7, 'guitar_7.drop_a')!.fullLabel(),
        'A1 E2 A2 D3 G3 B3 E4');
  });

  test('drop tunings really drop the lowest string', () {
    for (final inst in kInstruments) {
      final standard = inst.tunings
          .firstWhere((t) => t.category == TuningCategory.standard);
      for (final t in inst.tunings.where(
        (t) => t.category == TuningCategory.drop && !t.id.contains('double'),
      )) {
        expect(t.midiNotes.first, lessThan(standard.midiNotes.first),
            reason: '${t.id} vs ${standard.id}');
      }
    }
  });
}
