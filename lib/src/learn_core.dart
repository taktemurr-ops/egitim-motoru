/// Öğrenme araçlarının saf (arayüzsüz, test edilebilir) mantığı: aralıklı
/// tekrar (SM-2), matematik soruları, yazma hızı, hızlı okuma parçaları,
/// robot bulmacası yorumlayıcısı, deneme neti ve periyodik tablo konumu.
library;

import 'dart:math' as math;

// ------------------------------------------------------------ SM-2

/// Bir kartın tekrar durumu.
class CardState {
  final double ef;
  final int interval;
  final int reps;
  final DateTime due;
  const CardState({this.ef = 2.5, this.interval = 0, this.reps = 0, required this.due});
}

/// SuperMemo-2 (Wozniak, 1987) — [q]: 0–5 arası öz değerlendirme.
CardState sm2(CardState s, int q, DateTime today) {
  final d = DateTime(today.year, today.month, today.day);
  var ef = s.ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
  if (ef < 1.3) ef = 1.3;
  if (q < 3) return CardState(ef: ef, interval: 0, reps: 0, due: d);
  final reps = s.reps + 1;
  final interval = reps == 1 ? 1 : (reps == 2 ? 6 : (s.interval * ef).round());
  return CardState(ef: ef, interval: interval, reps: reps, due: DateTime(d.year, d.month, d.day + interval));
}

// ------------------------------------------------------------ matematik

class MathQ {
  final int a, b;
  final String op;
  final int answer;
  const MathQ(this.a, this.b, this.op, this.answer);
  String get text => '$a $op $b';
}

/// [op]: + − × ÷ ya da '?' (karışık); [level] 1–3. Bölme her zaman tam bölünür.
MathQ makeMathQ(math.Random r, String op, int level) {
  final ops = ['+', '−', '×', '÷'];
  final o = op == '?' ? ops[r.nextInt(4)] : op;
  final max = [10, 50, 200][level.clamp(1, 3) - 1];
  final mul = [10, 12, 20][level.clamp(1, 3) - 1];
  int n(int hi, [int lo = 0]) => lo + r.nextInt(hi - lo + 1);
  switch (o) {
    case '+':
      final a = n(max), b = n(max);
      return MathQ(a, b, o, a + b);
    case '−':
      final a = n(max), b = n(a);
      return MathQ(a, b, o, a - b);
    case '×':
      final a = n(mul, 1), b = n(mul, 1);
      return MathQ(a, b, o, a * b);
    default:
      final b = n(mul, 1), q = n(mul, 1);
      return MathQ(b * q, b, '÷', q);
  }
}

// ------------------------------------------------------------ yazma

/// Doğru karakter sayısı, hata ve dakikada kelime (5 karakter = 1 kelime).
({int correct, int errors, double wpm, double accuracy}) typingStats(String target, String typed, Duration elapsed) {
  var correct = 0, errors = 0;
  for (var i = 0; i < typed.length; i++) {
    if (i < target.length && typed[i] == target[i]) {
      correct++;
    } else {
      errors++;
    }
  }
  final min = elapsed.inMilliseconds / 60000;
  final wpm = min <= 0 ? 0.0 : (correct / 5) / min;
  final acc = typed.isEmpty ? 1.0 : correct / typed.length;
  return (correct: correct, errors: errors, wpm: wpm, accuracy: acc);
}

// ------------------------------------------------------------ hızlı okuma

/// Metni [size] kelimelik parçalara böler.
List<String> chunkWords(String text, int size) {
  final w = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  final out = <String>[];
  for (var i = 0; i < w.length; i += size) {
    out.add(w.sublist(i, math.min<int>(i + size, w.length)).join(' '));
  }
  return out;
}

/// Bir parçanın ekranda kalma süresi (ms); noktalama sonrası kısa duraklama.
int chunkMs(String chunk, int wpm, int size) {
  final base = 60000 / wpm * size;
  final pause = RegExp(r'[.!?;:。！？]$').hasMatch(chunk) ? 1.6 : (chunk.endsWith(',') ? 1.25 : 1.0);
  return (base * pause).round();
}

// ------------------------------------------------------------ robot

/// Robot bulmacası. Izgara: 'S' başlangıç (doğuya bakar), 'G' hedef,
/// '#' duvar, '.' yol. Komutlar: F ileri, L sola dön, R sağa dön, P alt program.
class RobotLevel {
  final List<String> grid;
  final int mainMax;
  final int procMax;
  const RobotLevel(this.grid, this.mainMax, this.procMax);

  int get w => grid.map((r) => r.length).reduce(math.max);
  int get h => grid.length;
  String at(int x, int y) => y < 0 || y >= h || x < 0 || x >= grid[y].length ? '#' : grid[y][x];

  (int, int) get start {
    for (var y = 0; y < h; y++) {
      final x = grid[y].indexOf('S');
      if (x >= 0) return (x, y);
    }
    return (0, 0);
  }
}

