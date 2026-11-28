/// Dünya Manyetik Modeli (WMM2025, NOAA/BGS; kamu malı) ile manyetik sapma.
/// Telefon pusulası manyetik kuzeyi gösterir; kıble ise coğrafi kuzeye göre
/// hesaplanır. Aradaki fark (Türkiye'de ~6°, ABD'de ±15°'ye kadar) burada
/// hesaplanıp pusulaya eklenir. Geçerlilik: 2025–2030.
library;

import 'dart:math' as math;

const double _epoch = 2025.0;

// Katsayılar: indeks n(n+1)/2 + m (n = 0…12). nT ve nT/yıl.
const List<double> _g = [
  0, -29351.8, -1410.8, -2556.6, 2951.1, 1649.3, 1361, -2404.1, 1243.8, 453.6, 895, 799.5, 55.7, -281.1, 12.1,
  -233.2, 368.9, 187.2, -138.7, -142, 20.9, 64.4, 63.8, 76.9, -115.7, -40.9, 14.9, -60.7, 79.5, -77, -8.8,
  59.3, 15.8, 2.5, -11.1, 14.2, 23.2, 10.8, -17.5, 2, -21.7, 16.9, 15, -16.8, 0.9, 4.6, 7.8, 3, -0.2, -2.5,
  -13.1, 2.4, 8.6, -8.7, -12.9, -1.3, -6.4, 0.2, 2, -1, -0.6, -0.9, 1.5, 0.9, -2.7, -3.9, 2.9, -1.5, -2.5, 2.4,
  -0.6, -0.1, -0.6, -0.1, 1.1, -1, -0.2, 2.6, -2, -0.2, 0.3, 1.2, -1.3, 0.6, 0.6, 0.5, -0.1, -0.4, -0.2, -1.3,
  -0.7,
];
const List<double> _h = [
  0, 0, 4545.4, 0, -3133.6, -815.1, 0, -56.6, 237.5, -549.5, 0, 278.6, -133.9, 212, -375.6, 0, 45.4, 220.2,
  -122.9, 43, 106.1, 0, -18.4, 16.8, 48.8, -59.8, 10.9, 72.7, 0, -48.9, -14.4, -1, 23.4, -7.4, -25.1, -2.3, 0,
  7.1, -12.6, 11.4, -9.7, 12.7, 0.7, -5.2, 3.9, 0, -24.8, 12.2, 8.3, -3.3, -5.2, 7.2, -0.6, 0.8, 10, 0, 3.3, 0,
  2.4, 5.3, -9.1, 0.4, -4.2, -3.8, 0.9, -9.1, 0, 0, 2.9, -0.6, 0.2, 0.5, -0.3, -1.2, -1.7, -2.9, -1.8, -2.3, 0,
  -1.3, 0.7, 1, -1.4, 0, 0.6, -0.1, 0.8, 0.1, -1, 0.1, 0.2,
];
const List<double> _gd = [
  0, 12, 9.7, -11.6, -5.2, -8, -1.3, -4.2, 0.4, -15.6, -1.6, -2.4, -6, 5.6, -7, 0.6, 1.4, 0, 0.6, 2.2, 0.9,
  -0.2, -0.4, 0.9, 1.2, -0.9, 0.3, 0.9, 0, -0.1, -0.1, 0.5, -0.1, -0.8, -0.8, 0.8, -0.1, 0.2, 0, 0.5, -0.1,
  0.3, 0.2, 0, 0.2, 0, -0.1, 0.1, 0.3, -0.3, 0, 0.3, -0.1, 0.1, -0.1, 0.1, 0, 0.1, 0.1, 0, -0.3, 0, -0.1, -0.1,
  0, 0, 0, 0, 0, 0, 0, -0.1, 0, 0, -0.1, -0.1, -0.1, -0.1, 0, 0, 0, 0, 0, 0, 0.1, 0, 0, 0, -0.1, 0, -0.1,
];
const List<double> _hd = [
  0, 0, -21.5, 0, -27.7, -12.1, 0, 4, -0.3, -4.1, 0, -1.1, 4.1, 1.6, -4.4, 0, -0.5, 2.2, 0.4, 1.7, 1.9, 0, 0.3,
  -1.6, -0.4, 0.9, 0.7, 0.9, 0, 0.6, 0.5, -0.8, 0, -1, 0.6, -0.2, 0, -0.2, 0.5, -0.4, 0.4, -0.5, -0.6, 0.3,
  0.2, 0, -0.3, 0.3, -0.3, 0.3, 0.2, -0.1, -0.2, 0.4, 0.1, 0, 0, 0, -0.2, 0.1, -0.1, 0.1, 0, -0.1, 0.2, 0, 0,
  0, 0.1, 0, 0.1, 0, 0, 0.1, 0, 0, 0, 0, 0, 0, 0, -0.1, 0.1, 0, 0, 0, 0, 0, 0, 0, -0.1,
];

