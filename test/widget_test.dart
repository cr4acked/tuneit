import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuneit/app.dart';
import 'package:tuneit/audio/pitch_detector.dart';
import 'package:tuneit/core/note_utils.dart';
import 'package:tuneit/data/custom_tunings_repository.dart';
import 'package:tuneit/data/settings_repository.dart';
import 'package:tuneit/state/metronome_controller.dart';
import 'package:tuneit/state/settings_controller.dart';
import 'package:tuneit/state/tuner_controller.dart';
import 'package:tuneit/ui/tuner/tuner_screen.dart';

Future<(TunerController, SettingsController)> pumpApp(
  WidgetTester tester,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(SettingsRepository(prefs));
  final tuner = TunerController(
    settings: settings,
    customRepo: CustomTuningsRepository(prefs),
    microphoneAvailable: false,
  );
  final metronome = MetronomeController();
  await tester.pumpWidget(
    TuneitApp(
      settings: settings,
      tuner: tuner,
      metronome: metronome,
      home: const TunerScreen(),
    ),
  );
  await tester.pump();
  return (tuner, settings);
}

PitchEstimate estimate(double hz) =>
    PitchEstimate(frequencyHz: hz, confidence: 0.95, rms: 0.1);

void main() {
  testWidgets('tuner screen renders tuning, strings and modes',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Standard E'), findsOneWidget);
    expect(find.text('Guitar, 6-string'), findsOneWidget); // en default
    expect(find.text('E2'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('D3'), findsOneWidget);
    expect(find.text('G3'), findsOneWidget);
    expect(find.text('B3'), findsOneWidget);
    expect(find.text('E4'), findsWidgets); // string badge (+ maybe target)
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Chromatic'), findsOneWidget);
    expect(find.text('Listening…'), findsOneWidget);
  });

  testWidgets('feeding a flat E2 shows Tune up, in-tune shows In tune',
      (tester) async {
    final (tuner, _) = await pumpApp(tester);

    for (var i = 0; i < 4; i++) {
      tuner.ingest(estimate(80.0)); // flat of E2 = 82.41
    }
    await tester.pump();
    expect(find.text('Tune up'), findsOneWidget);

    // Reset smoothing (like re-plucking after retuning), then land in tune.
    tuner.setMode(TunerMode.auto);
    for (var i = 0; i < 4; i++) {
      tuner.ingest(estimate(midiToHz(40)));
    }
    await tester.pump();
    expect(find.text('In tune'), findsOneWidget);
  });

  testWidgets('sharp note shows Tune down', (tester) async {
    final (tuner, _) = await pumpApp(tester);
    for (var i = 0; i < 4; i++) {
      tuner.ingest(estimate(85.0)); // sharp of E2
    }
    await tester.pump();
    expect(find.text('Tune down'), findsOneWidget);
  });

  testWidgets('language switch changes the UI to Russian', (tester) async {
    final (_, settings) = await pumpApp(tester);
    expect(find.text('Auto'), findsOneWidget);

    settings.language = AppLanguage.ru;
    await tester.pumpAndSettle();
    expect(find.text('Авто'), findsOneWidget);
    expect(find.text('Гитара, 6 струн'), findsOneWidget);
    expect(find.text('Слушаю…'), findsOneWidget);
  });

  testWidgets('denied microphone shows the fallback view', (tester) async {
    final (tuner, _) = await pumpApp(tester);
    tuner.debugSetStatus(TunerStatus.denied);
    await tester.pump();
    expect(find.text('No microphone access'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('tapping a string switches to manual mode', (tester) async {
    final (tuner, _) = await pumpApp(tester);
    await tester.tap(find.text('A2'));
    await tester.pump();
    expect(tuner.mode, TunerMode.manual);
    expect(tuner.manualStringIndex, 1);
  });

  testWidgets('theme mode follows the setting', (tester) async {
    final (_, settings) = await pumpApp(tester);
    settings.theme = AppThemeMode.dark;
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
