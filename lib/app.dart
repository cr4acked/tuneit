import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/strings.dart';
import 'state/metronome_controller.dart';
import 'state/settings_controller.dart';
import 'state/tuner_controller.dart';

class TuneitApp extends StatelessWidget {
  const TuneitApp({
    super.key,
    required this.settings,
    required this.tuner,
    required this.metronome,
    required this.home,
  });

  final SettingsController settings;
  final TunerController tuner;
  final MetronomeController metronome;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<TunerController>.value(value: tuner),
        ChangeNotifierProvider<MetronomeController>.value(value: metronome),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Tuneit',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            locale: settings.localeOverride,
            supportedLocales: Strings.supportedLocales,
            localizationsDelegates: const [
              Strings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: home,
          );
        },
      ),
    );
  }
}
