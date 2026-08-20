import '../models.dart';

const _id = 'bass_5';

final List<TuningPreset> bass5Tunings = [
  t(_id, 'standard_b', 'Standard B', 'B0 E1 A1 D2 G2', TuningCategory.standard),
  t(_id, 'drop_a', 'Drop A', 'A0 E1 A1 D2 G2', TuningCategory.drop),
  t(_id, 'a_sharp_standard', 'A# Standard (-1/2)', 'A#0 D#1 G#1 C#2 F#2', TuningCategory.lowered),
  t(_id, 'a_standard', 'A Standard (-1)', 'A0 D1 G1 C2 F2', TuningCategory.lowered),
  t(_id, 'tenor_5', 'Tenor 5', 'E1 A1 D2 G2 C3', TuningCategory.alternate),
  t(_id, 'low_f_sharp', 'Low F#', 'F#0 B0 E1 A1 D2', TuningCategory.alternate),
];
