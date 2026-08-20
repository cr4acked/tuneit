/// Static instrument catalog. Pure Dart.
library;

import 'models.dart';
import 'tunings/baritone.dart';
import 'tunings/bass_4.dart';
import 'tunings/bass_5.dart';
import 'tunings/bass_6.dart';
import 'tunings/guitar_12.dart';
import 'tunings/guitar_6.dart';
import 'tunings/guitar_7.dart';
import 'tunings/guitar_8.dart';

final List<InstrumentType> kInstruments = [
  InstrumentType(id: 'guitar_6', stringCount: 6, tunings: guitar6Tunings),
  InstrumentType(id: 'guitar_7', stringCount: 7, tunings: guitar7Tunings),
  InstrumentType(id: 'guitar_8', stringCount: 8, tunings: guitar8Tunings),
  InstrumentType(id: 'baritone_6', stringCount: 6, tunings: baritoneTunings),
  InstrumentType(
    id: 'guitar_12',
    stringCount: 6,
    tunings: guitar12Tunings,
    isTwelveString: true,
  ),
  InstrumentType(id: 'bass_4', stringCount: 4, tunings: bass4Tunings),
  InstrumentType(id: 'bass_5', stringCount: 5, tunings: bass5Tunings),
  InstrumentType(id: 'bass_6', stringCount: 6, tunings: bass6Tunings),
];

InstrumentType instrumentById(String id) {
  return kInstruments.firstWhere(
    (i) => i.id == id,
    orElse: () => kInstruments.first,
  );
}

TuningPreset? presetById(InstrumentType instrument, String tuningId) {
  for (final p in instrument.tunings) {
    if (p.id == tuningId) return p;
  }
  return null;
}
