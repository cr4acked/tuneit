import '../models.dart';

const _id = 'guitar_8';

final List<TuningPreset> guitar8Tunings = [
  t(_id, 'standard_f_sharp', 'Standard F#', 'F#1 B1 E2 A2 D3 G3 B3 E4', TuningCategory.standard),
  t(_id, 'drop_e', 'Drop E', 'E1 B1 E2 A2 D3 G3 B3 E4', TuningCategory.drop),
  t(_id, 'drop_d_sharp', 'Drop D#', 'D#1 A#1 D#2 G#2 C#3 F#3 A#3 D#4', TuningCategory.drop),
  t(_id, 'drop_d', 'Drop D', 'D1 A1 D2 G2 C3 F3 A3 D4', TuningCategory.drop),
  t(_id, 'f_standard', 'F Standard (-1/2)', 'F1 A#1 D#2 G#2 C#3 F#3 A#3 D#4', TuningCategory.lowered),
  t(_id, 'e_standard', 'E Standard (-1)', 'E1 A1 D2 G2 C3 F3 A3 D4', TuningCategory.lowered),
];
