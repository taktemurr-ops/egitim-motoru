/// Seslendirme: cihazın kendi metin okuma motoru (flutter_tts; Android TTS,
/// iOS AVSpeechSynthesizer, web speechSynthesis). Ses yoksa sessizce false.
library;

import 'package:flutter_tts/flutter_tts.dart';

/// Dil kodu → denenecek yerel ayarlar (sırayla).
const Map<String, List<String>> kTtsLocales = {
  'tr': ['tr-TR'], 'en': ['en-US', 'en-GB'], 'de': ['de-DE'], 'es': ['es-ES', 'es-MX', 'es-US'],
  'fr': ['fr-FR', 'fr-CA'], 'ar': ['ar-SA', 'ar-001', 'ar-EG', 'ar'], 'fa': ['fa-IR', 'fa'], 'he': ['he-IL', 'iw-IL'],
  'ur': ['ur-PK', 'ur-IN'], 'ru': ['ru-RU'], 'uk': ['uk-UA'], 'pl': ['pl-PL'], 'cs': ['cs-CZ'],
  'ro': ['ro-RO'], 'hu': ['hu-HU'], 'el': ['el-GR'], 'it': ['it-IT'], 'pt': ['pt-BR', 'pt-PT'],
  'nl': ['nl-NL', 'nl-BE'], 'sv': ['sv-SE'], 'da': ['da-DK'], 'nb': ['nb-NO', 'no-NO'], 'fi': ['fi-FI'],
  'ja': ['ja-JP'], 'ko': ['ko-KR'], 'zh': ['zh-CN', 'cmn-CN', 'zh-TW'], 'hi': ['hi-IN'], 'bn': ['bn-BD', 'bn-IN'],
  'id': ['id-ID', 'in-ID'], 'ms': ['ms-MY'], 'th': ['th-TH'], 'vi': ['vi-VN'], 'fil': ['fil-PH', 'tl-PH'],
};

class Speaker {
  Speaker._();
  static final Speaker instance = Speaker._();

  FlutterTts? _tts;
  final Map<String, String?> _locale = {};

  FlutterTts get _engine => _tts ??= FlutterTts();

  /// [lang] için kullanılabilir yerel ayar (önbellekli); yoksa null.
  Future<String?> localeFor(String lang) async {
    if (_locale.containsKey(lang)) return _locale[lang];
    String? found;
    for (final l in kTtsLocales[lang] ?? const <String>[]) {
      try {
        final ok = await _engine.isLanguageAvailable(l);
        if (ok == true || ok == 1) {
          found = l;
          break;
        }
      } catch (_) {
        break;
      }
    }
    _locale[lang] = found;
    return found;
  }

  /// [text]'i [lang] dilinde okur; ses yoksa false.
  Future<bool> speak(String text, String lang, {double rate = 0.45}) async {
    try {
      final loc = await localeFor(lang);
      if (loc == null) return false;
      final e = _engine;
      await e.stop();
      await e.setLanguage(loc);
      await e.setSpeechRate(rate);
      await e.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
