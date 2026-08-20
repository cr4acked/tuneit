/// Hand-written localization (ru/en).
///
/// A deliberate choice over ARB codegen: zero build-time codegen keeps the
/// project robust across Flutter versions, and the abstract base class makes
/// "same keys in every language" a compile-time guarantee instead of a test.
/// Tuning names (Drop C, DADGAD, ...) and note names are intentionally not
/// translated — they are international in the guitar community.
library;

import 'package:flutter/widgets.dart';

abstract class Strings {
  const Strings();

  static Strings of(BuildContext context) {
    return Localizations.of<Strings>(context, Strings) ?? const StringsEn();
  }

  static const LocalizationsDelegate<Strings> delegate = _StringsDelegate();

  static const supportedLocales = [Locale('ru'), Locale('en')];

  // App
  String get appTitle;

  // Tuner
  String get listening;
  String get inTune;
  String get tuneUp; // string is flat -> tighten
  String get tuneDown; // string is sharp -> loosen
  String get modeAuto;
  String get modeManual;
  String get modeChromatic;
  String get micDeniedTitle;
  String get micDeniedBody;
  String get openSystemSettings;
  String get referenceTonesStillWork;
  String get longPressToPlayTone;
  String get octavePairsNote;
  String get stopTone;

  // Picker
  String get chooseTuning;
  String get searchTunings;
  String get recent;
  String get categoryStandard;
  String get categoryDrop;
  String get categoryLowered;
  String get categoryOpen;
  String get categoryAlternate;
  String get categoryCustom;
  String get nothingFound;

  // Custom tunings
  String get customTunings;
  String get newCustomTuning;
  String get editCustomTuning;
  String get tuningName;
  String get stringsCount;
  String get save;
  String get delete;
  String get duplicate;
  String get deleteTuningQuestion;
  String get cancel;
  String get startFromCurrent;
  String get allStringsDown;
  String get allStringsUp;

  // Metronome
  String get metronome;
  String get bpm;
  String get tapTempo;
  String get timeSignature;
  String get subdivision;
  String get subdivisionQuarters;
  String get subdivisionEighths;
  String get subdivisionTriplets;
  String get subdivisionSixteenths;
  String get accentFirstBeat;
  String get hapticPulse;

  // Settings
  String get settings;
  String get theme;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get a4Calibration;
  String get resetTo440;
  String get inTuneThreshold;
  String get centsSuffix;
  String get notation;
  String get notationSharps;
  String get notationFlats;
  String get hapticFeedback;
  String get language;
  String get languageSystem;
  String get languageRussian;
  String get languageEnglish;
  String get micSensitivity;
  String get sensitivityLow;
  String get sensitivityMedium;
  String get sensitivityHigh;
  String get about;
  String get aboutText;
  String get version;

  // Instruments (localized by id).
  String instrumentName(String id);
}

class StringsRu extends Strings {
  const StringsRu();

  @override
  String get appTitle => 'Tuneit';

  @override
  String get listening => 'Слушаю…';
  @override
  String get inTune => 'В строе';
  @override
  String get tuneUp => 'Подтяни';
  @override
  String get tuneDown => 'Ослабь';
  @override
  String get modeAuto => 'Авто';
  @override
  String get modeManual => 'Вручную';
  @override
  String get modeChromatic => 'Хроматика';
  @override
  String get micDeniedTitle => 'Нет доступа к микрофону';
  @override
  String get micDeniedBody =>
      'Микрофон нужен, чтобы слышать звук струны и показывать точность настройки. Запись никуда не отправляется и не сохраняется.';
  @override
  String get openSystemSettings => 'Открыть настройки';
  @override
  String get referenceTonesStillWork =>
      'Эталонные тоны работают и без микрофона: удерживайте струну, чтобы услышать её ноту.';
  @override
  String get longPressToPlayTone =>
      'Тап — выбрать струну, долгий тап — эталонный тон';
  @override
  String get octavePairsNote =>
      'Парные струны настраивайте на октаву выше (режим «Хроматика» подскажет).';
  @override
  String get stopTone => 'Остановить тон';

