/// Gök hesapları (saf Dart, cihazda): Güneş konumu, namaz vakitleri,
/// kıble yönü, Ay evresi, Hicri takvim ve yıldızların ufuk koordinatları.
///
/// Namaz vakitleri, yaygın kullanılan açık yöntemle (Güneş'in ufkun altındaki
/// açısı + öğle/ikindi gölge oranı) hesaplanır; formüller PrayTimes.org ve
/// `adhan` (MIT) kitaplıklarının belgelediği yaklaşımla aynıdır. Kurumların
/// açı ve temkin değerleri [PrayerMethod] içinde açıkça yazılıdır. Bu dosya
/// dini hüküm vermez; yalnızca seçilen yöntemin sayısal sonucunu üretir.
library;

import 'dart:math' as math;

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;
double _fix(double a, double b) {
  final r = a - b * (a / b).floorToDouble();
  return r < 0 ? r + b : r;
}

double _fixHour(double h) => _fix(h, 24);
double _fixAngle(double a) => _fix(a, 360);

/// Miladi tarihin (öğlen değil, gün başı UT) Jülyen günü.
double julianDay(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5;
}

/// Güneşin sapması (derece) ve zaman denklemi (saat).
({double decl, double eqt}) sunPosition(double jd) {
  final d = jd - 2451545.0;
  final g = _fixAngle(357.529 + 0.98560028 * d);
  final q = _fixAngle(280.459 + 0.98564736 * d);
  final l = _fixAngle(q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2 * g)));
  final e = 23.439 - 0.00000036 * d;
  final ra = _deg(math.atan2(math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l)))) / 15;
  final decl = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));
  final eqt = q / 15 - _fixHour(ra);
  return (decl: decl, eqt: eqt);
}

// ------------------------------------------------------------ namaz

/// Bir hesaplama yöntemi. Açılar derece; `ishaMinutes` doluysa yatsı, akşamdan
/// sonra sabit dakikadır. [adjust]: imsak, güneş, öğle, ikindi, akşam, yatsı
/// için dakika düzeltmesi (temkin).
class PrayerMethod {
  final String id;
  final String name;
  final double fajr;
  final double? isha;
  final int? ishaMinutes;
  final double maghribAngle;
  final List<int> adjust;
  const PrayerMethod(this.id, this.name, this.fajr,
      {this.isha, this.ishaMinutes, this.maghribAngle = 0, this.adjust = const [0, 0, 0, 0, 0, 0]});

  /// Ekranda gösterilen parametre özeti.
  String get summary {
    final i = ishaMinutes != null ? '${ishaMinutes}min' : '${isha!.toStringAsFixed(isha! % 1 == 0 ? 0 : 1)}°';
    final f = fajr.toStringAsFixed(fajr % 1 == 0 ? 0 : 1);
    final adj = adjust.any((a) => a != 0) ? ' · ±${adjust.join('/')}' : '';
    return '$f° / $i$adj';
  }
}

/// Yaygın yöntemler. Değerler kurumların yayımladığı açılardır.
const List<PrayerMethod> prayerMethods = [
  PrayerMethod('diyanet', 'Diyanet (Türkiye)', 18, isha: 17, adjust: [0, -7, 5, 4, 7, 0]),
  PrayerMethod('mwl', 'Muslim World League', 18, isha: 17),
  PrayerMethod('isna', 'ISNA (North America)', 15, isha: 15),
  PrayerMethod('egypt', 'Egyptian General Authority', 19.5, isha: 17.5),
  PrayerMethod('makkah', 'Umm al-Qura (Makkah)', 18.5, ishaMinutes: 90),
  PrayerMethod('karachi', 'Univ. of Islamic Sciences, Karachi', 18, isha: 18),
  PrayerMethod('tehran', 'Inst. of Geophysics, Tehran', 17.7, isha: 14, maghribAngle: 4.5),
  PrayerMethod('kuwait', 'Kuwait', 18, isha: 17.5),
  PrayerMethod('qatar', 'Qatar', 18, ishaMinutes: 90),
  PrayerMethod('singapore', 'MUIS (Singapore)', 20, isha: 18),
  PrayerMethod('france', 'UOIF (France)', 12, isha: 12),
];

PrayerMethod methodById(String id) => prayerMethods.firstWhere((m) => m.id == id, orElse: () => prayerMethods.first);

/// Bir günün vakitleri (yerel saat, `null`: o gün oluşmuyor).
class PrayerDay {
  final DateTime date;

  /// imsak, güneş, öğle, ikindi, akşam, yatsı
  final List<DateTime?> times;
  const PrayerDay(this.date, this.times);
  DateTime? get fajr => times[0];
  DateTime? get sunrise => times[1];
  DateTime? get dhuhr => times[2];
  DateTime? get asr => times[3];
  DateTime? get maghrib => times[4];
  DateTime? get isha => times[5];
}

