import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

enum AppThemeMode { system, light, dark }

enum AppLanguage { system, ru, en }

enum MicSensitivity { low, medium, high }

/// Typed persistence over shared_preferences. No backend anywhere.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kTheme = 'theme';
  static const _kA4 = 'a4hz';
  static const _kInTune = 'inTuneCents';
  static const _kFlats = 'useFlats';
  static const _kHaptic = 'haptic';
  static const _kLanguage = 'language';
  static const _kSensitivity = 'sensitivity';
  static const _kLastInstrument = 'lastInstrument';
  static const _kLastTuning = 'lastTuning';
  static const _kRecents = 'recents';

  AppThemeMode get theme => AppThemeMode.values.asNameMap()[_prefs.getString(_kTheme)] ?? AppThemeMode.system;
  set theme(AppThemeMode v) => _prefs.setString(_kTheme, v.name);

  double get a4Hz =>
      (_prefs.getDouble(_kA4) ?? kA4Default).clamp(kA4Min, kA4Max).toDouble();
  set a4Hz(double v) =>
      _prefs.setDouble(_kA4, v.clamp(kA4Min, kA4Max).toDouble());

  double get inTuneCents => _prefs.getDouble(_kInTune) ?? kInTuneCentsDefault;
  set inTuneCents(double v) => _prefs.setDouble(_kInTune, v);

  bool get useFlats => _prefs.getBool(_kFlats) ?? false;
  set useFlats(bool v) => _prefs.setBool(_kFlats, v);

  bool get haptic => _prefs.getBool(_kHaptic) ?? true;
  set haptic(bool v) => _prefs.setBool(_kHaptic, v);

  AppLanguage get language =>
      AppLanguage.values.asNameMap()[_prefs.getString(_kLanguage)] ??
      AppLanguage.system;
  set language(AppLanguage v) => _prefs.setString(_kLanguage, v.name);

  MicSensitivity get sensitivity =>
      MicSensitivity.values.asNameMap()[_prefs.getString(_kSensitivity)] ??
      MicSensitivity.medium;
  set sensitivity(MicSensitivity v) =>
      _prefs.setString(_kSensitivity, v.name);

  String? get lastInstrumentId => _prefs.getString(_kLastInstrument);
  String? get lastTuningId => _prefs.getString(_kLastTuning);

  void saveLastSelection(String instrumentId, String tuningId) {
    _prefs.setString(_kLastInstrument, instrumentId);
    _prefs.setString(_kLastTuning, tuningId);
  }

  /// Recent combos as 'instrumentId|tuningId', most recent first, max 5.
  List<String> get recents => _prefs.getStringList(_kRecents) ?? const [];

  void pushRecent(String instrumentId, String tuningId) {
    final key = '$instrumentId|$tuningId';
    final list = [key, ...recents.where((e) => e != key)];
    _prefs.setStringList(_kRecents, list.take(5).toList());
  }
}
