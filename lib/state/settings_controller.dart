import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/settings_repository.dart';

/// App-wide user preferences. Every setter persists immediately.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repo);

  final SettingsRepository _repo;

  AppThemeMode get theme => _repo.theme;
  set theme(AppThemeMode v) {
    _repo.theme = v;
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (theme) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  double get a4Hz => _repo.a4Hz;
  set a4Hz(double v) {
    _repo.a4Hz = v;
    notifyListeners();
  }

  double get inTuneCents => _repo.inTuneCents;
  set inTuneCents(double v) {
    _repo.inTuneCents = v;
    notifyListeners();
  }

  bool get useFlats => _repo.useFlats;
  set useFlats(bool v) {
    _repo.useFlats = v;
    notifyListeners();
  }

  bool get haptic => _repo.haptic;
  set haptic(bool v) {
    _repo.haptic = v;
    notifyListeners();
  }

  AppLanguage get language => _repo.language;
  set language(AppLanguage v) {
    _repo.language = v;
    notifyListeners();
  }

  Locale? get localeOverride {
    switch (language) {
      case AppLanguage.ru:
        return const Locale('ru');
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.system:
        return null;
    }
  }

  MicSensitivity get sensitivity => _repo.sensitivity;
  set sensitivity(MicSensitivity v) {
    _repo.sensitivity = v;
    notifyListeners();
  }

  /// RMS noise-gate threshold implied by the sensitivity setting.
  double get gateRms {
    switch (sensitivity) {
      case MicSensitivity.low:
        return kGateRmsLow;
      case MicSensitivity.medium:
        return kGateRmsMedium;
      case MicSensitivity.high:
        return kGateRmsHigh;
    }
  }

  SettingsRepository get repo => _repo;
}
