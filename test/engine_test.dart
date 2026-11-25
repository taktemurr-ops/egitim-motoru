import 'dart:math' as math;

import 'package:egitim_motoru/egitim_motoru.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:studio_core/core/save_store.dart';

void main() {
  test('45 uygulama, 33 dilde ad ve açıklama, geçerli kategori', () {
    expect(egitimTools.length, 45);
    expect(egitimTools.map((t) => t.id).toSet().length, 45);
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
    expect(w.dhuhr!.hour, 12);
    expect(w.maghrib!.hour, 16);
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
    expect(overlapHours([3, -5]), isEmpty);
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
