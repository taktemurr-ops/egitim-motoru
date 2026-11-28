/// 4. tur eğitim uygulamalarının arayüzsüz (test edilebilir) mantığı:
/// 33 dilde adım adım dil kursu (mevcut 33 dilli kelime ve ifade verisinden),
/// Arap harfleri (konuma göre biçimler, harekeler) ve ASL parmak alfabesi
/// el şekli tanımları.
library;

import 'dart:math' as math;

import 'data/core_words.dart';
import 'data/phrases.dart';
import 'learn_core.dart';

// ================================================================ dil kursu

/// Kursun bir öğesi: kelime ya da ifade, 33 dilde.
class CourseItem {
  final String id;
  final String emoji;
  final List<String> text;
  final bool phrase;
  const CourseItem(this.id, this.emoji, this.text, {this.phrase = false});
}

/// Ünite: kategori kimliği ('greet', kelime kategorisi ya da 'p1'..'p4' ifade
/// kategorisi) ve dersleri.
class CourseUnit {
  final String cat;
  final List<List<CourseItem>> lessons;
  const CourseUnit(this.cat, this.lessons);
}

/// Ünite sırası: selamlaşma, temel kelimeler, sonra günlük ifadeler.
const List<String> kCourseOrder = [
  'greet', 'num', 'color', 'people', 'food', 'fruit', 'animal', 'body', 'clothes', 'home', 'p1', 'transport',
  'place', 'p2', 'time', 'day', 'month', 'p3', 'nature', 'feel', 'direction', 'shape', 'p4',
];

/// Ünite başlığı etiketi: kelime kategorileri `vc_*`, ifadeler `phrase_cats` listesinden.
String unitLabelKey(String cat) => cat.startsWith('p') && cat.length == 2 ? 'phrase_cats' : 'vc_$cat';

int phraseCatOf(String cat) => cat == 'greet' ? 0 : int.parse(cat.substring(1));

List<List<T>> _chunks<T>(List<T> xs, int size) {
  final out = <List<T>>[];
  for (var i = 0; i < xs.length; i += size) {
    out.add(xs.sublist(i, math.min(xs.length, i + size)));
  }
  // Çok kısa son dersi bir öncekine kat.
  if (out.length > 1 && out.last.length < 3) {
    final last = out.removeLast();
    out.last = [...out.last, ...last];
  }
  return out;
}

/// Bütün kurs (dil bağımsız; metinler 33 dilde).
List<CourseUnit> buildCourse({int size = 6}) {
  final units = <CourseUnit>[];
  for (final cat in kCourseOrder) {
    final List<CourseItem> items;
    if (cat == 'greet' || (cat.startsWith('p') && cat.length == 2)) {
      final pc = phraseCatOf(cat);
      items = [for (final p in kPhrases.where((p) => p.cat == pc)) CourseItem('p:${p.text[1]}', '💬', p.text, phrase: true)];
    } else {
      items = [for (final w in kCoreWords.where((w) => w.cat == cat)) CourseItem('w:$cat:${w.w[1]}', w.emoji, w.w)];
    }
    if (items.isNotEmpty) units.add(CourseUnit(cat, _chunks(items, size)));
  }
  return units;
}

/// Boşlukla sözcüklere ayrılmayan yazılar (ifade kurma alıştırması yok).
bool usesSpaces(String lang) => !const {'ja', 'zh', 'th'}.contains(lang);

List<String> tokensOf(String text) => text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

enum ExKind { meaning, word, build }

/// Bir alıştırma: [meaning] hedef dildeki öğenin anlamını seç, [word] bilinen
/// dildeki anlamın hedef dildeki karşılığını seç, [build] ifadeyi sözcüklerden kur.
class Exercise {
  final ExKind kind;
  final CourseItem item;
  final List<CourseItem> options;
  final List<String> tokens; // build: karışık sözcükler
  const Exercise(this.kind, this.item, {this.options = const [], this.tokens = const []});

  int get answer => options.indexOf(item);
}

