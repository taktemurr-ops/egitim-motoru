import 'dart:io';
import 'dart:math' as math;

import 'package:egitim_motoru/egitim_motoru.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:studio_core/core/save_store.dart';

void main() {
  test('52 uygulama, 33 dilde ad ve açıklama, geçerli kategori', () {
    expect(egitimTools.length, 52);
    expect(egitimTools.map((t) => t.id).toSet().length, 52);
    for (final t in egitimTools) {
      expect(t.title.length, 33, reason: t.id);
      expect(t.tagline.length, 33, reason: t.id);
      expect(t.id.startsWith('uyg-'), isTrue, reason: t.id);
      expect(egitimCategories.any((c) => c.id == t.category), isTrue, reason: t.id);
    }
    for (final id in egitimFeatured) {
      expect(egitimTools.any((t) => t.id == id), isTrue, reason: id);
    }
    expect(egitimHubTitle.length, 33);
    expect(egitimHubTagline.length, 33);
    expect(egitimTool('uyg-ilk-yardim-rehberi').disclaimer, AppDisclaimer.wellness);
  });

  test('namaz vakitleri: İstanbul için sıralı ve makul', () {
    final m = methodById('diyanet');
    final d = prayerTimes(DateTime(2026, 6, 21), 41.01, 28.98, 3, m);
    for (final t in d.times) {
      expect(t, isNotNull);
    }
    for (var i = 1; i < 6; i++) {
      expect(d.times[i]!.isAfter(d.times[i - 1]!), isTrue, reason: '$i');
    }
    // Yaz gündönümünde öğle ~13:10, akşam ~20:40 civarı.
    expect(d.dhuhr!.hour, 13);
    expect(d.maghrib!.hour, anyOf(20, 21));
    final w = prayerTimes(DateTime(2026, 12, 21), 41.01, 28.98, 3, m);
    // Türkiye yıl boyu UTC+3: kış gündönümünde öğle ~13:07, akşam ~17:46.
    expect(w.dhuhr!.hour, 13);
    expect(w.maghrib!.hour, 17);
  });

  test('Diyanet takvimiyle karşılaştırma: Fatih 28.11.2026 (±1 dk)', () {
    // Diyanet'in yayımladığı Fatih vakitleri: 06:29 07:59 12:57 15:23 17:45 19:10.
    final d = prayerTimes(DateTime(2026, 11, 28), 41.0082, 28.9784, 3, methodById('diyanet'));
    const ref = [(6, 29), (7, 59), (12, 57), (15, 23), (17, 45), (19, 10)];
    for (var i = 0; i < 6; i++) {
      final got = d.times[i]!.hour * 60 + d.times[i]!.minute;
      expect((got - (ref[i].$1 * 60 + ref[i].$2)).abs(), lessThanOrEqualTo(1), reason: '$i');
    }
  });

  test('WMM2025 manyetik sapma (NOAA modeliyle aynı katsayılar)', () {
    final when = DateTime(2026, 11, 28);
    // Beklenen değerler WMM2025'in bağımsız Python uygulamasından (±0,05°).
    expect(magneticDeclination(41.01, 28.98, when), closeTo(6.08, 0.05)); // İstanbul, doğu
    expect(magneticDeclination(40.71, -74.0, when), closeTo(-12.46, 0.05)); // New York, batı
    expect(magneticDeclination(-33.87, 151.2, when), closeTo(12.83, 0.05)); // Sidney
    expect(magneticDeclination(21.42, 39.83, when), closeTo(3.5, 0.05)); // Mekke
  });

  test('vakit bildirimleri: 7 gün, geçmiş atlanır, yerin UTC farkıyla mutlak an', () {
    final m = methodById('diyanet');
    PrayerDay dayOf(DateTime d) => prayerTimes(d, 41.0082, 28.9784, 3, m);
    final now = DateTime.utc(2026, 11, 28, 13, 0); // İstanbul 16:00
    final on = [false, false, true, false, true, false]; // öğle ve akşam
    final all = prayerAlertTimes(dayOf, (_) => 3.0, now, on, 0);
    // Bugünün öğlesi geçti: bugün yalnız akşam, sonraki 6 günde ikişer.
    expect(all.length, 13);
    expect(all.first.$1, (0, 4));
    final first = all.first.$3;
    expect(all.first.$2, DateTime.utc(first.year, first.month, first.day, first.hour - 3, first.minute));
    final early = prayerAlertTimes(dayOf, (_) => 3.0, now, on, 10);
    expect(early.first.$2, all.first.$2.subtract(const Duration(minutes: 10)));
    expect(prayerAlertTimes(dayOf, (_) => 3.0, now, List.filled(6, false), 0), isEmpty);
  });

  test('yüksek enlemde vakitler yine oluşur', () {
    final d = prayerTimes(DateTime(2026, 6, 21), 59.33, 18.07, 2, methodById('mwl'));
    expect(d.fajr, isNotNull);
    expect(d.isha, isNotNull);
  });

  test('kıble yönü ve mesafe', () {
    expect(qiblaBearing(41.01, 28.98), closeTo(151.6, 1.5));
    expect(greatCircleKm(41.01, 28.98, kaabaLat, kaabaLng), closeTo(2400, 80));
  });

  test('Hicri takvim gidiş-dönüş ve ay uzunluğu', () {
    for (final g in [DateTime(2024, 3, 11), DateTime(2026, 2, 18), DateTime(2027, 1, 1)]) {
      final (y, m, d) = toHijri(g);
      expect(fromHijri(y, m, d), DateTime(g.year, g.month, g.day));
    }
    for (var m = 1; m <= 12; m++) {
      expect(hijriMonthLength(1448, m), inInclusiveRange(29, 30));
    }
    final r = ramadanDays(DateTime(2026, 11, 25));
    expect(r.length, inInclusiveRange(29, 30));
    expect(r.first.year, 2027);
    final up = upcomingHolyDays(DateTime(2026, 11, 25));
    expect(up.length, 11);
    for (var i = 1; i < up.length; i++) {
      expect(up[i].$2.isBefore(up[i - 1].$2), isFalse);
    }
  });

  test('Ay evresi: bilinen dolunay ve yeni ay', () {
    // 2026-01-03 dolunay, 2026-01-18 yeni ay (yaklaşık).
    expect(moonPhase(DateTime.utc(2026, 1, 3, 10)).illumination, greaterThan(0.97));
    expect(moonPhase(DateTime.utc(2026, 1, 18, 19)).illumination, lessThan(0.03));
    final n = nextLunation(DateTime.utc(2026, 1, 1), 180);
    expect(n.difference(DateTime.utc(2026, 1, 3, 10)).inHours.abs(), lessThan(18));
  });

  test('yaz saati kuralları', () {
    expect(dstActive('E', DateTime.utc(2026, 7, 1), 1), isTrue);
    expect(dstActive('E', DateTime.utc(2026, 12, 1), 1), isFalse);
    expect(dstActive('U', DateTime.utc(2026, 7, 1), -5), isTrue);
    expect(dstActive('A', DateTime.utc(2026, 1, 15), 10), isTrue);
    expect(dstActive('A', DateTime.utc(2026, 7, 15), 10), isFalse);
    expect(dstActive('N', DateTime.utc(2026, 7, 1), 3), isFalse);
    expect(cityByName('İstanbul').offsetAt(DateTime.utc(2026, 7, 1)), 3);
  });

  test('SM-2 aralıklı tekrar', () {
    final t = DateTime(2026, 11, 25);
    var s = CardState(due: t);
    s = sm2(s, 5, t);
    expect(s.interval, 1);
    s = sm2(s, 5, t);
    expect(s.interval, 6);
    s = sm2(s, 4, t);
    expect(s.interval, greaterThan(6));
    final fail = sm2(s, 1, t);
    expect(fail.reps, 0);
    expect(fail.due, t);
    expect(fail.ef, greaterThanOrEqualTo(1.3));
  });

  test('matematik soruları doğru cevaplı, bölme tam', () {
    final r = math.Random(7);
    for (var i = 0; i < 300; i++) {
      final q = makeMathQ(r, '?', 1 + i % 3);
      switch (q.op) {
        case '+':
          expect(q.answer, q.a + q.b);
        case '−':
          expect(q.answer, q.a - q.b);
          expect(q.answer, greaterThanOrEqualTo(0));
        case '×':
          expect(q.answer, q.a * q.b);
        default:
          expect(q.a % q.b, 0);
          expect(q.answer, q.a ~/ q.b);
      }
    }
  });

  test('yazma istatistiği ve hızlı okuma parçaları', () {
    final s = typingStats('merhaba dunya', 'merhaba dunye', const Duration(minutes: 1));
    expect(s.correct, 12);
    expect(s.errors, 1);
    expect(s.wpm, closeTo(2.4, 0.01));
    expect(chunkWords('bir iki üç dört beş', 2), ['bir iki', 'üç dört', 'beş']);
    expect(chunkMs('son.', 300, 1), greaterThan(chunkMs('orta', 300, 1)));
  });

  test('robot bulmacası: çözülebilir ve duvar algılanır', () {
    expect(runRobot(kRobotLevels[0], ['F', 'F', 'F', 'F'], const []).success, isTrue);
    expect(runRobot(kRobotLevels[1], ['F', 'F', 'F'], const []).error, 'wall');
    expect(runRobot(kRobotLevels[3], ['P', 'P'], ['F', 'F', 'F', 'F', 'F']).success, isTrue);
    expect(runRobot(kRobotLevels[0], ['P'], ['P']).error, 'limit');
  });

  test('deneme neti: YKS 4:1, LGS 3:1', () {
    expect(netScore(30, 8, 4), 28);
    expect(netScore(15, 3, 3), 14);
  });

  test('periyodik tablo: 118 element, konumlar benzersiz', () {
    expect(kElements.length, 118);
    expect(kElements.first.symbol, 'H');
    expect(kElements.last.z, 118);
    final seen = <(int, int)>{};
    for (final e in kElements) {
      final c = elementCell(e.z);
      expect(seen.add(c), isTrue, reason: '${e.symbol} $c');
      expect(c.$1, inInclusiveRange(1, 18));
    }
    expect(elementCell(26), (8, 4));
    expect(elementCell(79), (11, 6));
    expect(elementCategory(10), 'noble');
  });

  test('formüller hesaplanır', () {
    expect(kFormulas.length, greaterThan(20));
    for (final f in kFormulas) {
      final v = f.calc([for (var i = 0; i < f.vars.length; i++) 2.0 + i * 1.5]);
      expect(v.isFinite, isTrue, reason: f.title[0]);
    }
  });

  test('sözlük araması ve kelime listesi', () {
    expect(kWords.length, greaterThan(400));
    final hits = searchWords(kWords, 'kapı');
    expect(hits.first.$2, contains('door'));
    expect(searchWords(kWords, 'door').first.$1, 'kapı');
    expect(searchWords(kWords, '  '), isEmpty);
  });

  test('bilim ve rehber içerikleri 33 dilde', () {
    for (final e in kElements) {
      expect(e.name.length, 33, reason: e.symbol);
      expect(e.name.every((n) => n.trim().isNotEmpty), isTrue, reason: e.symbol);
    }
    expect(kElements[25].name[0], 'Demir');
    expect(kElements[25].name[2], 'Eisen');
    for (final f in kFormulas) {
      expect(f.title.length, 33, reason: f.title[1]);
      for (final v in f.vars) {
        expect(v.name.length, 33, reason: '${f.title[1]} ${v.sym}');
      }
      expect(f.result.name.length, 33, reason: f.title[1]);
    }
    for (final g in kFirstAid) {
      expect(g.title.length, 33, reason: g.title[1]);
      for (final s in g.steps) {
        expect(s.length, 33, reason: s[1]);
      }
    }
    for (final k in kKnots) {
      expect(k.name.length, 33, reason: k.name[1]);
      expect(k.use.length, 33, reason: k.name[1]);
      for (final s in k.steps) {
        expect(s.length, 33, reason: s[1]);
      }
    }
    for (final row in kCareSymbols) {
      for (final c in row) {
        expect(c.meaning.length, 33, reason: c.meaning[1]);
      }
    }
    for (final m in kMolecules) {
      expect(m.name.length, 33, reason: m.formula);
    }
    for (final c in kCrops) {
      expect(c.name.length, 33, reason: c.id);
    }
    for (final c in kCountries) {
      expect(c.name.length, 33, reason: c.name[1]);
    }
    expect(kCountries.firstWhere((c) => c.name[1] == 'Germany').name[2], 'Deutschland');
  });

  test('büyük sözlük ve seviyeli kelime listesi', () {
    expect(parseDictTsv('# yorum\nev, konut\thouse\nbozuk satır\n'), [('ev, konut', 'house')]);
    expect(parseVocabTsv('A1\tev\thouse\nB2\tdeneme\n'), [('A1', 'ev', 'house')]);
    // Varlık yoksa çekirdek listeye düşer.
    final fb = buildVocabDecks(const [], 'Türkçe → English', true);
    expect(fb.decks, ['Türkçe → English']);
    expect(fb.cards.length, kWords.length);
    final dict = parseDictTsv(File('assets/dict/tr_en.tsv').readAsStringSync());
    expect(dict.length, greaterThan(10000));
    expect(searchWords([...kWords, ...dict], 'house').first.$1, contains('ev'));
    final vocab = parseVocabTsv(File('assets/vocab/tr_en_levels.tsv').readAsStringSync());
    expect(vocab.length, greaterThanOrEqualTo(3000));
    expect(vocab.map((v) => v.$1).toSet(), kVocabLevels.toSet());
    final built = buildVocabDecks(vocab, 'Türkçe → English', true);
    expect(built.decks.length, 5);
    expect(built.cards.length, vocab.length);
    expect(built.cards.first['front'], vocab.first.$3);
    expect(File('assets/dict/LICENSE-GPL2.txt').existsSync(), isTrue);
  });

  test('seyahat ifadeleri 33 dilde', () {
    expect(kLangCodes.length, 33);
    for (final p in kPhrases) {
      expect(p.text.length, 33, reason: p.text.first);
      expect(p.text.every((s) => s.trim().isNotEmpty), isTrue, reason: p.text.first);
    }
  });

  test('tarif: malzeme ayrıştırma, toplama, yedek', () {
    final a = Ingredient.parse('200 g un');
    expect(a.qty, 200);
    expect(a.unit, 'g');
    expect(a.name, 'un');
    expect(Ingredient.parse('1/2 kg şeker').qty, 0.5);
    final sum = aggregate([(a, 1.0), (const Ingredient('Un', 100, 'g'), 2.0)]);
    expect(sum.length, 1);
    expect(sum.first.qty, 400);
    final r = Recipe('1', 'Kek', 4, [a], const ['Karıştır'], const ['tatlı']);
    final back = importRecipes(exportRecipes([r]));
    expect(back.single.title, 'Kek');
    expect(back.single.ingredients.single.qty, 200);
    expect(() => importRecipes('{}'), throwsFormatException);
    expect(weekDays(DateTime(2026, 11, 25)).first, '2026-11-23');
    final plan = <String, Object?>{
      '2026-11-16|0': {'dish': 'Menemen', 'ing': ['3 yumurta'], 'eaten': true},
      '2026-11-17|1': {'dish': 'Mercimek', 'ing': <String>[]},
      '2026-11-24|1': {'dish': 'Pilav', 'ing': <String>[]},
    };
    final n = copyWeekPlan(plan, weekDays(DateTime(2026, 11, 16)), weekDays(DateTime(2026, 11, 23)), 4);
    expect(n, 1);
    expect((plan['2026-11-23|0'] as Map)['dish'], 'Menemen');
    expect((plan['2026-11-23|0'] as Map)['eaten'], isNull);
    expect((plan['2026-11-24|1'] as Map)['dish'], 'Pilav');
  });

  test('kayıt motoru: vade, yıldönümü, ilerleme, toplam', () {
    final today = DateTime(2026, 11, 25);
    expect(nextAnniversary(DateTime(2000, 2, 29), DateTime(2027, 1, 1)), DateTime(2027, 2, 28));
    expect(nextAnniversary(DateTime(1990, 11, 25), today), today);
    expect(nextAnniversary(DateTime(1990, 11, 24), today), DateTime(2027, 11, 24));
    final due = nextDue(plantSpec, {plantSpec.dateField!: '2026-11-20', plantSpec.daysField!: 3}, today);
    expect(due, DateTime(2026, 11, 23));
    expect(notifyId('a', 'b'), notifyId('a', 'b'));
    expect(notifyId('a', 'b'), isNot(notifyId('a', 'c')));
    expect(notifyId('x', 'y'), greaterThan(0));
    if (weddingSpec.sumField != null) {
      expect(sumOf(weddingSpec, [
        {weddingSpec.sumField!: 10},
        {weddingSpec.sumField!: 2.5},
      ]), 12.5);
    }
    if (travelChecklistSpec.checkField != null) {
      final p = progressOf(travelChecklistSpec, [
        {travelChecklistSpec.checkField!: true},
        {travelChecklistSpec.checkField!: false},
      ]);
      expect(p, (1, 2));
    }
  });

  test('gider bölüşme: bakiye sıfıra toplanır, hesaplaşma kapatır', () {
    final people = ['A', 'B', 'C'];
    final ex = [
      const Expense('1', 'otel', 300, 'A', ['A', 'B', 'C']),
      const Expense('2', 'yemek', 60, 'B', ['B', 'C']),
    ];
    final b = balances(people, ex);
    expect(b.values.fold<double>(0, (s, v) => s + v), closeTo(0, 1e-9));
    expect(b['A'], closeTo(200, 1e-9));
    final pay = settle(b);
    final after = Map<String, double>.from(b);
    for (final (from, to, x) in pay) {
      after[from] = after[from]! + x;
      after[to] = after[to]! - x;
    }
    for (final v in after.values) {
      expect(v.abs(), lessThan(0.02));
    }
  });

  test('saat dilimi örtüşmesi ve yön', () {
    expect(overlapHours([3, 3]), [9, 10, 11, 12, 13, 14, 15, 16, 17]);
    // 8 saat fark: yalnız ana saatle 17:00 (karşı taraf 09:00) ortak mesai.
    expect(overlapHours([3, -5]), [17]);
    expect(overlapHours([3, -9]), isEmpty);
    expect(bearing(0, 0, 10, 0), closeTo(0, 0.01));
    expect(bearing(0, 0, 0, 10), closeTo(90, 0.01));
  });

  test('eğik atış', () {
    final p = projectile(20, 45, 9.81);
    expect(p.range, closeTo(40.77, 0.1));
    expect(p.maxH, closeTo(10.19, 0.05));
  });

  test('bahçe: sığan bitki ve kötü komşular', () {
    expect(plantsFit(cropById('tomato'), 100, 100), greaterThan(1));
    expect(plantsFit(cropById('tomato'), 0, 100), 0);
    expect(badPairs(['tomato', 'potato', 'basil']), [('tomato', 'potato')]);
    for (final c in kCrops) {
      for (final x in [...c.good, ...c.bad]) {
        expect(kCrops.any((k) => k.id == x), isTrue, reason: '${c.id}→$x');
      }
    }
  });

  test('moleküller: bağlar bulunur', () {
    expect(kMolecules.length, greaterThan(15));
    for (final m in kMolecules) {
      if (m.atoms.length > 1) expect(bondsOf(m), isNotEmpty, reason: m.formula);
    }
  });

  test('içerik: rehberler, ülkeler, yıldızlar, şehirler', () {
    expect(kFirstAid.length, greaterThan(10));
    expect(kKnots.length, greaterThan(10));
    expect(kCareSymbols, isNotEmpty);
    expect(kCountries.length, greaterThan(190));
    expect(kStars.length, greaterThan(50));
    expect(kConstellations, isNotEmpty);
    expect(kCities.length, greaterThan(150));
  });

  test('33 dilde temel kelimeler: dolu, kategorili, test soruları', () {
    expect(kCoreWords.length, greaterThanOrEqualTo(200));
    for (final w in kCoreWords) {
      expect(w.w.length, 33, reason: w.w[1]);
      expect(w.w.every((x) => x.trim().isNotEmpty), isTrue, reason: w.w[1]);
      expect(kVocabCats.containsKey(w.cat), isTrue, reason: w.cat);
    }
    for (final c in kVocabCats.keys) {
      expect(vocabOf(c).length, greaterThanOrEqualTo(4), reason: c);
    }
    final r = math.Random(5);
    for (var i = 0; i < 50; i++) {
      final q = vocabQuestion(12, i % 12, r);
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4);
      expect(q.options.contains(q.answer), isTrue);
    }
    // Türkçe "içinde" doğru küçültülmüş (İ → i).
    expect(kCoreWords.any((w) => w.w[0] == 'içinde'), isTrue);
  });

  test('zaman çizelgesi: sıralı, 33 dil, dönemler, yıl seçenekleri', () {
    expect(kTimeline.length, greaterThanOrEqualTo(110));
    for (var i = 1; i < kTimeline.length; i++) {
      expect(kTimeline[i].year, greaterThanOrEqualTo(kTimeline[i - 1].year));
    }
    for (final e in kTimeline) {
      expect(e.text.length, 33);
      expect(e.kind, inInclusiveRange(0, 5));
      expect(eraOf(e.year), greaterThanOrEqualTo(0));
    }
    expect(kTimeline.first.year, lessThan(0));
    final r = math.Random(2);
    for (final e in kTimeline) {
      final o = yearOptions(e.year, r);
      expect(o.length, 4, reason: '${e.year}');
      expect(o.toSet().length, 4);
      expect(o.contains(e.year), isTrue);
      expect(o.contains(0), isFalse);
    }
  });

  test('ehliyet: özgün sorular, deneme sınavı dağılımı, puan', () {
    expect(kExamQuestions.length, greaterThanOrEqualTo(120));
    for (final q in kExamQuestions) {
      expect(q.options.length, 4, reason: q.q);
      expect(q.options.toSet().length, 4, reason: q.q);
      expect(q.answer, inInclusiveRange(0, 3));
      expect(q.why.isNotEmpty, isTrue);
      expect(q.cat, inInclusiveRange(0, 3));
    }
    for (var c = 0; c < 4; c++) {
      expect(kExamQuestions.where((q) => q.cat == c).length, greaterThanOrEqualTo(kExamMix[c]));
    }
    final exam = buildExam(math.Random(1));
    expect(exam.length, 50);
    expect(exam.toSet().length, 50);
    for (var c = 0; c < 4; c++) {
      expect(exam.where((i) => kExamQuestions[i].cat == c).length, kExamMix[c]);
    }
    expect(examScore(35, 50), 70);
    expect(examScore(35, 50) >= kPassScore, isTrue);
    expect(examScore(34, 50) >= kPassScore, isFalse);
    expect(kEhliyetReviewed, matches(RegExp(r'^\d{4}-\d{2}$')));
  });

  test('Türkçe: ünlü uyumu, hece, ekler, yazım', () {
    expect(syllables('Türkçe'), ['Türk', 'çe']);
    expect(syllables('kitap'), ['ki', 'tap']);
    expect(syllables('saat'), ['sa', 'at']);
    expect(syllables('kardeş'), ['kar', 'deş']);
    expect(syllables('okul'), ['o', 'kul']);
    expect(syllables('tren'), ['tren']);
    expect(bigHarmony('araba'), isTrue);
    expect(bigHarmony('kitap'), isFalse);
    expect(smallHarmony('çocuk'), isTrue);
    expect(smallHarmony('tavuk'), isFalse);
    expect(addSuffix('kitap', Suffix.accusative), 'kitabı');
    expect(addSuffix('kitap', Suffix.locative), 'kitapta');
    expect(addSuffix('kitap', Suffix.ablative), 'kitaptan');
    expect(addSuffix('ağaç', Suffix.dative), 'ağaca');
    expect(addSuffix('renk', Suffix.accusative), 'rengi');
    expect(addSuffix('ekmek', Suffix.accusative), 'ekmeği');
    expect(addSuffix('top', Suffix.accusative), 'topu');
    expect(addSuffix('saat', Suffix.plural), 'saatler');
    expect(addSuffix('saat', Suffix.accusative), 'saati');
    expect(addSuffix('ağız', Suffix.accusative), 'ağzı');
    expect(addSuffix('araba', Suffix.accusative), 'arabayı');
    expect(addSuffix('araba', Suffix.genitive), 'arabanın');
    expect(addSuffix('araba', Suffix.possessive1), 'arabam');
    expect(addSuffix('araba', Suffix.instrumental), 'arabayla');
    expect(addSuffix('göz', Suffix.instrumental), 'gözle');
    expect(addSuffix('ev', Suffix.plural), 'evler');
    expect(addSuffix('İstanbul', Suffix.locative), "İstanbul'da");
    expect(addSuffix('Mehmet', Suffix.accusative), "Mehmet'i");
    expect(addSuffix('okul', Suffix.genitive), 'okulun');
    expect(addSuffix('göl', Suffix.accusative), 'gölü');
    final issues = spellIssues('Herkez geldi ama hiç bir şey yanlız kalmadı.');
    expect(issues.map((i) => i.$2).toList(), ['herkes', 'hiçbir', 'yalnız']);
    expect(spellIssues('Herkes geldi.'), isEmpty);
    final pairs = spellingPairs();
    expect(pairs.length, greaterThan(50));
    expect(pairs.every((p) => p.$1 != p.$2), isTrue);
    expect(kSentencePairs.every((p) => p.$1 != p.$2 && p.$3.isNotEmpty), isTrue);
    expect(kGrammarTopics.length, greaterThanOrEqualTo(15));
  });

  group('4. tur: dil kursu, Arap harfleri, parmak alfabesi', () {
    test('kurs: bütün kelime ve ifadeler, kısa dersler, 33 dil', () {
      final units = buildCourse();
      expect(units.length, kCourseOrder.length);
      final items = [for (final u in units) for (final l in u.lessons) ...l];
      expect(items.length, kCoreWords.length + kPhrases.length);
      expect(items.map((i) => i.id).toSet().length, items.length);
      for (final u in units) {
        for (final l in u.lessons) {
          expect(l.length, inInclusiveRange(1, 8), reason: u.cat);
        }
        final key = unitLabelKey(u.cat);
        expect(key == 'phrase_cats' || key.startsWith('vc_'), isTrue);
      }
      for (final i in items) {
        expect(i.text.length, 33, reason: i.id);
        expect(i.text.every((x) => x.trim().isNotEmpty), isTrue, reason: i.id);
      }
    });

    test('alıştırmalar: 4 farklı seçenek, doğru cevap içinde; ifade kurma', () {
      final r = math.Random(4);
      final items = [for (final u in buildCourse()) for (final l in u.lessons) ...l];
      for (var learn = 0; learn < 33; learn++) {
        final know = learn == 0 ? 1 : 0;
        for (var k = 0; k < 40; k++) {
          final it = items[r.nextInt(items.length)];
          final ex = makeExercise(r, it, items, learn, know);
          if (ex.kind == ExKind.build) {
            expect(it.phrase, isTrue);
            expect(usesSpaces(kLangCodes[learn]), isTrue);
            expect(buildCorrect(tokensOf(it.text[learn]), it, learn), isTrue);
            continue;
          }
          expect(ex.options.length, 4);
          expect(ex.answer, greaterThanOrEqualTo(0));
          expect(ex.options.map((o) => o.text[learn]).toSet().length, 4, reason: '${kLangCodes[learn]} ${it.id}');
          expect(ex.options.map((o) => o.text[know]).toSet().length, 4, reason: '${kLangCodes[learn]} ${it.id}');
        }
      }
      final hello = items.firstWhere((i) => i.phrase && tokensOf(i.text[1]).length >= 2);
      final ex = makeExercise(r, hello, items, 1, 0, kind: ExKind.build);
      expect(ex.kind, ExKind.build);
      expect(ex.tokens.toSet(), tokensOf(hello.text[1]).toSet());
      expect(buildCorrect(tokensOf(hello.text[1]).reversed.toList(), hello, 1), isFalse);
      final q = lessonQueue(r, items.take(6).toList(), items.skip(6).take(10).toList());
      expect(q.length, 6 * 2 + 2);
      for (var i = 1; i < q.length; i++) {
        // Aynı öğe art arda gelmez (küçük kuyrukta kaçınılmazsa yalnızca sonda).
        if (q[i].$1.id == q[i - 1].$1.id) expect(i, q.length - 1);
      }
    });

    test('seri ve aralıklı tekrar kaydı', () {
      final d = DateTime(2026, 3, 10);
      expect(bumpStreak(0, null, d), 1);
      expect(bumpStreak(4, '2026-03-09', d), 5);
      expect(bumpStreak(4, '2026-03-10', d), 4);
      expect(bumpStreak(4, '2026-03-07', d), 1);
      final c = sm2(CardState(due: d), 5, d);
      final back = cardFromJson(cardToJson(c))!;
      expect(back.interval, c.interval);
      expect(back.reps, c.reps);
      expect(back.ef, c.ef);
      expect(back.due, c.due);
      expect(cardFromJson('x'), isNull);
      expect(cardFromJson([1, 2]), isNull);
    });

    test('Arap harfleri: 28 + 4 ek harf, biçimler, hece sorusu', () {
      expect(kArLetters.where((l) => !l.extra).length, 28);
      expect(kArLetters.where((l) => l.extra).length, 4);
      expect(kArLetters.map((l) => l.ch).toSet().length, kArLetters.length);
      expect(kArLetters.where((l) => !l.joinsNext).map((l) => l.ch).toSet(), {'ا', 'د', 'ذ', 'ر', 'ز', 'و'});
      final b = kArLetters.firstWhere((l) => l.ch == 'ب');
      expect(arForm(b, 0), 'ب');
      expect(arForm(b, 1), 'ب‍');
      expect(arForm(b, 2), '‍ب‍');
      expect(arForm(b, 3), '‍ب');
      final r = kArLetters.firstWhere((l) => l.ch == 'ر');
      expect(arForm(r, 1), 'ر');
      expect(arForm(r, 2), '‍ر');
      expect(syllableOf(b, kArMarks[0]), 'ba');
      expect(syllableOf(b, kArMarks[1]), 'bi');
      expect(syllableOf(b, kArMarks[4]), 'bb');
      final rnd = math.Random(1);
      for (var i = 0; i < 200; i++) {
        final q = syllableQuestion(rnd);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options, contains(q.answer));
      }
    });

    test('ASL parmak alfabesi: A–Z, geçerli durumlar, heceleme', () {
      expect(kAslAlphabet.map((h) => h.letter).join(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      for (final h in kAslAlphabet) {
        expect(h.fingers.length, 4, reason: h.letter);
        expect(RegExp(r'^[uschvtx]{4}$').hasMatch(h.fingers), isTrue, reason: h.letter);
        expect(h.orient, inInclusiveRange(0, 2));
      }
      expect(kAslAlphabet.where((h) => h.motion != null).map((h) => h.letter).toList(), ['J', 'Z']);
      // Aynı çizim iki harfe verilmez (J/Z hareketle, P/Q yönle ayrılır).
      final keys = kAslAlphabet.map((h) => '${h.fingers}|${h.thumb}|${h.orient}|${h.motion}').toSet();
      expect(keys.length, 26);
      expect(spellable('Hi, Ali 2!'), ['H', 'I', ' ', 'A', 'L', 'I']);
      expect(spellable('ç'), isEmpty);
      final words = fingerspellWords();
      expect(words.length, greaterThan(40));
      expect(words.every((w) => RegExp(r'^[a-z]{3,7}$').hasMatch(w)), isTrue);
    });

    test('iz sürme puanı', () {
      const w = 60, h = 60;
      final mask = List<bool>.generate(w * h, (i) => (i % w) >= 20 && (i % w) < 40 && (i ~/ w) >= 10 && (i ~/ w) < 50);
      final good = [for (var y = 10; y < 50; y += 2) (30.0, y.toDouble())];
      final s = traceScore(mask, w, h, good, r: 12);
      expect(s.coverage, greaterThan(0.9));
      expect(s.precision, 1.0);
      expect(traceStars(s.coverage, s.precision), 3);
      final bad = [for (var y = 0; y < 60; y += 2) (2.0, y.toDouble())];
      final b = traceScore(mask, w, h, bad, r: 12);
      expect(b.precision, 0);
      expect(traceStars(b.coverage, b.precision), 0);
      expect(traceScore(mask, w, h, const []).coverage, 0);
    });
  });

  // Sensör, konum ya da kamera gerektirmeyen ekranlar test ortamında açılır.
  const skip = {'uyg-kible-pusulasi', 'uyg-gokyuzu-haritasi', 'uyg-park-yeri-bulucu'};
  for (final tool in egitimTools.where((t) => !skip.contains(t.id))) {
    final id = tool.id;
    testWidgets('ekran açılır: $id', (tester) async {
      final s = AppServices(hubId: 'm', backend: MemoryBackend(), ads: NoAdsService(), purchases: NoPurchaseService());
      final ctx = ToolContext(toolId: id, lang: 'tr', store: s.storeFor(id), services: s);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: AppLook(style: egitimHubStyle, child: Scaffold(body: Builder(builder: (c) => egitimTool(id).builder(c, ctx)))),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
