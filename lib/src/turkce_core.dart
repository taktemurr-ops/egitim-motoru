/// Türkçe dilbilgisi ve yazımın saf mantığı (arayüzsüz, testli): ünlü
/// uyumları, hece bölme, ek getirme (ünlü uyumu, ünsüz benzeşmesi,
/// yumuşama, kaynaştırma, ünlü düşmesi; istisna listeleriyle) ve sık yapılan
/// yazım yanlışlarını bulma. Türk Dil Kurumu yazım kurallarındaki genel
/// ilkelere dayanır; kurala uymayan sözcükler olabilir.
library;

const String _vowels = 'aeıioöuüâîû';
const String _back = 'aıouâû';
const String _rounded = 'oöuüû';
const String _hard = 'fstkçşhp';

String trLower(String s) => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

bool isVowel(String c) => _vowels.contains(trLower(c));

/// Sözcükteki ünlüler (sırayla).
List<String> vowelsOf(String word) => [
      for (final c in trLower(word).split(''))
        if (_vowels.contains(c)) c,
    ];

String? _lastVowel(String word) {
  final v = vowelsOf(word);
  return v.isEmpty ? null : v.last;
}

bool _isBack(String v) => _back.contains(v);
bool _isRounded(String v) => _rounded.contains(v);

/// Büyük ünlü uyumu: ünlülerin hepsi kalın ya da hepsi ince mi?
bool bigHarmony(String word) {
  final v = vowelsOf(word);
  if (v.length < 2) return true;
  final b = _isBack(v.first);
  return v.every((x) => _isBack(x) == b);
}

/// Küçük ünlü uyumu: düzden sonra düz; yuvarlaktan sonra dar-yuvarlak ya da
/// düz-geniş (a, e) gelir.
bool smallHarmony(String word) {
  final v = vowelsOf(word);
  for (var i = 1; i < v.length; i++) {
    final prev = v[i - 1], cur = v[i];
    if (!_isRounded(prev)) {
      if (_isRounded(cur)) return false;
    } else {
      if (!(('uüû').contains(cur) || cur == 'a' || cur == 'e')) return false;
    }
  }
  return true;
}

/// Heceleme: her hecede bir ünlü bulunur; iki ünlü arasındaki tek ünsüz
/// sonraki heceye, ikiden fazla ünsüzün sonuncusu sonraki heceye geçer.
/// Başta ünsüz öbeği olan alıntı sözcükler (tren, spor) desteklenir.
List<String> syllables(String word) {
  final w = word.trim();
  if (w.isEmpty) return [];
  final chars = w.split('');
  final vIdx = <int>[for (var i = 0; i < chars.length; i++) if (isVowel(chars[i])) i];
  if (vIdx.length <= 1) return [w];
  final cuts = <int>[];
  for (var k = 0; k < vIdx.length - 1; k++) {
    final a = vIdx[k], b = vIdx[k + 1];
    final cons = b - a - 1;
    // 0 ünsüz: ünlü yanyana (sa-at); 1: önceki|sonraki; 2+: son ünsüz sonraki heceye.
    cuts.add(cons == 0 ? b : b - 1);
  }
  final out = <String>[];
  var start = 0;
  for (final c in cuts) {
    out.add(w.substring(start, c));
    start = c;
  }
  out.add(w.substring(start));
  return out;
}

/// Ek türleri.
enum Suffix { plural, accusative, dative, locative, ablative, genitive, possessive1, instrumental }

/// Son hecesi kalın olduğu hâlde ince ek alan alıntı sözcükler.
const Set<String> kFrontSuffixWords = {
  'saat', 'harf', 'alkol', 'kalp', 'hal', 'rol', 'gol', 'petrol', 'meal', 'kontrol', 'protokol', 'sual', 'hayal',
  'istiklal', 'misal', 'emsal', 'ihtimal', 'idrak', 'iştirak', 'infilak', 'hakikat', 'tahsilat', 'kabul', 'usul', 'vakit',
  'dikkat', 'ziraat', 'sanat', 'kanaat', 'cemaat', 'itaat', 'helal', 'ahval', 'idman', 'mahsul', 'meşgul', 'mahsus',
};