/// Namaz vakitlerini hesaplar. [tz]: o tarihteki UTC farkı (saat).
/// [hanafi]: ikindi için gölge oranı 2 (aksi 1).
PrayerDay prayerTimes(DateTime date, double lat, double lng, double tz, PrayerMethod m, {bool hanafi = false}) {
  final jd = julianDay(date.year, date.month, date.day) - lng / (15 * 24);

  double midDay(double t) => _fixHour(12 - sunPosition(jd + t).eqt);

  double? angleTime(double angle, double t, {bool ccw = false}) {
    final decl = sunPosition(jd + t).decl;
    final noon = midDay(t);
    final c = (-math.sin(_rad(angle)) - math.sin(_rad(decl)) * math.sin(_rad(lat))) /
        (math.cos(_rad(decl)) * math.cos(_rad(lat)));
    if (c < -1 || c > 1) return null;
    final v = _deg(math.acos(c)) / 15;
    return noon + (ccw ? -v : v);
  }

  double? asrTime(double factor, double t) {
    final decl = sunPosition(jd + t).decl;
    final angle = -_deg(math.atan(1 / (factor + math.tan(_rad((lat - decl).abs())))));
    return angleTime(angle, t);
  }

  // İki yinelemeli kestirim (PrayTimes ile aynı).
  var est = <double?>[5, 6, 12, 13, 18, 18, 18];
  for (var it = 0; it < 2; it++) {
    final p = est.map((h) => (h ?? 12) / 24).toList();
    est = [
      angleTime(m.fajr, p[0], ccw: true),
      angleTime(0.833, p[1], ccw: true),
      midDay(p[2]),
      asrTime(hanafi ? 2 : 1, p[3]),
      angleTime(0.833, p[4]),
      m.maghribAngle > 0 ? angleTime(m.maghribAngle, p[5]) : angleTime(0.833, p[5]),
      m.isha != null ? angleTime(m.isha!, p[6]) : null,
    ];
  }
  final sunrise = est[1], sunset = est[4];
  double? fajr = est[0], isha = est[6];
  var maghrib = est[5];
  if (m.ishaMinutes != null && sunset != null) isha = sunset + m.ishaMinutes! / 60;

  // Yüksek enlem: açıya dayalı gece payı (vakit oluşmazsa ya da aşırı uzarsa).
  if (sunrise != null && sunset != null) {
    final night = 24 - (sunset - sunrise);
    final fp = m.fajr / 60 * night;
    if (fajr == null || (sunrise - fajr) > fp) fajr = sunrise - fp;
    if (m.isha != null) {
      final ip = m.isha! / 60 * night;
      if (isha == null || (isha - sunset) > ip) isha = sunset + ip;
    }
  }
  maghrib ??= sunset;

  final raw = <double?>[fajr, sunrise, est[2], est[3], maghrib, isha];
  final out = <DateTime?>[];
  final base = DateTime.utc(date.year, date.month, date.day);
  for (var i = 0; i < 6; i++) {
    final h = raw[i];
    if (h == null || h.isNaN) {
      out.add(null);
      continue;
    }
    final local = h + tz - lng / 15 + m.adjust[i] / 60;
    final minutes = (local * 60).round();
    final u = base.add(Duration(minutes: minutes));
    out.add(DateTime(u.year, u.month, u.day, u.hour, u.minute));
  }
  return PrayerDay(DateTime(date.year, date.month, date.day), out);
}

// ------------------------------------------------------------ kıble

const double kaabaLat = 21.422487, kaabaLng = 39.826206;

/// Kuzeyden saat yönünde kıble açısı (büyük daire).
double qiblaBearing(double lat, double lng) {
  final p1 = _rad(lat), p2 = _rad(kaabaLat), dl = _rad(kaabaLng - lng);
  final y = math.sin(dl);
  final x = math.cos(p1) * math.tan(p2) - math.sin(p1) * math.cos(dl);
  return _fixAngle(_deg(math.atan2(y, x)));
}

