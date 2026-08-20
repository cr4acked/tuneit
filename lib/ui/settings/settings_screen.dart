import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/settings_repository.dart';
import '../../l10n/strings.dart';
import '../../state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Section(title: s.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppThemeMode>(
              segments: [
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text(s.themeSystem),
                ),
                ButtonSegment(
                  value: AppThemeMode.light,
                  label: Text(s.themeLight),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  label: Text(s.themeDark),
                ),
              ],
              selected: {settings.theme},
              onSelectionChanged: (sel) => settings.theme = sel.first,
            ),
          ),
          _Section(title: s.a4Calibration),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${settings.a4Hz.toStringAsFixed(1)} Hz',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Expanded(
                  child: Slider(
                    value: settings.a4Hz,
                    min: kA4Min,
                    max: kA4Max,
                    divisions: ((kA4Max - kA4Min) / kA4Step).round(),
                    label: settings.a4Hz.toStringAsFixed(1),
                    onChanged: (v) => settings.a4Hz = v,
                  ),
                ),
                TextButton(
                  onPressed: () => settings.a4Hz = kA4Default,
                  child: Text(s.resetTo440),
                ),
              ],
            ),
          ),
          _Section(title: s.inTuneThreshold),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<double>(
              segments: [
                for (final c in const [1.0, 3.0, 5.0])
                  ButtonSegment(
                    value: c,
                    label: Text('±${c.toInt()} ${s.centsSuffix}'),
                  ),
              ],
              selected: {settings.inTuneCents},
              onSelectionChanged: (sel) => settings.inTuneCents = sel.first,
            ),
          ),
          _Section(title: s.notation),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(s.notationSharps)),
                ButtonSegment(value: true, label: Text(s.notationFlats)),
              ],
              selected: {settings.useFlats},
              onSelectionChanged: (sel) => settings.useFlats = sel.first,
            ),
          ),
          SwitchListTile(
            title: Text(s.hapticFeedback),
            value: settings.haptic,
            onChanged: (v) => settings.haptic = v,
          ),
          _Section(title: s.micSensitivity),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<MicSensitivity>(
              segments: [
                ButtonSegment(
                  value: MicSensitivity.low,
                  label: Text(s.sensitivityLow),
                ),
                ButtonSegment(
                  value: MicSensitivity.medium,
                  label: Text(s.sensitivityMedium),
                ),
                ButtonSegment(
                  value: MicSensitivity.high,
                  label: Text(s.sensitivityHigh),
                ),
              ],
              selected: {settings.sensitivity},
              onSelectionChanged: (sel) => settings.sensitivity = sel.first,
            ),
          ),
          _Section(title: s.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppLanguage>(
              segments: [
                ButtonSegment(
                  value: AppLanguage.system,
                  label: Text(s.languageSystem),
                ),
                ButtonSegment(
                  value: AppLanguage.ru,
                  label: Text(s.languageRussian),
                ),
                ButtonSegment(
                  value: AppLanguage.en,
                  label: Text(s.languageEnglish),
                ),
              ],
              selected: {settings.language},
              onSelectionChanged: (sel) => settings.language = sel.first,
            ),
          ),
          _Section(title: s.about),
          ListTile(
            leading: const Icon(Icons.offline_bolt_outlined),
            title: Text(s.aboutText),
            subtitle: Text('${s.version} 1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
