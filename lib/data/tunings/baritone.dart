import '../models.dart';

const _id = 'baritone_6';

final List<TuningPreset> baritoneTunings = [
  t(_id, 'standard_b', 'Standard B', 'B1 E2 A2 D3 F#3 B3', TuningCategory.standard),
  t(_id, 'standard_a', 'Standard A', 'A1 D2 G2 C3 E3 A3', TuningCategory.standard),
  t(_id, 'standard_c', 'Standard C', 'C2 F2 A#2 D#3 G3 C4', TuningCategory.standard),
  t(_id, 'drop_a', 'Drop A', 'A1 E2 A2 D3 F#3 B3', TuningCategory.drop),
  t(_id, 'drop_g', 'Drop G', 'G1 D2 G2 C3 E3 A3', TuningCategory.drop),
];
