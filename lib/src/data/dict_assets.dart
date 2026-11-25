/// Büyük çevrimdışı sözlük ve seviyeli kelime listesi (paket varlıkları).
///
/// Kaynak: FreeDict English-Turkish 0.3 ve Turkish-English 0.3
/// (https://github.com/freedict/fd-dictionaries), GNU GPL 2.0 veya sonrası.
/// Veri yalnızca ayrı bir varlık dosyası olarak dağıtılır; dönüştürme
/// betiği proto/apps/egitim/mkdict.py. Seviyeler wordfreq İngilizce
/// sıklığına göre yaklaşık atanır (resmî CEFR değildir).
library;

import 'package:flutter/services.dart' show rootBundle;

const String kDictAsset = 'packages/egitim_motoru/assets/dict/tr_en.tsv';
const String kVocabAsset = 'packages/egitim_motoru/assets/vocab/tr_en_levels.tsv';
const List<String> kVocabLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];

/// `tr<TAB>en` satırları → (tr, en). `#` ile başlayan satırlar yorumdur.
List<(String, String)> parseDictTsv(String s) => [
      for (final line in s.split('\n'))
        if (line.isNotEmpty && !line.startsWith('#') && line.contains('\t'))
          (line.substring(0, line.indexOf('\t')).trim(), line.substring(line.indexOf('\t') + 1).trim()),
    ];

/// `seviye<TAB>tr<TAB>en` satırları → (seviye, tr, en).
List<(String, String, String)> parseVocabTsv(String s) => [
      for (final line in s.split('\n'))
        if (line.isNotEmpty && !line.startsWith('#'))
          if (line.split('\t') case [final l, final tr, final en]) (l.trim(), tr.trim(), en.trim()),
    ];

Future<List<(String, String)>>? _dict;
Future<List<(String, String, String)>>? _vocab;

/// Sözlüğü bir kez yükler; varlık yoksa boş liste döner (çekirdek liste yine çalışır).
Future<List<(String, String)>> loadDictionary() => _dict ??= () async {
      try {
        return parseDictTsv(await rootBundle.loadString(kDictAsset));
      } catch (_) {
        return const <(String, String)>[];
      }
    }();

/// Seviyeli kelime listesini bir kez yükler; varlık yoksa boş liste döner.
Future<List<(String, String, String)>> loadVocabulary() => _vocab ??= () async {
      try {
        return parseVocabTsv(await rootBundle.loadString(kVocabAsset));
      } catch (_) {
        return const <(String, String, String)>[];
      }
    }();