/// İki nokta arası büyük daire uzaklığı (km).
double greatCircleKm(double lat1, double lng1, double lat2, double lng2) {
  final p1 = _rad(lat1), p2 = _rad(lat2);
  final dp = _rad(lat2 - lat1), dl = _rad(lng2 - lng1);
  final a = math.sin(dp / 2) * math.sin(dp / 2) + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return 6371.0088 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

// ------------------------------------------------------------ Ay

const double synodicMonth = 29.530588853;

/// Jülyen gün (UT) olarak bir an.
double jdOf(DateTime t) {
  final u = t.toUtc();
  return julianDay(u.year, u.month, u.day) + (u.hour + u.minute / 60 + u.second / 3600) / 24;
}

/// Ay ile Güneş'in ekliptik boylam farkı (derece, 0–360): ana terimlerle
/// yaklaşık (birkaç saat duyarlılık).
double moonElongation(DateTime t) {
  final d = jdOf(t) - 2451545.0;
  final lMoon = 218.316 + 13.176396 * d;
  final mMoon = _rad(134.963 + 13.064993 * d);
  final dMoon = _rad(297.850 + 12.190749 * d);
  final mSun = _rad(357.529 + 0.98560028 * d);
  final moon = lMoon + 6.289 * math.sin(mMoon) + 1.274 * math.sin(2 * dMoon - mMoon) + 0.658 * math.sin(2 * dMoon) -
      0.186 * math.sin(mSun);
  final q = 280.459 + 0.98564736 * d;
  final sun = q + 1.915 * math.sin(mSun) + 0.020 * math.sin(2 * mSun);
  return _fixAngle(moon - sun);
}

/// Ay yaşı (gün, yaklaşık), aydınlanma oranı (0–1) ve evre sırası (0 yeni ay … 7).
({double age, double illumination, int phase}) moonPhase(DateTime t) {
  final e = moonElongation(t);
  final age = e / 360 * synodicMonth;
  final illum = (1 - math.cos(_rad(e))) / 2;
  final phase = ((e / 360) * 8 + 0.5).floor() % 8;
  return (age: age, illumination: illum, phase: phase);
}

/// [from]'dan sonraki ilk yeni ay (hedef 0°) ya da dolunay (180°).
DateTime nextLunation(DateTime from, double targetDeg) {
  double gap(DateTime t) => _fix(targetDeg - moonElongation(t), 360);
  var t = from.add(Duration(minutes: (gap(from) / 12.19 * 1440).round()));
  // Newton benzeri düzeltme: Ay, Güneş'e göre günde ~12,19° ilerler.
  for (var i = 0; i < 6; i++) {
    var g = gap(t);
    if (g > 180) g -= 360;
    t = t.add(Duration(minutes: (g / 12.19 * 1440).round()));
  }
  if (!t.isAfter(from)) t = nextLunation(from.add(const Duration(days: 2)), targetDeg);
  return t;
}

// ------------------------------------------------------------ Hicri

int gregorianToJdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
}

DateTime jdnToGregorian(int j) {
  final a = j + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - 146097 * b ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - 1461 * d ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  return DateTime(100 * b + d - 4800 + m ~/ 10, m + 3 - 12 * (m ~/ 10), e - (153 * m + 2) ~/ 5 + 1);
}

// Tablo usulü (aritmetik, "Kuwaiti") Hicri takvim; arac-motoru ile aynı.
const int _islamicEpoch = 1948440;
int hijriToJdn(int y, int m, int d) =>
    d + (29.5 * (m - 1)).ceil() + (y - 1) * 354 + ((3 + 11 * y) / 30).floor() + _islamicEpoch - 1;

/// Miladi → Hicri (yıl, ay, gün). [adjust]: elle gün düzeltmesi (±2).
(int, int, int) toHijri(DateTime g, {int adjust = 0}) {
  final j = gregorianToJdn(g.year, g.month, g.day) + adjust;
  final y = ((30 * (j - _islamicEpoch) + 10646) / 10631).floor();
  final m = math.min<int>(12, ((j - (29 + hijriToJdn(y, 1, 1))) / 29.5).ceil() + 1);
  final d = j - hijriToJdn(y, m, 1) + 1;
  return (y, m, d);
}

/// Hicri → Miladi.
DateTime fromHijri(int y, int m, int d, {int adjust = 0}) => jdnToGregorian(hijriToJdn(y, m, d) - adjust);

/// Hicri ay uzunluğu (tablo usulü).
int hijriMonthLength(int y, int m) => m == 12 ? hijriToJdn(y + 1, 1, 1) - hijriToJdn(y, 12, 1) : hijriToJdn(y, m + 1, 1) - hijriToJdn(y, m, 1);

// ------------------------------------------------------------ yıldız

/// Yıldızın ufuk yüksekliği ve azimutu (derece). [raH]: sağ açıklık (saat).
({double alt, double az}) horizontal(double raH, double decDeg, double lat, double lng, DateTime t) {
  final jd = jdOf(t);
  final gmst = _fixAngle(280.46061837 + 360.98564736629 * (jd - 2451545.0));
  final lst = _fixAngle(gmst + lng);
  final h = _rad(_fixAngle(lst - raH * 15));
  final dec = _rad(decDeg), phi = _rad(lat);
  final alt = math.asin(math.sin(dec) * math.sin(phi) + math.cos(dec) * math.cos(phi) * math.cos(h));
  final az = math.atan2(math.sin(h), math.cos(h) * math.sin(phi) - math.tan(dec) * math.cos(phi));
  return (alt: _deg(alt), az: _fixAngle(_deg(az) + 180));
}

/// Güneşin anlık konumu (sağ açıklık saat, sapma derece).
({double ra, double dec}) sunRaDec(DateTime t) {
  final d = jdOf(t) - 2451545.0;
  final g = _fixAngle(357.529 + 0.98560028 * d);
  final q = _fixAngle(280.459 + 0.98564736 * d);
  final l = _fixAngle(q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2 * g)));
  final e = 23.439 - 0.00000036 * d;
  final ra = _fixHour(_deg(math.atan2(math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l)))) / 15);
  final dec = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));
  return (ra: ra, dec: dec);
}
