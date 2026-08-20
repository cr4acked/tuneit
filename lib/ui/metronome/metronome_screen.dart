import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../l10n/strings.dart';
import '../../state/metronome_controller.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  late final MetronomeController _metronome;

  @override
  void initState() {
    super.initState();
    _metronome = context.read<MetronomeController>();
  }

  @override
  void dispose() {
    _metronome.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MetronomeController>();
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.metronome)),
      floatingActionButton: FloatingActionButton.large(
        onPressed: m.toggle,
        child: Icon(m.isRunning ? Icons.stop : Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Beat dots.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < m.signature.beats; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: m.isRunning && m.visualBeat == i ? 20 : 12,
                    height: m.isRunning && m.visualBeat == i ? 20 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.isRunning && m.visualBeat == i
                          ? (i == 0 && m.accentFirst
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
          // BPM.
          Center(
            child: Text(
              '${m.bpm}',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Center(child: Text(s.bpm)),
          Row(
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: () => m.bpm = m.bpm - 1,
              ),
              Expanded(
                child: Slider(
                  value: m.bpm.toDouble(),
                  min: kBpmMin.toDouble(),
                  max: kBpmMax.toDouble(),
                  onChanged: (v) => m.bpm = v.round(),
                ),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: () => m.bpm = m.bpm + 1,
              ),
            ],
          ),
          Center(
            child: OutlinedButton.icon(
              onPressed: m.tap,
              icon: const Icon(Icons.touch_app_outlined),
              label: Text(s.tapTempo),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.timeSignature,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final sig in kTimeSignatures)
                ChoiceChip(
                  label: Text(sig.label),
                  selected: m.signature.label == sig.label,
                  onSelected: (_) => m.signature = sig,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(s.subdivision, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 1, label: Text(s.subdivisionQuarters)),
              ButtonSegment(value: 2, label: Text(s.subdivisionEighths)),
              ButtonSegment(value: 3, label: Text(s.subdivisionTriplets)),
              ButtonSegment(value: 4, label: Text(s.subdivisionSixteenths)),
            ],
            selected: {m.subdivisions},
            onSelectionChanged: (sel) => m.subdivisions = sel.first,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(s.accentFirstBeat),
            value: m.accentFirst,
            onChanged: (v) => m.accentFirst = v,
          ),
          SwitchListTile(
            title: Text(s.hapticPulse),
            value: m.hapticPulse,
            onChanged: (v) => m.hapticPulse = v,
          ),
        ],
      ),
    );
  }
}