/// [lat], [lng] (derece, WGS84) ve [when] anında manyetik sapma (derece;
/// doğu +, batı −). Coğrafi yön = manyetik yön + sapma.
double magneticDeclination(double lat, double lng, DateTime when, {double heightM = 0}) {
  const n = 12, a = 6371200.0, bigA = 6378137.0, f = 1 / 298.257223563;
  const e2 = f * (2 - f);
  final year = when.year + (when.difference(DateTime(when.year)).inHours / 24) / 365.25;
  final dt = (year - _epoch).clamp(-1.0, 6.0).toDouble();
  final phi = lat.clamp(-89.999, 89.999).toDouble() * math.pi / 180, lam = lng * math.pi / 180;
  final sp = math.sin(phi);
  final rc = bigA / math.sqrt(1 - e2 * sp * sp);
  final p = (rc + heightM) * math.cos(phi), z = (rc * (1 - e2) + heightM) * sp;
  final r = math.sqrt(p * p + z * z);
  final phic = math.asin(z / r);
  final th = math.pi / 2 - phic, ct = math.cos(th), st = math.sin(th);
  final pp = List.generate(n + 1, (_) => List<double>.filled(n + 1, 0));
  final dp = List.generate(n + 1, (_) => List<double>.filled(n + 1, 0));
  final s = List.generate(n + 1, (_) => List<double>.filled(n + 1, 0));
  pp[0][0] = 1;
  s[0][0] = 1;
  for (var k = 1; k <= n; k++) {
    s[k][0] = s[k - 1][0] * (2 * k - 1) / k;
    for (var m = 1; m <= k; m++) {
      s[k][m] = s[k][m - 1] * math.sqrt((k - m + 1) * (m == 1 ? 2 : 1) / (k + m));
    }
    for (var m = 0; m <= k; m++) {
      if (k == m) {
        pp[k][m] = st * pp[k - 1][m - 1];
        dp[k][m] = st * dp[k - 1][m - 1] + ct * pp[k - 1][m - 1];
      } else if (k == 1 || m == k - 1) {
        pp[k][m] = ct * pp[k - 1][m];
        dp[k][m] = ct * dp[k - 1][m] - st * pp[k - 1][m];
      } else {
        final kk = ((k - 1) * (k - 1) - m * m) / ((2 * k - 1) * (2 * k - 3));
        pp[k][m] = ct * pp[k - 1][m] - kk * pp[k - 2][m];
        dp[k][m] = ct * dp[k - 1][m] - st * pp[k - 1][m] - kk * dp[k - 2][m];
      }
    }
  }
  var br = 0.0, bt = 0.0, bp = 0.0;
  for (var k = 1; k <= n; k++) {
    final ar = math.pow(a / r, k + 2).toDouble();
    for (var m = 0; m <= k; m++) {
      final i = k * (k + 1) ~/ 2 + m;
      final g = (_g[i] + dt * _gd[i]) * s[k][m], h = (_h[i] + dt * _hd[i]) * s[k][m];
      final cm = math.cos(m * lam), sm = math.sin(m * lam);
      br += (k + 1) * ar * (g * cm + h * sm) * pp[k][m];
      bt -= ar * (g * cm + h * sm) * dp[k][m];
      bp += ar * m * (g * sm - h * cm) * pp[k][m];
    }
  }
  bp /= st.abs() < 1e-10 ? 1e-10 : st;
  final psi = phic - phi;
  final x = -bt * math.cos(psi) + br * math.sin(psi);
  return math.atan2(bp, x) * 180 / math.pi;
}
