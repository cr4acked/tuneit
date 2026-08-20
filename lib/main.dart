import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/custom_tunings_repository.dart';
import 'data/settings_repository.dart';
import 'state/metronome_controller.dart';
import 'state/settings_controller.dart';
import 'state/tuner_controller.dart';
import 'ui/tuner/tuner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(SettingsRepository(prefs));
  final tuner = TunerController(
    settings: settings,
    customRepo: CustomTuningsRepository(prefs),
  );
  final metronome = MetronomeController();
  runApp(
    TuneitApp(
      settings: settings,
      tuner: tuner,
      metronome: metronome,
      home: const TunerScreen(),
    ),
  );
}