const List<RobotLevel> kRobotLevels = [
  RobotLevel(['S...G'], 6, 0),
  RobotLevel(['S..#', '#.G#'], 6, 0),
  RobotLevel(['S....', '####.', 'G....'], 12, 0),
  RobotLevel(['S.........G'], 4, 6),
  RobotLevel(['S.###', '#..##', '##..#', '###.G'], 5, 5),
  RobotLevel(['S...#', '###.#', 'G...#'], 5, 4),
  RobotLevel(['S.#####', '#.#####', '#....##', '####.##', '####..G'], 8, 6),
  RobotLevel(['S..............G'], 2, 3),
];

/// Çalıştırma sonucu: izlenen yol, hedefe ulaşıldı mı, hata nedeni.
class RobotRun {
  final List<(int, int, int)> path;
  final bool success;
  final String? error;
  const RobotRun(this.path, this.success, this.error);
}

/// Programı çalıştırır. Yönler: 0 doğu, 1 güney, 2 batı, 3 kuzey.
/// Alt program kendini çağırabilir (döngü); 200 adım sınırı vardır.
RobotRun runRobot(RobotLevel lv, List<String> main, List<String> proc) {
  var (x, y) = lv.start;
  var d = 0;
  final path = <(int, int, int)>[(x, y, d)];
  var steps = 0;
  String? error;
  var done = false;

  void exec(List<String> prog, int depth) {
    for (final c in prog) {
      if (done || error != null) return;
      if (++steps > 200) {
        error = 'limit';
        return;
      }
      switch (c) {
        case 'F':
          const dx = [1, 0, -1, 0], dy = [0, 1, 0, -1];
          final nx = x + dx[d], ny = y + dy[d];
          if (lv.at(nx, ny) == '#') {
            error = 'wall';
            return;
          }
          x = nx;
          y = ny;
        case 'L':
          d = (d + 3) % 4;
        case 'R':
          d = (d + 1) % 4;
        case 'P':
          if (depth > 60) {
            error = 'limit';
            return;
          }
          exec(proc, depth + 1);
      }
      path.add((x, y, d));
      if (lv.at(x, y) == 'G') {
        done = true;
        return;
      }
    }
  }

  exec(main, 0);
  return RobotRun(path, done, done ? null : (error ?? 'short'));
}

// ------------------------------------------------------------ deneme neti

/// Net: doğru − yanlış / oran (YKS ve KPSS 4, LGS 3).
double netScore(int correct, int wrong, int ratio) => correct - wrong / ratio;

// ------------------------------------------------------------ periyodik tablo

/// Atom numarasından (grup, periyot); lantanit/aktinitler için grup 0
/// ve tablonun alt satırları (periyot 8 = lantanit, 9 = aktinit).
(int, int) elementCell(int z) {
  const starts = [1, 3, 11, 19, 37, 55, 87, 119];
  var period = 1;
  for (var i = 0; i < 7; i++) {
    if (z >= starts[i] && z < starts[i + 1]) period = i + 1;
  }
  if (z >= 57 && z <= 71) return (z - 57 + 3, 8);
  if (z >= 89 && z <= 103) return (z - 89 + 3, 9);
  final pos = z - starts[period - 1];
  final int group;
  if (period == 1) {
    group = z == 1 ? 1 : 18;
  } else if (period <= 3) {
    group = pos < 2 ? pos + 1 : pos + 11;
  } else if (period <= 5) {
    group = pos + 1;
  } else if (period == 6) {
    group = z <= 56 ? z - 54 : z - 68;
  } else {
    group = z <= 88 ? z - 86 : z - 100;
  }
  return (group, period);
}

/// Element sınıfı (renk ve açıklama için).
String elementCategory(int z) {
  const nonmetal = {1, 6, 7, 8, 15, 16, 34};
  const halogen = {9, 17, 35, 53, 85, 117};
  const noble = {2, 10, 18, 36, 54, 86, 118};
  const metalloid = {5, 14, 32, 33, 51, 52};
  const alkali = {3, 11, 19, 37, 55, 87};
  const alkaline = {4, 12, 20, 38, 56, 88};
  const post = {13, 31, 49, 50, 81, 82, 83, 84, 113, 114, 115, 116};
  if (nonmetal.contains(z)) return 'nonmetal';
  if (halogen.contains(z)) return 'halogen';
  if (noble.contains(z)) return 'noble';
  if (metalloid.contains(z)) return 'metalloid';
  if (alkali.contains(z)) return 'alkali';
  if (alkaline.contains(z)) return 'alkaline';
  if (post.contains(z)) return 'post';
  if (z >= 57 && z <= 71) return 'lanthanide';
  if (z >= 89 && z <= 103) return 'actinide';
  return 'transition';
}