  @override
  String get chooseTuning => 'Инструмент и строй';
  @override
  String get searchTunings => 'Поиск строя…';
  @override
  String get recent => 'Недавние';
  @override
  String get categoryStandard => 'Стандартные';
  @override
  String get categoryDrop => 'Drop';
  @override
  String get categoryLowered => 'Пониженные / повышенные';
  @override
  String get categoryOpen => 'Открытые';
  @override
  String get categoryAlternate => 'Альтернативные';
  @override
  String get categoryCustom => 'Мои строи';
  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get customTunings => 'Мои строи';
  @override
  String get newCustomTuning => 'Новый строй';
  @override
  String get editCustomTuning => 'Изменить строй';
  @override
  String get tuningName => 'Название';
  @override
  String get stringsCount => 'Струн';
  @override
  String get save => 'Сохранить';
  @override
  String get delete => 'Удалить';
  @override
  String get duplicate => 'Дублировать';
  @override
  String get deleteTuningQuestion => 'Удалить этот строй?';
  @override
  String get cancel => 'Отмена';
  @override
  String get startFromCurrent => 'Взять текущий строй за основу';
  @override
  String get allStringsDown => 'Все −1 полутон';
  @override
  String get allStringsUp => 'Все +1 полутон';

  @override
  String get metronome => 'Метроном';
  @override
  String get bpm => 'BPM';
  @override
  String get tapTempo => 'Tap';
  @override
  String get timeSignature => 'Размер';
  @override
  String get subdivision => 'Дробление';
  @override
  String get subdivisionQuarters => 'Четверти';
  @override
  String get subdivisionEighths => 'Восьмые';
  @override
  String get subdivisionTriplets => 'Триоли';
  @override
  String get subdivisionSixteenths => 'Шестнадцатые';
  @override
  String get accentFirstBeat => 'Акцент на первую долю';
  @override
  String get hapticPulse => 'Вибро-пульс';

  @override
  String get settings => 'Настройки';
  @override
  String get theme => 'Тема';
  @override
  String get themeSystem => 'Системная';
  @override
  String get themeLight => 'Светлая';
  @override
  String get themeDark => 'Тёмная';
  @override
  String get a4Calibration => 'Калибровка A4';
  @override
  String get resetTo440 => 'Сброс на 440';
  @override
  String get inTuneThreshold => 'Порог «в строе»';
  @override
  String get centsSuffix => 'центов';
  @override
  String get notation => 'Нотация';
  @override
  String get notationSharps => 'Диезы (♯)';
  @override
  String get notationFlats => 'Бемоли (♭)';
  @override
  String get hapticFeedback => 'Вибро-отклик при попадании';
  @override
  String get language => 'Язык';
  @override
  String get languageSystem => 'Системный';
  @override
  String get languageRussian => 'Русский';
  @override
  String get languageEnglish => 'English';
  @override
  String get micSensitivity => 'Чувствительность микрофона';
  @override
  String get sensitivityLow => 'Низкая';
  @override
  String get sensitivityMedium => 'Средняя';
  @override
  String get sensitivityHigh => 'Высокая';
  @override
  String get about => 'О приложении';
  @override
  String get aboutText =>
      'Работает офлайн. Ничего не отправляет в сеть и не собирает данные.';
  @override
  String get version => 'Версия';

  @override
  String instrumentName(String id) {
    switch (id) {
      case 'guitar_6':
        return 'Гитара, 6 струн';
      case 'guitar_7':
        return 'Гитара, 7 струн';
      case 'guitar_8':
        return 'Гитара, 8 струн';
      case 'baritone_6':
        return 'Баритон-гитара';
      case 'guitar_12':
        return '12-струнная гитара';
      case 'bass_4':
        return 'Бас, 4 струны';
      case 'bass_5':
        return 'Бас, 5 струн';
      case 'bass_6':
        return 'Бас, 6 струн';
    }
    return id;
  }
}

class StringsEn extends Strings {
  const StringsEn();

  @override
  String get appTitle => 'Tuneit';

  @override
  String get listening => 'Listening…';
  @override
  String get inTune => 'In tune';
  @override
  String get tuneUp => 'Tune up';
  @override
  String get tuneDown => 'Tune down';
  @override
  String get modeAuto => 'Auto';
  @override
  String get modeManual => 'Manual';
  @override
  String get modeChromatic => 'Chromatic';
  @override
  String get micDeniedTitle => 'No microphone access';
  @override
  String get micDeniedBody =>
      'The microphone is used to hear the string and show tuning accuracy. Audio is never sent anywhere or stored.';
  @override
  String get openSystemSettings => 'Open settings';
  @override
  String get referenceTonesStillWork =>
      'Reference tones work without the microphone: long-press a string to hear its note.';
  @override
  String get longPressToPlayTone =>
      'Tap to select a string, long-press for its reference tone';
  @override
  String get octavePairsNote =>
      'Tune paired strings one octave higher (Chromatic mode will pick them up).';
  @override
  String get stopTone => 'Stop tone';

