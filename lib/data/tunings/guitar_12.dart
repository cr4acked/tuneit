import '../models.dart';

const _id = 'guitar_12';

/// 12-string guitars are modeled as 6 courses. The stored note is the
/// principal string of each course; the UI marks the four lower courses
/// as octave pairs. Tune the octave string one octave above the shown
/// note (chromatic mode picks it up automatically).
final List<TuningPreset> guitar12Tunings = [
  t(_id, 'standard_e', 'Standard E (pairs)', 'E2 A2 D3 G3 B3 E4', TuningCategory.standard),
  t(_id, 'drop_d', 'Drop D (pairs)', 'D2 A2 D3 G3 B3 E4', TuningCategory.drop),
  t(_id, 'd_standard', 'D Standard (pairs)', 'D2 G2 C3 F3 A3 D4', TuningCategory.lowered),
];
