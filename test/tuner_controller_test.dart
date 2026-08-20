import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuneit/audio/pitch_detector.dart';
import 'package:tuneit/core/note_utils.dart';
import 'package:tuneit/data/custom_tunings_repository.dart';
import 'package:tuneit/data/instruments.dart';
import 'package:tuneit/data/models.dart';
import 'package:tuneit/data/settings_repository.dart';
import 'package:tuneit/state/settings_controller.dart';
import 'package:tuneit/state/tuner_controller.dart';

Future<TunerController> makeController(
    {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final settings = SettingsController(SettingsRepository(p));
  return TunerController(
    settings: settings,
    customRepo: CustomTuningsRepository(p),
    microphoneAvailable: false,
  );
}

PitchEstimate estimate(double hz) =>
    PitchEstimate(frequencyHz: hz, confidence: 0.95, rms: 0.1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to 6-string guitar, Standard E', () async {
    final c = await makeController();
    expect(c.instrument.id, 'guitar_6');
    expect(c.tuning.id, 'guitar_6.standard_e');
  });

  test('restores last selection from prefs', () async {
    final c = await makeController(prefs: {
      'lastInstrument': 'bass_5',
      'lastTuning': 'bass_5.drop_a',
    });
    expect(c.instrument.id, 'bass_5');
    expect(c.tuning.id, 'bass_5.drop_a');
  });

  test('auto mode picks the nearest string', () async {
    final c = await makeController();
    // Slightly flat D3 (146.83 Hz) -> string index 2 of Standard E.
    for (var i = 0; i < 4; i++) {
      c.ingest(estimate(144.0));
    }
    expect(c.activeStringIndex, 2);
    expect(c.targetMidi, 50); // D3
    expect(c.displayCents, isNotNull);
    expect(c.displayCents!, lessThan(0)); // flat
  });

  test('manual mode pins the chosen string', () async {
    final c = await makeController();
    c.selectString(5); // high E4
    // Play A2-ish sound; target must stay E4.
    for (var i = 0; i < 4; i++) {
      c.ingest(estimate(110.0));
    }
    expect(c.mode, TunerMode.manual);
    expect(c.targetMidi, 64);
  });

  test('chromatic mode targets the nearest semitone', () async {
    final c = await makeController();
    c.setMode(TunerMode.chromatic);
    for (var i = 0; i < 4; i++) {
      c.ingest(estimate(midiToHz(58) * 1.01)); // slightly sharp A#3
    }
    expect(c.targetMidi, 58);
    expect(c.activeStringIndex, isNull);
    expect(c.displayCents!, greaterThan(0));
  });

  test('in-tune streak marks the string as tuned', () async {
    final c = await makeController();
    final e2 = midiToHz(40);
    for (var i = 0; i < 10; i++) {
      c.ingest(estimate(e2));
    }
    expect(c.tunedStrings, contains(0));
    expect(c.isInTune, isTrue);
  });

  test('weak or unconfident frames are gated out', () async {
    final c = await makeController();
    c.ingest(
      const PitchEstimate(frequencyHz: 100, confidence: 0.2, rms: 0.1),
    );
    expect(c.displayHz, isNull);
    c.ingest(
      const PitchEstimate(frequencyHz: 100, confidence: 0.9, rms: 0.0001),
    );
    expect(c.displayHz, isNull);
  });

  test('signal clears after silence', () async {
    final c = await makeController();
    for (var i = 0; i < 4; i++) {
      c.ingest(estimate(110.0));
    }
    expect(c.displayHz, isNotNull);
    for (var i = 0; i < 8; i++) {
      c.ingest(PitchEstimate.none);
    }
    expect(c.displayHz, isNull);
    expect(c.displayCents, isNull);
  });

  test('A4 calibration moves the cents readout', () async {
    final c = await makeController();
    final hz440 = midiToHz(69); // exact A4 at 440
    c.selectTuning(instrumentById('guitar_6'),
        presetById(instrumentById('guitar_6'), 'guitar_6.standard_e')!);
    c.setMode(TunerMode.chromatic);
    for (var i = 0; i < 4; i++) {
      c.ingest(estimate(hz440));
    }
    final centsAt440 = c.displayCents!;
    expect(centsAt440.abs(), lessThan(0.5));

    c.settings.a4Hz = 442.0;
    c.setMode(TunerMode.chromatic);
    for (var i = 0; i < 4; i++) {
      c.ingest(estimate(hz440));
    }
    // 440 Hz against A4=442 must read flat by ~7.86 cents.
    expect(c.displayCents!, lessThan(-5.0));
  });

  test('custom tunings save, update and delete', () async {
    final c = await makeController();
    await c.saveCustomTuning(const TuningPreset(
      id: 'custom.test1',
      name: 'My Drop C',
      midiNotes: [36, 43, 48, 53, 57, 62],
      category: TuningCategory.custom,
      isCustom: true,
      nonMonotonic: true,
      instrumentId: 'guitar_6',
    ));
    expect(c.customTunings.length, 1);
    expect(c.customTuningsFor(instrumentById('guitar_6')).length, 1);
    expect(c.customTuningsFor(instrumentById('bass_6')), isEmpty);

    await c.saveCustomTuning(const TuningPreset(
      id: 'custom.test1',
      name: 'Renamed',
      midiNotes: [36, 43, 48, 53, 57, 62],
      category: TuningCategory.custom,
      isCustom: true,
    ));
    expect(c.customTunings.single.name, 'Renamed');

    await c.deleteCustomTuning('custom.test1');
    expect(c.customTunings, isEmpty);
  });

  test('custom tunings survive a reload (persisted as JSON)', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final repo = CustomTuningsRepository(p);
    await repo.save([
      const TuningPreset(
        id: 'custom.x',
        name: 'X',
        midiNotes: [30, 35, 40, 45],
        category: TuningCategory.custom,
        isCustom: true,
        instrumentId: 'bass_4',
      ),
    ]);
    final loaded = CustomTuningsRepository(p).load();
    expect(loaded.single.name, 'X');
    expect(loaded.single.midiNotes, [30, 35, 40, 45]);
    expect(loaded.single.isCustom, isTrue);
    expect(loaded.single.instrumentId, 'bass_4');
  });

  test('start() without a microphone is a harmless no-op', () async {
    final c = await makeController();
    await c.start();
    expect(c.status, TunerStatus.idle);
  });
}