/// Sona yumuşamayan çok heceli sözcükler (çoğu alıntı).
const Set<String> kNoSoften = {
  'millet', 'devlet', 'hukuk', 'sepet', 'saat', 'cumhuriyet', 'bisiklet', 'paket', 'bilet', 'adalet', 'hayat', 'sanat',
  'hakikat', 'dikkat', 'ziraat', 'kanaat', 'cemaat', 'itaat', 'ahlak', 'merak', 'idrak', 'iştirak', 'evrak', 'ittifak',
  'avukat', 'ticaret', 'hizmet', 'ibadet', 'ceket', 'raket', 'roket', 'demet', 'kibrit', 'suret', 'servet', 'sohbet',
  'kuvvet', 'nimet', 'saadet', 'sıhhat', 'kıyamet', 'tabiat', 'mekanizmat', 'sükût', 'otomat', 'kaset', 'puset',
};

/// Yumuşayan tek heceli sözcükler (çoğu tek heceli yumuşamaz).
const Set<String> kSoftenMono = {
  'uç', 'güç', 'kap', 'dip', 'kurt', 'tat', 'dert', 'renk', 'çok', 'yurt', 'but', 'dört', 'gök', 'cep', 'kulp', 'denk',
  'kalp', 'harp', 'genç', 'borç', 'taç',
};

/// Ünlüyle başlayan ek alınca son hecedeki ünlüsü düşen sözcükler.
const Map<String, String> kVowelDrop = {
  'ağız': 'ağz', 'burun': 'burn', 'oğul': 'oğl', 'alın': 'aln', 'beyin': 'beyn', 'gönül': 'gönl', 'isim': 'ism',
  'resim': 'resm', 'şehir': 'şehr', 'akıl': 'akl', 'fikir': 'fikr', 'ömür': 'ömr', 'sabır': 'sabr', 'nehir': 'nehr',
  'karın': 'karn', 'boyun': 'boyn', 'göğüs': 'göğs', 'bağır': 'bağr', 'kayın': 'kayn', 'koyun': 'koyn', 'metin': 'metn',
  'zehir': 'zehr', 'şükür': 'şükr', 'kahır': 'kahr', 'hüküm': 'hükm', 'cisim': 'cism', 'kısım': 'kısm', 'vakit': 'vakt',
  'nesil': 'nesl', 'asıl': 'asl', 'hayır': 'hayr', 'kadir': 'kadr', 'emir': 'emr', 'seyir': 'seyr', 'hapis': 'haps',
};

bool _frontForSuffix(String word) {
  final w = trLower(word);
  if (kFrontSuffixWords.contains(w)) return true;
  final v = _lastVowel(w);
  return v != null && !_isBack(v);
}

String _narrow(String word) {
  // dar ünlü: ı i u ü
  final w = trLower(word);
  final v = _lastVowel(w) ?? 'e';
  final front = _frontForSuffix(w);
  final r = _isRounded(v);
  if (front) return r ? 'ü' : 'i';
  return r ? 'u' : 'ı';
}

String _wide(String word) => _frontForSuffix(word) ? 'e' : 'a';

/// Ünlüyle başlayan ek öncesi gövde: ünlü düşmesi ve ünsüz yumuşaması.
String _stemForVowelSuffix(String word) {
  final w = trLower(word);
  final drop = kVowelDrop[w];
  if (drop != null) return _keepCase(word, drop);
  if (w.isEmpty) return word;
  final last = w[w.length - 1];
  if (!'pçtk'.contains(last)) return word;
  final syl = vowelsOf(w).length;
  if (syl <= 1 ? !kSoftenMono.contains(w) : kNoSoften.contains(w)) return word;
  String soft;
  switch (last) {
    case 'p':
      soft = 'b';
    case 'ç':
      soft = 'c';
    case 't':
      soft = 'd';
    default:
      // k → ğ; "nk" → "ng"
      soft = w.length > 1 && w[w.length - 2] == 'n' ? 'g' : 'ğ';
  }
  return word.substring(0, word.length - 1) + soft;
}

