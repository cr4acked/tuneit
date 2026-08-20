import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:provider/provider.dart';

import '../../core/note_utils.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../state/metronome_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/tuner_controller.dart';
import '../instrument_picker/instrument_picker_screen.dart';
import '../metronome/metronome_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/cents_gauge.dart';
import '../widgets/string_row.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start listening right away: the app opens ready to tune.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TunerController>().start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tuner = context.read<TunerController>();
    final metronome = context.read<MetronomeController>();
    // `inactive` fires for permission dialogs, Control Center and similar
    // overlays — stopping the mic there races start() and drops the tuner.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        tuner.stop();
        tuner.stopReferenceTone();
        metronome.stop();
      case AppLifecycleState.resumed:
        tuner.start();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerController>();
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openPicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        tuner.tuning.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                Text(
                  s.instrumentName(tuner.instrument.id),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: s.metronome,
            icon: const Icon(Icons.av_timer),
            onPressed: () => _openRoute(context, const MetronomeScreen()),
          ),
          IconButton(
            tooltip: s.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openRoute(context, const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: tuner.status == TunerStatus.denied
                  ? const _MicDeniedView()
                  : const _GaugeView(),
            ),
            const StringRow(),
            const SizedBox(height: 12),
            const _ModeSelector(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) =>
      _openRoute(context, const InstrumentPickerScreen());

  Future<void> _openRoute(BuildContext context, Widget page) async {
    final tuner = context.read<TunerController>();
    await tuner.stop();
    await tuner.stopReferenceTone();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (!context.mounted) return;
    await tuner.start();
  }
}

class _GaugeView extends StatelessWidget {
  const _GaugeView();

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerController>();
    final settings = context.watch<SettingsController>();
    final s = Strings.of(context);
    final scheme = Theme.of(context).colorScheme;

    final target = tuner.targetMidi;
    final cents = tuner.displayCents;
    final color = centsColor(context, cents, settings.inTuneCents);

    String statusText;
    IconData statusIcon;
    if (cents == null) {
      statusText = s.listening;
      statusIcon = Icons.hearing;
    } else if (cents.abs() <= settings.inTuneCents) {
      statusText = s.inTune;
      statusIcon = Icons.check_circle_outline;
    } else if (cents < 0) {
      statusText = s.tuneUp;
      statusIcon = Icons.arrow_upward;
    } else {
      statusText = s.tuneDown;
      statusIcon = Icons.arrow_downward;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Target note, big.
            Text(
              target != null
                  ? midiNoteName(target, flats: settings.useFlats)
                  : '—',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              target != null
                  ? '${midiToHz(target, a4Hz: settings.a4Hz).toStringAsFixed(2)} Hz'
                  : '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            CentsGauge(
              cents: cents,
              inTuneCents: settings.inTuneCents,
              color: color,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: color),
                ),
                if (cents != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(1)} ¢',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tuner.displayHz != null
                  ? '${tuner.displayHz!.toStringAsFixed(2)} Hz'
                  : ' ',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicDeniedView extends StatelessWidget {
  const _MicDeniedView();

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_off_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              s.micDeniedTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.micDeniedBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              s.referenceTonesStillWork,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: ph.openAppSettings,
              icon: const Icon(Icons.settings),
              label: Text(s.openSystemSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerController>();
    final s = Strings.of(context);
    return SegmentedButton<TunerMode>(
      segments: [
        ButtonSegment(value: TunerMode.auto, label: Text(s.modeAuto)),
        ButtonSegment(value: TunerMode.manual, label: Text(s.modeManual)),
        ButtonSegment(
          value: TunerMode.chromatic,
          label: Text(s.modeChromatic),
        ),
      ],
      selected: {tuner.mode},
      onSelectionChanged: (selection) => tuner.setMode(selection.first),
    );
  }
}
