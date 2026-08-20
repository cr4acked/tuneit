import '../models.dart';

const _id = 'bass_4';

final List<TuningPreset> bass4Tunings = [
  t(_id, 'standard_e', 'Standard E', 'E1 A1 D2 G2', TuningCategory.standard),
  t(_id, 'drop_d', 'Drop D', 'D1 A1 D2 G2', TuningCategory.drop),
  t(_id, 'drop_c_sharp', 'Drop C#', 'C#1 G#1 C#2 F#2', TuningCategory.drop),
  t(_id, 'drop_c', 'Drop C', 'C1 G1 C2 F2', TuningCategory.drop),
  t(_id, 'eb_standard', 'Eb Standard (-1/2)', 'D#1 G#1 C#2 F#2', TuningCategory.lowered),
  t(_id, 'd_standard', 'D Standard (-1)', 'D1 G1 C2 F2', TuningCategory.lowered),
  t(_id, 'c_sharp_standard', 'C# Standard (-1 1/2)', 'C#1 F#1 B1 E2', TuningCategory.lowered),
  t(_id, 'c_standard', 'C Standard (-2)', 'C1 F1 A#1 D#2', TuningCategory.lowered),
  t(_id, 'b_standard', 'B Standard (-2 1/2)', 'B0 E1 A1 D2', TuningCategory.lowered),
  t(_id, 'bead', 'BEAD', 'B0 E1 A1 D2', TuningCategory.alternate),
  t(_id, 'tenor', 'Tenor bass', 'A1 D2 G2 C3', TuningCategory.alternate),
];
