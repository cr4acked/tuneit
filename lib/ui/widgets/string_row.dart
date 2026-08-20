import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/note_utils.dart';
import '../../l10n/strings.dart';
import '../../state/settings_controller.dart';
import '../../state/tuner_controller.dart';

/// Row of string badges: lowest (thickest) string on the left.
/// Tap selects the string (manual mode); long-press plays its reference
/// tone; a check mark shows strings already tuned this session.
class StringRow extends StatelessWidget {
  const StringRow({super.key});

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerController>();
    final settings = context.watch<SettingsController>();
    final s = Strings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final notes = tuner.tuning.midiNotes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (var i = 0; i < notes.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _StringBadge(
                    label: midiNoteName(notes[i], flats: settings.useFlats),
                    active: tuner.activeStringIndex == i,
                    tuned: tuner.tunedStrings.contains(i),
                    playing: tuner.playingToneIndex == i,
                    octavePair: tuner.instrument.isTwelveString && i < 4,
                    scheme: scheme,
                    onTap: () => tuner.selectString(i),
                    onLongPress: () => tuner.toggleReferenceTone(i),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tuner.instrument.isTwelveString
              ? s.octavePairsNote
              : s.longPressToPlayTone,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StringBadge extends StatelessWidget {
  const _StringBadge({
    required this.label,
    required this.active,
    required this.tuned,
    required this.playing,
    required this.octavePair,
    required this.scheme,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final bool active;
  final bool tuned;
  final bool playing;
  final bool octavePair;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (octavePair)
                  Text(
                    '×2 8va',
                    style: TextStyle(color: fg, fontSize: 8),
                  ),
              ],
            ),
            if (tuned)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF2E9E5B),
                ),
              ),
            if (playing)
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.volume_up, size: 16, color: scheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