String _keepCase(String original, String lowerStem) =>
    original.isNotEmpty && original[0] != trLower(original[0]) ? original[0] + lowerStem.substring(1) : lowerStem;

bool _endsWithVowel(String word) => word.isNotEmpty && isVowel(word[word.length - 1]);

bool _endsHard(String word) => word.isNotEmpty && _hard.contains(trLower(word[word.length - 1]));

/// Özel adlar (büyük harfle başlayan) eki kesme işaretiyle alır.
bool _proper(String word) => word.isNotEmpty && word[0] != trLower(word[0]);

/// Sözcüğe ek getirir. Örnek: kitap + belirtme → kitabı; İstanbul + bulunma → İstanbul'da.
String addSuffix(String word, Suffix s) {
  final w = word.trim();
  if (w.isEmpty) return '';
  final proper = _proper(w);
  final sep = proper ? "'" : '';
  final vEnd = _endsWithVowel(w);
  final n = _narrow(w), a = _wide(w);
  String vowelSuffix(String suffix) {
    // Özel adlarda yumuşama yazıya yansıtılmaz (Mehmet'i).
    final stem = vEnd || proper ? w : _stemForVowelSuffix(w);
    return '$stem$sep$suffix';
  }

  switch (s) {
    case Suffix.plural:
      return '$w${sep}l${a}r';
    case Suffix.accusative:
      return vEnd ? '$w${sep}y$n' : vowelSuffix(n);
    case Suffix.dative:
      return vEnd ? '$w${sep}y$a' : vowelSuffix(a);
    case Suffix.locative:
      return '$w$sep${_endsHard(w) ? 't' : 'd'}$a';
    case Suffix.ablative:
      return '$w$sep${_endsHard(w) ? 't' : 'd'}${a}n';
    case Suffix.genitive:
      return vEnd ? '$w${sep}n${n}n' : vowelSuffix('${n}n');
    case Suffix.possessive1:
      return vEnd ? '$w${sep}m' : vowelSuffix('${n}m');
    case Suffix.instrumental:
      return vEnd ? '$w${sep}yl$a' : '$w${sep}l$a';
  }
}