/// [item] için alıştırma; çeldiriciler [pool]'dan, iki dilde de metni farklı olanlar.
Exercise makeExercise(math.Random r, CourseItem item, List<CourseItem> pool, int learn, int know, {ExKind? kind}) {
  final lang = kLangCodes[learn];
  final toks = tokensOf(item.text[learn]);
  final canBuild = item.phrase && usesSpaces(lang) && toks.length >= 2;
  final k = kind ?? (canBuild && r.nextInt(3) == 0 ? ExKind.build : (r.nextBool() ? ExKind.meaning : ExKind.word));
  if (k == ExKind.build && canBuild) {
    var shuffled = List<String>.of(toks);
    for (var i = 0; i < 5 && _same(shuffled, toks); i++) {
      shuffled.shuffle(r);
    }
    if (_same(shuffled, toks)) shuffled = toks.reversed.toList();
    return Exercise(ExKind.build, item, tokens: shuffled);
  }
  final kk = k == ExKind.build ? ExKind.meaning : k;
  final seenL = {item.text[learn]}, seenK = {item.text[know]};
  final cands = [for (final c in pool) if (c.id != item.id) c]..shuffle(r);
  // Önce aynı türden (kelime/ifade) çeldiriciler.
  cands.sort((a, b) => (a.phrase == item.phrase ? 0 : 1) - (b.phrase == item.phrase ? 0 : 1));
  final opts = <CourseItem>[item];
  for (final c in cands) {
    if (opts.length == 4) break;
    if (seenL.contains(c.text[learn]) || seenK.contains(c.text[know])) continue;
    seenL.add(c.text[learn]);
    seenK.add(c.text[know]);
    opts.add(c);
  }
  opts.shuffle(r);
  return Exercise(kk, item, options: opts);
}

bool _same(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Kurulan ifade doğru mu (noktalama ve büyük/küçük harf önemsiz).
bool buildCorrect(List<String> picked, CourseItem item, int learn) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[.,!?¿¡。、？！،؟]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  return norm(picked.join(' ')) == norm(item.text[learn]);
}

/// Ders kuyruğu: her yeni öğe iki kez (anlam + karşılık), önceki derslerden en
/// çok [reviewCount] öğe bir kez; aynı öğe art arda gelmez.
List<(CourseItem, ExKind?)> lessonQueue(math.Random r, List<CourseItem> items, List<CourseItem> earlier, {int reviewCount = 2}) {
  final pool = <(CourseItem, ExKind?)>[
    for (final it in items) (it, ExKind.meaning),
    for (final it in items) (it, it.phrase ? null : ExKind.word),
    for (final it in (List<CourseItem>.of(earlier)..shuffle(r)).take(reviewCount)) (it, null),
  ]..shuffle(r);
  // Açgözlü sıralama: bir önceki öğeden farklı olan ilk öğe; yalnızca geriye
  // aynı öğe kaldığında (en sonda) art arda gelebilir.
  final q = <(CourseItem, ExKind?)>[];
  while (pool.isNotEmpty) {
    var k = pool.indexWhere((e) => q.isEmpty || e.$1.id != q.last.$1.id);
    if (k < 0) k = 0;
    q.add(pool.removeAt(k));
  }
  return q;
}

/// Günlük seri: bugün zaten çalışıldıysa aynı, dün çalışıldıysa +1, yoksa 1.
int bumpStreak(int streak, String? lastIso, DateTime today) {
  final d = DateTime(today.year, today.month, today.day);
  String iso(DateTime x) => '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
  if (lastIso == iso(d)) return math.max(1, streak);
  if (lastIso == iso(DateTime(d.year, d.month, d.day - 1))) return streak + 1;
  return 1;
}

/// Aralıklı tekrar durumunu saklanabilir listeye çevirir ve geri okur.
List<Object> cardToJson(CardState s) => [s.ef, s.interval, s.reps, s.due.millisecondsSinceEpoch];

CardState? cardFromJson(Object? v) {
  if (v is! List || v.length != 4 || v.any((x) => x is! num)) return null;
  return CardState(
    ef: (v[0] as num).toDouble(),
    interval: (v[1] as num).toInt(),
    reps: (v[2] as num).toInt(),
    due: DateTime.fromMillisecondsSinceEpoch((v[3] as num).toInt()),
  );
}

// ================================================================ Arap harfleri

class ArLetter {
  final String ch;

