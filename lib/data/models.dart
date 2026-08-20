/// Data model for instruments and tuning presets. Pure Dart.
library;

import '../core/note_utils.dart';

enum TuningCategory { custom, standard, drop, lowered, open, alternate }

class TuningPreset {
  const TuningPreset({
    required this.id,
    required this.name,
    required this.midiNotes,
    required this.category,
    this.nonMonotonic = false,
    this.isCustom = false,
    this.instrumentId,
  });

  /// Stable identifier, e.g. 'guitar_6.drop_c'.
  final String id;

  /// Display name; tuning names are intentionally not localized.
  final String name;

  /// Notes from the thickest (lowest) string to the thinnest.
  final List<int> midiNotes;

  final TuningCategory category;

  /// True for re-entrant tunings (e.g. Nashville) where pitches are not
  /// strictly ascending; excluded from the monotonicity data test.
  final bool nonMonotonic;

  final bool isCustom;

  /// Owning instrument for custom tunings. Null on built-in presets and
  /// on customs saved before this field existed.
  final String? instrumentId;

  int get stringCount => midiNotes.length;

  /// Compact letters-only label, e.g. 'CGCFAD'.
  String shortLabel({bool flats = false}) {
    return midiNotes.map((m) => midiPitchClass(m, flats: flats)).join();
  }

  /// Full label with octaves, e.g. 'C2 G2 C3 F3 A3 D4'.
  String fullLabel({bool flats = false}) {
    return midiNotes.map((m) => midiNoteName(m, flats: flats)).join(' ');
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'midiNotes': midiNotes,
        if (instrumentId != null) 'instrumentId': instrumentId,
      };

  static TuningPreset fromJson(Map<String, Object?> json) {
    return TuningPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      midiNotes:
          (json['midiNotes'] as List).map((e) => e as int).toList(growable: false),
      category: TuningCategory.custom,
      isCustom: true,
      instrumentId: json['instrumentId'] as String?,
    );
  }
}

class InstrumentType {
  const InstrumentType({
    required this.id,
    required this.stringCount,
    required this.tunings,
    this.isTwelveString = false,
  });

  /// Stable identifier, e.g. 'guitar_6'. Display names are localized by id.
  final String id;

  final int stringCount;

  final List<TuningPreset> tunings;

  /// 12-string guitars are shown as 6 courses with an octave-pair mark.
  final bool isTwelveString;
}

/// Helper used by the static tuning tables.
TuningPreset t(
  String instrumentId,
  String presetId,
  String name,
  String notes,
  TuningCategory category, {
  bool nonMonotonic = false,
}) {
  return TuningPreset(
    id: '$instrumentId.$presetId',
    name: name,
    midiNotes: parseNotes(notes),
    category: category,
    nonMonotonic: nonMonotonic,
  );
}
