import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Custom (user-defined) tunings, stored locally as JSON.
class CustomTuningsRepository {
  CustomTuningsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'customTunings';

  List<TuningPreset> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TuningPreset.fromJson(
              (e as Map).map((k, v) => MapEntry(k as String, v))))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<TuningPreset> tunings) {
    final raw = jsonEncode(tunings.map((t) => t.toJson()).toList());
    return _prefs.setString(_key, raw);
  }
}
