import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/instruments.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/settings_controller.dart';
import '../../state/tuner_controller.dart';
import '../custom_tuning/custom_tuning_editor.dart';

class InstrumentPickerScreen extends StatefulWidget {
  const InstrumentPickerScreen({super.key});

  @override
  State<InstrumentPickerScreen> createState() => _InstrumentPickerScreenState();
}

class _InstrumentPickerScreenState extends State<InstrumentPickerScreen> {
  late InstrumentType _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = context.read<TunerController>().instrument;
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.chooseTuning)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(s.newCustomTuning),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CustomTuningEditor(instrument: _selected),
            ),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.searchTunings,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          if (_query.isEmpty) _InstrumentChips(
            selected: _selected,
            onSelect: (inst) => setState(() => _selected = inst),
          ),
          Expanded(
            child: _query.isEmpty
                ? _TuningList(instrument: _selected)
                : _SearchResults(query: _query),
          ),
        ],
      ),
    );
  }
}

class _InstrumentChips extends StatelessWidget {
  const _InstrumentChips({required this.selected, required this.onSelect});

  final InstrumentType selected;
  final ValueChanged<InstrumentType> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final inst in kInstruments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: ChoiceChip(
                label: Text(s.instrumentName(inst.id)),
                selected: inst.id == selected.id,
                onSelected: (_) => onSelect(inst),
              ),
            ),
        ],
      ),
    );
  }
}

class _TuningList extends StatelessWidget {
  const _TuningList({required this.instrument});

  final InstrumentType instrument;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tuner = context.watch<TunerController>();
    final settings = context.watch<SettingsController>();
    final recents = _recentsFor(tuner, settings);
    final custom = tuner.customTuningsFor(instrument);

    final sections = <Widget>[];

    if (recents.isNotEmpty) {
      sections.add(_SectionHeader(title: s.recent));
      sections.addAll(
        recents.map(
          (r) => _TuningTile(
            instrument: r.$1,
            tuning: r.$2,
            subtitleSuffix: s.instrumentName(r.$1.id),
          ),
        ),
      );
    }

    if (custom.isNotEmpty) {
      sections.add(_SectionHeader(title: s.categoryCustom));
      sections.addAll(
        custom.map(
          (t) => _TuningTile(instrument: instrument, tuning: t, custom: true),
        ),
      );
    }

    for (final category in const [
      TuningCategory.standard,
      TuningCategory.drop,
      TuningCategory.lowered,
      TuningCategory.open,
      TuningCategory.alternate,
    ]) {
      final tunings =
          instrument.tunings.where((t) => t.category == category).toList();
      if (tunings.isEmpty) continue;
      sections.add(_SectionHeader(title: _categoryName(s, category)));
      sections.addAll(
        tunings.map((t) => _TuningTile(instrument: instrument, tuning: t)),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: sections,
    );
  }

  List<(InstrumentType, TuningPreset)> _recentsFor(
    TunerController tuner,
    SettingsController settings,
  ) {
    final result = <(InstrumentType, TuningPreset)>[];
    for (final key in settings.repo.recents) {
      final parts = key.split('|');
      if (parts.length != 2) continue;
      final inst = instrumentById(parts[0]);
      TuningPreset? preset = presetById(inst, parts[1]);
      if (preset == null) {
        for (final t in tuner.customTunings) {
          if (t.id == parts[1]) {
            preset = t;
            break;
          }
        }
      }
      if (preset != null) result.add((inst, preset));
    }
    return result;
  }
}

String _categoryName(Strings s, TuningCategory category) {
  switch (category) {
    case TuningCategory.standard:
      return s.categoryStandard;
    case TuningCategory.drop:
      return s.categoryDrop;
    case TuningCategory.lowered:
      return s.categoryLowered;
    case TuningCategory.open:
      return s.categoryOpen;
    case TuningCategory.alternate:
      return s.categoryAlternate;
    case TuningCategory.custom:
      return s.categoryCustom;
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tuner = context.watch<TunerController>();
    final settings = context.watch<SettingsController>();
    final flats = settings.useFlats;

    bool matches(TuningPreset t) {
      if (t.name.toLowerCase().contains(query)) return true;
      final compact =
          t.shortLabel(flats: flats).replaceAll(' ', '').toLowerCase();
      if (compact.contains(query.replaceAll(' ', ''))) return true;
      return t.fullLabel(flats: flats).toLowerCase().contains(query);
    }

    final results = <(InstrumentType, TuningPreset)>[];
    for (final inst in kInstruments) {
      for (final t in inst.tunings) {
        if (matches(t)) results.add((inst, t));
      }
      for (final t in tuner.customTuningsFor(inst)) {
        if (matches(t) && inst.stringCount == t.stringCount) {
          results.add((inst, t));
        }
      }
    }

    if (results.isEmpty) {
      return Center(child: Text(s.nothingFound));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) => _TuningTile(
        instrument: results[i].$1,
        tuning: results[i].$2,
        subtitleSuffix: s.instrumentName(results[i].$1.id),
        custom: results[i].$2.isCustom,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _TuningTile extends StatelessWidget {
  const _TuningTile({
    required this.instrument,
    required this.tuning,
    this.subtitleSuffix,
    this.custom = false,
  });

  final InstrumentType instrument;
  final TuningPreset tuning;
  final String? subtitleSuffix;
  final bool custom;

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerController>();
    final settings = context.watch<SettingsController>();
    final selected =
        tuner.tuning.id == tuning.id && tuner.instrument.id == instrument.id;
    final notes = tuning.fullLabel(flats: settings.useFlats);
    final subtitle =
        subtitleSuffix == null ? notes : '$notes · $subtitleSuffix';

    return ListTile(
      selected: selected,
      leading: selected
          ? const Icon(Icons.radio_button_checked)
          : const Icon(Icons.radio_button_off),
      title: Text(tuning.name),
      subtitle: Text(subtitle),
      trailing: custom
          ? IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomTuningEditor(
                      instrument: instrument,
                      existing: tuning,
                    ),
                  ),
                );
              },
            )
          : null,
      onTap: () {
        tuner.selectTuning(instrument, tuning);
        Navigator.of(context).pop();
      },
    );
  }
}