  /// Latin harfli ad (ISO 233 benzeri) ve harfin Arapça/Farsça adı.
  final String name, nativeName;

  /// Ses değeri (Latin harf çevirisi).
  final String sound;

  /// Kendinden sonraki harfe bağlanır mı (ا د ذ ر ز و bağlanmaz).
  final bool joinsNext;

  /// Farsça, Urduca ve Osmanlı Türkçesindeki ek harf.
  final bool extra;
  const ArLetter(this.ch, this.name, this.nativeName, this.sound, {this.joinsNext = true, this.extra = false});
}

const List<ArLetter> kArLetters = [
  ArLetter('ا', 'alif', 'ألف', 'ā', joinsNext: false),
  ArLetter('ب', 'bāʾ', 'باء', 'b'),
  ArLetter('ت', 'tāʾ', 'تاء', 't'),
  ArLetter('ث', 'thāʾ', 'ثاء', 'th'),
  ArLetter('ج', 'jīm', 'جيم', 'j'),
  ArLetter('ح', 'ḥāʾ', 'حاء', 'ḥ'),
  ArLetter('خ', 'khāʾ', 'خاء', 'kh'),
  ArLetter('د', 'dāl', 'دال', 'd', joinsNext: false),
  ArLetter('ذ', 'dhāl', 'ذال', 'dh', joinsNext: false),
  ArLetter('ر', 'rāʾ', 'راء', 'r', joinsNext: false),
  ArLetter('ز', 'zāy', 'زاي', 'z', joinsNext: false),
  ArLetter('س', 'sīn', 'سين', 's'),
  ArLetter('ش', 'shīn', 'شين', 'sh'),
  ArLetter('ص', 'ṣād', 'صاد', 'ṣ'),
  ArLetter('ض', 'ḍād', 'ضاد', 'ḍ'),
  ArLetter('ط', 'ṭāʾ', 'طاء', 'ṭ'),
  ArLetter('ظ', 'ẓāʾ', 'ظاء', 'ẓ'),
  ArLetter('ع', 'ʿayn', 'عين', 'ʿ'),
  ArLetter('غ', 'ghayn', 'غين', 'gh'),
  ArLetter('ف', 'fāʾ', 'فاء', 'f'),
  ArLetter('ق', 'qāf', 'قاف', 'q'),
  ArLetter('ك', 'kāf', 'كاف', 'k'),
  ArLetter('ل', 'lām', 'لام', 'l'),
  ArLetter('م', 'mīm', 'ميم', 'm'),
  ArLetter('ن', 'nūn', 'نون', 'n'),
  ArLetter('ه', 'hāʾ', 'هاء', 'h'),
  ArLetter('و', 'wāw', 'واو', 'w', joinsNext: false),
  ArLetter('ي', 'yāʾ', 'ياء', 'y'),
  ArLetter('پ', 'pe', 'پ', 'p', extra: true),
  ArLetter('چ', 'che', 'چ', 'ch', extra: true),
  ArLetter('ژ', 'zhe', 'ژ', 'zh', extra: true),
  ArLetter('گ', 'gāf', 'گاف', 'g', extra: true),
];

const String _zwj = '‍';

/// Konuma göre biçim: 0 tek başına, 1 başta, 2 ortada, 3 sonda. Yazı tipi
/// biçimi sıfır genişlikli birleştiriciyle (ZWJ) seçer.
String arForm(ArLetter l, int pos) => switch (pos) {
      1 => l.joinsNext ? '${l.ch}$_zwj' : l.ch,
      2 => l.joinsNext ? '$_zwj${l.ch}$_zwj' : '$_zwj${l.ch}',
      3 => '$_zwj${l.ch}',
      _ => l.ch,
    };

/// Hareke: işaret, Latin adı, okunuşa etkisi ve konum (true: harfin altında).
class ArMark {
  final String mark, name, vowel;
  final bool below;
  const ArMark(this.mark, this.name, this.vowel, {this.below = false});
}