/// Sık yapılan yazım yanlışları: yanlış → doğru (küçük harf).
const Map<String, String> kMisspellings = {
  'herkez': 'herkes', 'yanlız': 'yalnız', 'yalnış': 'yanlış', 'malesef': 'maalesef', 'eşortman': 'eşofman',
  'süpriz': 'sürpriz', 'kirbik': 'kirpik', 'klavuz': 'kılavuz', 'orjinal': 'orijinal', 'profösör': 'profesör',
  'traş': 'tıraş', 'entellektüel': 'entelektüel', 'egzos': 'egzoz', 'eksoz': 'egzoz', 'aşşağı': 'aşağı',
  'yada': 'ya da', 'birşey': 'bir şey', 'herşey': 'her şey', 'hiçbirşey': 'hiçbir şey', 'şöför': 'şoför',
  'şöförler': 'şoförler', 'kordinat': 'koordinat', 'kordinasyon': 'koordinasyon', 'fotokobi': 'fotokopi',
  'antreman': 'antrenman', 'makina': 'makine', 'pantalon': 'pantolon', 'mütevazi': 'mütevazı', 'muhattap': 'muhatap',
  'tesbit': 'tespit', 'meyva': 'meyve', 'sarmısak': 'sarımsak', 'kıravat': 'kravat', 'bilimum': 'bilumum',
  'pilaj': 'plaj', 'mahallebi': 'muhallebi', 'ünvan': 'unvan', 'şarz': 'şarj', 'sandoviç': 'sandviç',
  'kuafür': 'kuaför', 'hergün': 'her gün', 'herzaman': 'her zaman', 'birsürü': 'bir sürü', 'yanlızca': 'yalnızca',
  'yalnışlıkla': 'yanlışlıkla', 'birdaha': 'bir daha', 'herhangibir': 'herhangi bir', 'tabiki': 'tabii ki',
  'bişey': 'bir şey', 'varmı': 'var mı', 'yokmu': 'yok mu', 'gelecekmisin': 'gelecek misin',
  'öğretmenmi': 'öğretmen mi', 'kirbi': 'kirpi', 'eşarpı': 'eşarbı', 'yüzölçüm': 'yüz ölçümü', 'kollanya': 'kolonya',
  'laboratuar': 'laboratuvar', 'kontür': 'kontör', 'steteskop': 'stetoskop', 'poaça': 'poğaça',
  'psikolok': 'psikolog', 'rötüş': 'rötuş', 'mönü': 'menü', 'menu': 'menü', 'aksesuvar': 'aksesuar',
  'dövis': 'döviz', 'kiloğram': 'kilogram', 'kilomtere': 'kilometre', 'teprikler': 'tebrikler',
  'dinazor': 'dinozor', 'çikolota': 'çikolata', 'çukulata': 'çikolata',
};

/// Birden fazla sözcükten oluşan yanlışlar (bitişik yazılması gerekenler).
const Map<String, String> kMisspelledPhrases = {
  'hiç bir': 'hiçbir', 'bir çok': 'birçok', 'bir kaç': 'birkaç', 'her hangi': 'herhangi', 'şu an da': 'şu anda',
  'her kes': 'herkes', 'bir takım': 'birtakım', 'kayın valide': 'kayınvalide', 'güney doğu': 'güneydoğu',
  'kuzey batı': 'kuzeybatı', 'öz geçmiş': 'özgeçmiş', 'ilk okul': 'ilkokul', 'orta okul': 'ortaokul',
  'baş öğretmen': 'başöğretmen', 'hanım eli': 'hanımeli', 'alt yapı': 'altyapı', 'yüz yıl': 'yüzyıl',
};

/// Metindeki yazım yanlışları: (bulunan, öneri, başlangıç konumu).
List<(String, String, int)> spellIssues(String text) {
  final out = <(String, String, int)>[];
  final lower = trLower(text);
  kMisspelledPhrases.forEach((wrong, right) {
    if (wrong == right) return;
    var i = 0;
    while (true) {
      final at = lower.indexOf(wrong, i);
      if (at < 0) break;
      final before = at == 0 || !RegExp(r'[a-zçğıöşüâîû]').hasMatch(lower[at - 1]);
      final end = at + wrong.length;
      final after = end >= lower.length || !RegExp(r'[a-zçğıöşüâîû]').hasMatch(lower[end]);
      if (before && after) out.add((text.substring(at, end), right, at));
      i = end;
    }
  });
  for (final m in RegExp(r"[A-Za-zÇĞİÖŞÜçğıöşüÂÎÛâîû]+").allMatches(text)) {
    final w = trLower(m.group(0)!);
    final r = kMisspellings[w];
    if (r != null && r != w) out.add((m.group(0)!, r, m.start));
  }
  out.sort((a, b) => a.$3.compareTo(b.$3));
  return out;
}

/// Test için doğru/yanlış yazım çiftleri (yanlışlar listesinden, yalnız gerçekten farklı olanlar).
List<(String, String)> spellingPairs() => [
      for (final e in {...kMisspellings, ...kMisspelledPhrases}.entries)
        if (e.key != e.value) (e.value, e.key),
    ];
