import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/note_utils.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/settings_controller.dart';
import '../../state/tuner_controller.dart';

/// Editor for user-defined tunings: pick the string count (4-8), then move
/// each string by semitones (or shift all at once). Stored locally.
class CustomTuningEditor extends StatefulWidget {
  const CustomTuningEditor({super.key, required this.instrument, this.existing});

  final InstrumentType instrument;
  final TuningPreset? existing;

  @override
  State<CustomTuningEditor> createState() => _CustomTuningEditorState();
}

class _CustomTuningEditorState extends State<CustomTuningEditor> {
  late List<int> _notes;
  late TextEditingController _name;

  static const _defaults = <int, String>{
    4: 'E1 A1 D2 G2',
    5: 'B0 E1 A1 D2 G2',
    6: 'E2 A2 D3 G3 B3 E4',
    7: 'B1 E2 A2 D3 G3 B3 E4',
    8: 'F#1 B1 E2 A2 D3 G3 B3 E4',
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _notes = [...existing.midiNotes];
      _name = TextEditingController(text: existing.name);
    } else {
      final current = context.read<TunerController>().tuning;
      _notes = current.stringCount == widget.instrument.stringCount
          ? [...current.midiNotes]
          : parseNotes(_defaults[widget.instrument.stringCount] ??
              _defaults[6]!);
      _name = TextEditingController();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _setStringCount(int count) {
    setState(() {
      if (count < _notes.length) {
        _notes = _notes.sublist(_notes.length - count);
      } else {
        while (_notes.length < count) {
          _notes.insert(0, (_notes.first - 5).clamp(0, 127).toInt());
        }
      }
    });
  }

  void _shift(int index, int semitones) {
    setState(() {
      _notes[index] = (_notes[index] + semitones).clamp(12, 100).toInt();
    });
  }

  void _shiftAll(int semitones) {
    setState(() {
      for (var i = 0; i < _notes.length; i++) {
        _notes[i] = (_notes[i] + semitones).clamp(12, 100).toInt();
      }
    });
  }

  Future<void> _save() async {
    final tuner = context.read<TunerController>();
    final s = Strings.of(context);
    final name = _name.text.trim().isEmpty
        ? _notes.map((m) => midiPitchClass(m)).join('')
        : _name.text.trim();
    final id = widget.existing?.id ??
        'custom.${DateTime.now().millisecondsSinceEpoch}';
    final preset = TuningPreset(
      id: id,
      name: name,
      midiNotes: List.unmodifiable(_notes),
      category: TuningCategory.custom,
      isCustom: true,
      nonMonotonic: true,
    );
    await tuner.saveCustomTuning(preset);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${s.save}: $name')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final s = Strings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteTuningQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<TunerController>()
          .deleteCustomTuning(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final settings = context.watch<SettingsController>();
    final flats = settings.useFlats;
    final isNew = widget.existing == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? s.newCustomTuning : s.editCustomTuning),
        actions: [
          if (!isNew)
            IconButton(
              tooltip: s.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: s.tuningName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (isNew)
            Row(
              children: [
                Text(s.stringsCount),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: [
                      for (var n = 4; n <= 8; n++)
                        ButtonSegment(value: n, label: Text('$n')),
                    ],
                    selected: {_notes.length},
                    onSelectionChanged: (sel) => _setStringCount(sel.first),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _shiftAll(-1),
                  child: Text(s.allStringsDown),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _shiftAll(1),
                  child: Text(s.allStringsUp),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _notes.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${i + 1}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        midiNoteName(_notes[i], flats: flats),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _shift(i, -1),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: () => _shift(i, 1),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(s.save),
          ),
        ],
      ),
    );
  }
}
