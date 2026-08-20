import '../models.dart';

const _id = 'guitar_6';

final List<TuningPreset> guitar6Tunings = [
  // Standard
  t(_id, 'standard_e', 'Standard E', 'E2 A2 D3 G3 B3 E4', TuningCategory.standard),
  // Drop
  t(_id, 'drop_d', 'Drop D', 'D2 A2 D3 G3 B3 E4', TuningCategory.drop),
  t(_id, 'drop_c_sharp', 'Drop C#', 'C#2 G#2 C#3 F#3 A#3 D#4', TuningCategory.drop),
  t(_id, 'drop_c', 'Drop C', 'C2 G2 C3 F3 A3 D4', TuningCategory.drop),
  t(_id, 'drop_b', 'Drop B', 'B1 F#2 B2 E3 G#3 C#4', TuningCategory.drop),
  t(_id, 'drop_a_sharp', 'Drop A#', 'A#1 F2 A#2 D#3 G3 C4', TuningCategory.drop),
  t(_id, 'drop_a', 'Drop A', 'A1 E2 A2 D3 F#3 B3', TuningCategory.drop),
  t(_id, 'drop_g_sharp', 'Drop G#', 'G#1 D#2 G#2 C#3 F3 A#3', TuningCategory.drop),
  t(_id, 'drop_g', 'Drop G', 'G1 D2 G2 C3 E3 A3', TuningCategory.drop),
  t(_id, 'double_drop_d', 'Double Drop D', 'D2 A2 D3 G3 B3 D4', TuningCategory.drop),
  // Lowered / raised
  t(_id, 'eb_standard', 'Eb Standard (-1/2)', 'D#2 G#2 C#3 F#3 A#3 D#4', TuningCategory.lowered),
  t(_id, 'd_standard', 'D Standard (-1)', 'D2 G2 C3 F3 A3 D4', TuningCategory.lowered),
  t(_id, 'c_sharp_standard', 'C# Standard (-1 1/2)', 'C#2 F#2 B2 E3 G#3 C#4', TuningCategory.lowered),
  t(_id, 'c_standard', 'C Standard (-2)', 'C2 F2 A#2 D#3 G3 C4', TuningCategory.lowered),
  t(_id, 'b_standard', 'B Standard (-2 1/2)', 'B1 E2 A2 D3 F#3 B3', TuningCategory.lowered),
  t(_id, 'a_sharp_standard', 'A# Standard (-3)', 'A#1 D#2 G#2 C#3 F3 A#3', TuningCategory.lowered),
  t(_id, 'a_standard', 'A Standard (-3 1/2)', 'A1 D2 G2 C3 E3 A3', TuningCategory.lowered),
  t(_id, 'f_standard', 'F Standard (+1)', 'F2 A#2 D#3 G#3 C4 F4', TuningCategory.lowered),
  // Open
  t(_id, 'open_d', 'Open D', 'D2 A2 D3 F#3 A3 D4', TuningCategory.open),
  t(_id, 'open_d_minor', 'Open D minor', 'D2 A2 D3 F3 A3 D4', TuningCategory.open),
  t(_id, 'open_e', 'Open E', 'E2 B2 E3 G#3 B3 E4', TuningCategory.open),
  t(_id, 'open_g', 'Open G', 'D2 G2 D3 G3 B3 D4', TuningCategory.open),
  t(_id, 'open_g_minor', 'Open G minor', 'D2 G2 D3 G3 A#3 D4', TuningCategory.open),
  t(_id, 'open_a', 'Open A', 'E2 A2 E3 A3 C#4 E4', TuningCategory.open),
  t(_id, 'open_a_minor', 'Open A minor', 'E2 A2 E3 A3 C4 E4', TuningCategory.open),
  t(_id, 'open_c', 'Open C', 'C2 G2 C3 G3 C4 E4', TuningCategory.open),
  t(_id, 'open_c6', 'Open C6', 'C2 A2 C3 G3 C4 E4', TuningCategory.open),
  t(_id, 'open_c_minor', 'Open C minor', 'C2 G2 C3 G3 C4 D#4', TuningCategory.open),
  t(_id, 'open_f', 'Open F', 'C2 F2 C3 F3 A3 F4', TuningCategory.open),
  // Alternate
  t(_id, 'dadgad', 'DADGAD (Celtic)', 'D2 A2 D3 G3 A3 D4', TuningCategory.alternate),
  t(_id, 'dadaad', 'DADAAD', 'D2 A2 D3 A3 A3 D4', TuningCategory.alternate, nonMonotonic: true),
  t(_id, 'all_fourths', 'All Fourths', 'E2 A2 D3 G3 C4 F4', TuningCategory.alternate),
  t(_id, 'major_thirds', 'Major Thirds', 'E2 G#2 C3 E3 G#3 C4', TuningCategory.alternate),
  t(_id, 'nst', 'New Standard (NST)', 'C2 G2 D3 A3 E4 G4', TuningCategory.alternate),
  t(_id, 'nick_drake', 'Nick Drake (CGCFCE)', 'C2 G2 C3 F3 C4 E4', TuningCategory.alternate),
  t(_id, 'nashville', 'Nashville (high-strung)', 'E3 A3 D4 G3 B3 E4', TuningCategory.alternate, nonMonotonic: true),
  t(_id, 'vestapol', 'Lute / Vestapol', 'E2 A2 D3 F#3 B3 E4', TuningCategory.alternate),
];