const List<ArMark> kArMarks = [
  ArMark('َ', 'fatḥa', 'a'),
  ArMark('ِ', 'kasra', 'i', below: true),
  ArMark('ُ', 'ḍamma', 'u'),
  ArMark('ْ', 'sukūn', ''),
  ArMark('ّ', 'shadda', '+'),
  ArMark('ً', 'tanwīn fatḥ', 'an'),
  ArMark('ٍ', 'tanwīn kasr', 'in', below: true),
  ArMark('ٌ', 'tanwīn ḍamm', 'un'),
];

/// Okunuşu: harf + hareke → Latin hece (ör. بُ → bu, بّ → bb).
String syllableOf(ArLetter l, ArMark m) => m.vowel == '+' ? '${l.sound}${l.sound}' : '${l.sound}${m.vowel}';

/// Hece alıştırmasında kullanılan ünsüzler (alif ve ek harfler dışında).
List<ArLetter> get syllableLetters => [for (final l in kArLetters) if (l.ch != 'ا' && !l.extra) l];

/// Hece sorusu: doğru okunuş + 3 çeldirici (aynı harf başka hareke ya da aynı hareke başka harf).
({String text, String answer, List<String> options}) syllableQuestion(math.Random r) {
  final ls = syllableLetters;
  final l = ls[r.nextInt(ls.length)];
  final vowels = kArMarks.where((m) => m.vowel != '+' && m.vowel.isNotEmpty).toList();
  final m = vowels[r.nextInt(vowels.length)];
  final answer = syllableOf(l, m);
  final opts = <String>{answer};
  for (final o in vowels..shuffle(r)) {
    if (opts.length >= 3) break;
    opts.add(syllableOf(l, o));
  }
  while (opts.length < 4) {
    opts.add(syllableOf(ls[r.nextInt(ls.length)], m));
  }
  return (text: '${l.ch}${m.mark}', answer: answer, options: opts.toList()..shuffle(r));
}

// ================================================================ ASL parmak alfabesi

/// Parmak durumu: u açık (bitişik), s açık (aralıklı), c kapalı (avuca kıvrık),
/// h çengel (boğumdan bükük), v C biçiminde kavisli, t ucu başparmağa değiyor,
/// x orta parmak işaret parmağının üstünden çapraz.
/// Başparmak: side (işaret parmağının yanında, yukarı), across (parmakların
/// önünden yatay), out (yana açık), parallel (işaret parmağıyla aynı yönde),
/// touch (parmak uçlarına değiyor), between (işaret ile orta arasında),
/// up_between (K: işaret ile orta arasında, yukarıda), under2 / under3 (iki /
/// üç parmağın altında), curve (C).
class HandShape {
  final String letter;
  final String fingers; // işaret, orta, yüzük, serçe
  final String thumb;

  /// 0 yukarı, 1 yana (G, H), 2 aşağı (P, Q).
  final int orient;

  /// Hareketli harf: 'J' ya da 'Z'.
  final String? motion;
  const HandShape(this.letter, this.fingers, this.thumb, {this.orient = 0, this.motion});
}

/// ASL (American Sign Language) el alfabesi, sağ el, avuç izleyiciye dönük
/// (G/H yana, P/Q aşağı). Şematik tanım; bkz. uygulamadaki kaynak notu.
const List<HandShape> kAslAlphabet = [
  HandShape('A', 'cccc', 'side'),
  HandShape('B', 'uuuu', 'across'),
  HandShape('C', 'vvvv', 'curve'),
  HandShape('D', 'uttt', 'touch'),
  HandShape('E', 'hhhh', 'under4'),
  HandShape('F', 'tsss', 'touch'),
  HandShape('G', 'uccc', 'parallel', orient: 1),
  HandShape('H', 'uucc', 'across', orient: 1),
  HandShape('I', 'cccs', 'across'),
  HandShape('J', 'cccs', 'across', motion: 'J'),
  HandShape('K', 'uscc', 'up_between'),
  HandShape('L', 'uccc', 'out'),
  HandShape('M', 'cccc', 'under3'),
  HandShape('N', 'cccc', 'under2'),
  HandShape('O', 'tttt', 'touch'),
  HandShape('P', 'uscc', 'up_between', orient: 2),
  HandShape('Q', 'uccc', 'parallel', orient: 2),
  HandShape('R', 'uxcc', 'across'),
  HandShape('S', 'cccc', 'across'),
  HandShape('T', 'cccc', 'between'),
  HandShape('U', 'uucc', 'across'),
  HandShape('V', 'sscc', 'across'),
  HandShape('W', 'sssc', 'across'),
  HandShape('X', 'hccc', 'across'),
  HandShape('Y', 'cccs', 'out'),
  HandShape('Z', 'uccc', 'across', motion: 'Z'),
];

