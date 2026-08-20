import '../models.dart';

const _id = 'guitar_7';

final List<TuningPreset> guitar7Tunings = [
  t(_id, 'standard_b', 'Standard B', 'B1 E2 A2 D3 G3 B3 E4', TuningCategory.standard),
  t(_id, 'drop_a', 'Drop A', 'A1 E2 A2 D3 G3 B3 E4', TuningCategory.drop),
  t(_id, 'drop_g_sharp', 'Drop G#', 'G#1 D#2 G#2 C#3 F#3 A#3 D#4', TuningCategory.drop),
  t(_id, 'drop_g', 'Drop G', 'G1 D2 G2 C3 F3 A3 D4', TuningCategory.drop),
  t(_id, 'drop_f_sharp', 'Drop F#', 'F#1 C#2 F#2 B2 E3 G#3 C#4', TuningCategory.drop),
  t(_id, 'drop_e', 'Drop E', 'E1 B1 E2 A2 D3 F#3 B3', TuningCategory.drop),
  t(_id, 'a_sharp_standard', 'A# Standard (-1/2)', 'A#1 D#2 G#2 C#3 F#3 A#3 D#4', TuningCategory.lowered),
  t(_id, 'a_standard', 'A Standard (-1)', 'A1 D2 G2 C3 F3 A3 D4', TuningCategory.lowered),
  t(_id, 'g_sharp_standard', 'G# Standard (-1 1/2)', 'G#1 C#2 F#2 B2 E3 G#3 C#4', TuningCategory.lowered),
  t(_id, 'g_standard', 'G Standard (-2)', 'G1 C2 F2 A#2 D#3 G3 C4', TuningCategory.lowered),
  t(_id, 'russian_open_g', 'Russian 7-string (Open G)', 'D2 G2 B2 D3 G3 B3 D4', TuningCategory.open),
];