  @override
  String get chooseTuning => 'Instrument & tuning';
  @override
  String get searchTunings => 'Search tunings…';
  @override
  String get recent => 'Recent';
  @override
  String get categoryStandard => 'Standard';
  @override
  String get categoryDrop => 'Drop';
  @override
  String get categoryLowered => 'Lowered / raised';
  @override
  String get categoryOpen => 'Open';
  @override
  String get categoryAlternate => 'Alternate';
  @override
  String get categoryCustom => 'My tunings';
  @override
  String get nothingFound => 'Nothing found';

  @override
  String get customTunings => 'My tunings';
  @override
  String get newCustomTuning => 'New tuning';
  @override
  String get editCustomTuning => 'Edit tuning';
  @override
  String get tuningName => 'Name';
  @override
  String get stringsCount => 'Strings';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get duplicate => 'Duplicate';
  @override
  String get deleteTuningQuestion => 'Delete this tuning?';
  @override
  String get cancel => 'Cancel';
  @override
  String get startFromCurrent => 'Start from the current tuning';
  @override
  String get allStringsDown => 'All −1 semitone';
  @override
  String get allStringsUp => 'All +1 semitone';

  @override
  String get metronome => 'Metronome';
  @override
  String get bpm => 'BPM';
  @override
  String get tapTempo => 'Tap';
  @override
  String get timeSignature => 'Time signature';
  @override
  String get subdivision => 'Subdivision';
  @override
  String get subdivisionQuarters => 'Quarters';
  @override
  String get subdivisionEighths => 'Eighths';
  @override
  String get subdivisionTriplets => 'Triplets';
  @override
  String get subdivisionSixteenths => 'Sixteenths';
  @override
  String get accentFirstBeat => 'Accent first beat';
  @override
  String get hapticPulse => 'Haptic pulse';

  @override
  String get settings => 'Settings';
  @override
  String get theme => 'Theme';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get a4Calibration => 'A4 calibration';
  @override
  String get resetTo440 => 'Reset to 440';
  @override
  String get inTuneThreshold => '"In tune" threshold';
  @override
  String get centsSuffix => 'cents';
  @override
  String get notation => 'Notation';
  @override
  String get notationSharps => 'Sharps (♯)';
  @override
  String get notationFlats => 'Flats (♭)';
  @override
  String get hapticFeedback => 'Haptic on in-tune';
  @override
  String get language => 'Language';
  @override
  String get languageSystem => 'System';
  @override
  String get languageRussian => 'Русский';
  @override
  String get languageEnglish => 'English';
  @override
  String get micSensitivity => 'Microphone sensitivity';
  @override
  String get sensitivityLow => 'Low';
  @override
  String get sensitivityMedium => 'Medium';
  @override
  String get sensitivityHigh => 'High';
  @override
  String get about => 'About';
  @override
  String get aboutText =>
      'Works offline. Sends nothing to the network and collects no data.';
  @override
  String get version => 'Version';

  @override
  String instrumentName(String id) {
    switch (id) {
      case 'guitar_6':
        return 'Guitar, 6-string';
      case 'guitar_7':
        return 'Guitar, 7-string';
      case 'guitar_8':
        return 'Guitar, 8-string';
      case 'baritone_6':
        return 'Baritone guitar';
      case 'guitar_12':
        return '12-string guitar';
      case 'bass_4':
        return 'Bass, 4-string';
      case 'bass_5':
        return 'Bass, 5-string';
      case 'bass_6':
        return 'Bass, 6-string';
    }
    return id;
  }
}

class _StringsDelegate extends LocalizationsDelegate<Strings> {
  const _StringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ru' || locale.languageCode == 'en';

  @override
  Future<Strings> load(Locale locale) async {
    return locale.languageCode == 'ru' ? const StringsRu() : const StringsEn();
  }

  @override
  bool shouldReload(_StringsDelegate old) => false;
}