HandShape? handFor(String ch) {
  final u = ch.toUpperCase();
  for (final h in kAslAlphabet) {
    if (h.letter == u) return h;
  }
  return null;
}

/// Parmakla hecelenecek harfler (A–Z dışı karakterler atlanır, boşluk korunur).
List<String> spellable(String text) {
  final out = <String>[];
  for (final r in text.toUpperCase().runes) {
    final c = String.fromCharCode(r);
    if (handFor(c) != null) {
      out.add(c);
    } else if (c == ' ' && out.isNotEmpty && out.last != ' ') {
      out.add(' ');
    }
  }
  while (out.isNotEmpty && out.last == ' ') {
    out.removeLast();
  }
  return out;
}

/// Okuma alıştırması için İngilizce kelimeler (temel kelimelerden, 3–7 harf, yalnız A–Z).
List<String> fingerspellWords() {
  final out = <String>{};
  for (final w in kCoreWords) {
    final e = w.w[1].toLowerCase();
    if (RegExp(r'^[a-z]{3,7}$').hasMatch(e)) out.add(e);
  }
  return out.toList()..sort();
}

// ================================================================ iz sürme puanı

/// İz sürme puanı: [mask] (w×h, harfin dolu pikselleri) ve parmak izi
/// noktaları. coverage: harf piksellerinin (3 px adımla örneklenmiş) ize
/// [r] pikselden yakın olan oranı; precision: iz noktalarının harfe [r]
/// pikselden yakın olan oranı.
({double coverage, double precision}) traceScore(List<bool> mask, int w, int h, List<(double, double)> pts, {double r = 14}) {
  if (pts.isEmpty) return (coverage: 0, precision: 0);
  final cell = r.ceil();
  final gw = (w / cell).ceil() + 1, gh = (h / cell).ceil() + 1;
  final buckets = List<List<(double, double)>>.generate(gw * gh, (_) => []);
  for (final p in pts) {
    final gx = (p.$1 / cell).floor().clamp(0, gw - 1), gy = (p.$2 / cell).floor().clamp(0, gh - 1);
    buckets[gy * gw + gx].add(p);
  }
  bool nearStroke(int x, int y) {
    final gx = x ~/ cell, gy = y ~/ cell;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final bx = gx + dx, by = gy + dy;
        if (bx < 0 || by < 0 || bx >= gw || by >= gh) continue;
        for (final p in buckets[by * gw + bx]) {
          final ddx = p.$1 - x, ddy = p.$2 - y;
          if (ddx * ddx + ddy * ddy <= r * r) return true;
        }
      }
    }
    return false;
  }

  var total = 0, covered = 0;
  for (var y = 0; y < h; y += 3) {
    for (var x = 0; x < w; x += 3) {
      if (!mask[y * w + x]) continue;
      total++;
      if (nearStroke(x, y)) covered++;
    }
  }
  bool nearMask(double px, double py) {
    final ri = r.ceil();
    for (var y = math.max(0, py.round() - ri); y <= math.min(h - 1, py.round() + ri); y += 2) {
      for (var x = math.max(0, px.round() - ri); x <= math.min(w - 1, px.round() + ri); x += 2) {
        if (mask[y * w + x] && (x - px) * (x - px) + (y - py) * (y - py) <= r * r) return true;
      }
    }
    return false;
  }

  var inside = 0;
  for (final p in pts) {
    if (nearMask(p.$1, p.$2)) inside++;
  }
  return (coverage: total == 0 ? 0 : covered / total, precision: inside / pts.length);
}

/// Yıldız (0–3): kapsama ve isabetten.
int traceStars(double coverage, double precision) {
  if (precision < 0.6 || coverage < 0.35) return 0;
  if (coverage >= 0.75 && precision >= 0.85) return 3;
  if (coverage >= 0.55 && precision >= 0.75) return 2;
  return 1;
}
