/// Bilim: fizik simülasyonları, molekül görüntüleyici, dünya atlası,
/// gökyüzü haritası, Ay evreleri ve güneş saatleri.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:studio_core/apps/apps.dart';

import '../astro.dart';
import '../common.dart';
import '../data/countries.dart';
import '../data/molecules.dart';
import '../data/sky.dart';
import '../geo.dart';

// ------------------------------------------------------------ fizik

/// Eğik atış: menzil, en yüksek nokta, uçuş süresi (hava direnci yok).
({double range, double maxH, double time}) projectile(double v, double angleDeg, double g, {double h0 = 0}) {
  final a = angleDeg * math.pi / 180;
  final vx = v * math.cos(a), vy = v * math.sin(a);
  final time = (vy + math.sqrt(vy * vy + 2 * g * h0)) / g;
  return (range: vx * time, maxH: h0 + vy * vy / (2 * g), time: time);
}

class PhysicsTool extends StatefulWidget {
  final ToolContext t;
  const PhysicsTool(this.t, {super.key});

  @override
  State<PhysicsTool> createState() => _PhysicsToolState();
}

class _PhysicsToolState extends State<PhysicsTool> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _sim = 0;
  double _t = 0;
  Duration _last = Duration.zero;
  bool _running = false;

  // eğik atış
  double _v = 20, _angle = 45, _g = 9.81;
  // sarkaç
  double _len = 2, _theta0 = 30, _theta = 30 * math.pi / 180, _omega = 0, _damp = 0;
  // yay
  double _k = 20, _m = 1, _x = 1, _vel = 0;
  final List<Offset> _trail = [];

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _reset() {
    _ticker.stop();
    setState(() {
      _running = false;
      _t = 0;
      _last = Duration.zero;
      _theta = _theta0 * math.pi / 180;
      _omega = 0;
      _x = 1;
      _vel = 0;
      _trail.clear();
    });
  }

  void _toggle() {
    if (_running) {
      _ticker.stop();
      setState(() => _running = false);
    } else {
      _last = Duration.zero;
      _ticker.start();
      setState(() => _running = true);
    }
  }

  void _tick(Duration e) {
    final dt = _last == Duration.zero ? 0.016 : math.min<double>(0.05, (e - _last).inMicroseconds / 1e6);
    _last = e;
    setState(() {
      _t += dt;
      switch (_sim) {
        case 0:
          final p = projectile(_v, _angle, _g);
          if (_t >= p.time) {
            _t = p.time;
            _ticker.stop();
            _running = false;
          }
        case 1:
          // yarı-örtük Euler, küçük adımlar
          for (var i = 0; i < 8; i++) {
            final h = dt / 8;
            _omega += (-_g / _len * math.sin(_theta) - _damp * _omega) * h;
            _theta += _omega * h;
          }
        case 2:
          for (var i = 0; i < 8; i++) {
            final h = dt / 8;
            _vel += (-_k / _m * _x - _damp * _vel) * h;
            _x += _vel * h;
          }
          _trail.add(Offset(_t, _x));
          if (_trail.length > 300) _trail.removeAt(0);
      }
    });
  }

  Widget _slider(String label, double v, double min, double max, String unit, ValueChanged<double> on) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ${formatNumber(v, digits: 2)} $unit', style: const TextStyle(color: Colors.white70)),
      Slider(value: v.clamp(min, max), min: min, max: max, onChanged: (x) {
        on(x);
        _reset();
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final names = Ls(t, 'sims');
    final accent = AppLook.of(context).accent;
    final p = projectile(_v, _angle, _g);
    return ToolList(children: [
      Choice<int>(
        values: const [0, 1, 2],
        labels: names,
        selected: _sim,
        onChanged: (v) {
          _sim = v;
          _reset();
        },
      ),
      AppPanel(
        child: AspectRatio(
          aspectRatio: 1.6,
          child: CustomPaint(
            painter: _PhysicsPainter(
              sim: _sim,
              t: _t,
              v: _v,
              angle: _angle,
              g: _g,
              len: _len,
              theta: _theta,
              x: _x,
              trail: List.of(_trail),
              accent: accent,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: AppButton(label: _running ? L(t, 'pause') : L(t, 'start'), onPressed: _toggle)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.replay_rounded), onPressed: _reset),
        ]),
      ),
      AppPanel(
        child: Column(children: [
          if (_sim == 0) ...[
            _slider(L(t, 'speed'), _v, 1, 50, 'm/s', (x) => _v = x),
            _slider(L(t, 'angle'), _angle, 1, 89, '°', (x) => _angle = x),
            AppResult(label: L(t, 'range'), value: '${p.range.toStringAsFixed(1)} m', lang: t.lang),
            AppResult(label: L(t, 'max_height'), value: '${p.maxH.toStringAsFixed(1)} m', lang: t.lang),
            AppResult(label: L(t, 'flight_time'), value: '${p.time.toStringAsFixed(2)} s', lang: t.lang),
          ],
          if (_sim == 1) ...[
            _slider(L(t, 'length'), _len, 0.2, 10, 'm', (x) => _len = x),
            _slider(L(t, 'angle'), _theta0, 5, 170, '°', (x) => _theta0 = x),
            _slider(L(t, 'damping'), _damp, 0, 1, '', (x) => _damp = x),
            AppResult(
                label: '${L(t, 'period')} (≈ 2π√(L/g))',
                value: '${(2 * math.pi * math.sqrt(_len / _g)).toStringAsFixed(2)} s',
                lang: t.lang),
          ],
          if (_sim == 2) ...[
            _slider(L(t, 'stiffness'), _k, 1, 100, 'N/m', (x) => _k = x),
            _slider(L(t, 'mass'), _m, 0.1, 10, 'kg', (x) => _m = x),
            _slider(L(t, 'damping'), _damp, 0, 2, '', (x) => _damp = x),
            AppResult(label: '${L(t, 'period')} (2π√(m/k))', value: '${(2 * math.pi * math.sqrt(_m / _k)).toStringAsFixed(2)} s', lang: t.lang),
          ],
          _slider(L(t, 'gravity'), _g, 1, 25, 'm/s²', (x) => _g = x),
        ]),
      ),
      AppInfoCard(L(t, 'physics_note')),
    ]);
  }
}

class _PhysicsPainter extends CustomPainter {
  final int sim;
  final double t, v, angle, g, len, theta, x;
  final List<Offset> trail;
  final Color accent;
  _PhysicsPainter({
    required this.sim,
    required this.t,
    required this.v,
    required this.angle,
    required this.g,
    required this.len,
    required this.theta,
    required this.x,
    required this.trail,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final ball = Paint()..color = accent;
    switch (sim) {
      case 0:
        final p = projectile(v, angle, g);
        final scale = math.min<double>((size.width - 20) / math.max<double>(1, p.range), (size.height - 20) / math.max<double>(1, p.maxH));
        Offset at(double tt) {
          final a = angle * math.pi / 180;
          final px = v * math.cos(a) * tt, py = v * math.sin(a) * tt - g * tt * tt / 2;
          return Offset(10 + px * scale, size.height - 10 - py * scale);
        }

        canvas.drawLine(Offset(0, size.height - 10), Offset(size.width, size.height - 10), line);
        final path = Path()..moveTo(at(0).dx, at(0).dy);
        for (var i = 1; i <= 60; i++) {
          final o = at(p.time * i / 60);
          path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path, line);
        canvas.drawCircle(at(t), 8, ball);
      case 1:
        final pivot = Offset(size.width / 2, 12);
        final r = (size.height - 40) * math.min<double>(1, len / 10) + 20;
        final bob = pivot + Offset(math.sin(theta), math.cos(theta)) * r;
        canvas.drawLine(Offset(size.width * 0.3, 12), Offset(size.width * 0.7, 12), line);
        canvas.drawLine(pivot, bob, Paint()
          ..color = Colors.white70
          ..strokeWidth = 2);
        canvas.drawCircle(bob, 14, ball);
      case 2:
        final cx = size.width * 0.25;
        final top = 10.0;
        final y = size.height * 0.5 + x * size.height * 0.2;
        final spring = Path()..moveTo(cx, top);
        const coils = 14;
        for (var i = 1; i <= coils; i++) {
          spring.lineTo(cx + (i.isEven ? -12 : 12), top + (y - top) * i / coils);
        }
        spring.lineTo(cx, y);
        canvas.drawPath(spring, Paint()
          ..color = Colors.white70
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, y + 14), width: 40, height: 28), ball);
        if (trail.length > 1) {
          final t0 = trail.first.dx, t1 = trail.last.dx;
          final w = size.width * 0.6;
          final graph = Path();
          for (var i = 0; i < trail.length; i++) {
            final gx = size.width * 0.38 + (t1 - t0 <= 0 ? 0 : (trail[i].dx - t0) / (t1 - t0) * w);
            final gy = size.height * 0.5 + trail[i].dy * size.height * 0.2;
            if (i == 0) {
              graph.moveTo(gx, gy);
            } else {
              graph.lineTo(gx, gy);
            }
          }
          canvas.drawPath(graph, Paint()
            ..color = accent
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
        }
    }
  }

  @override
  bool shouldRepaint(_PhysicsPainter old) => true;
}

// ------------------------------------------------------------ molekül

class MoleculeTool extends StatefulWidget {
  final ToolContext t;
  const MoleculeTool(this.t, {super.key});

  @override
  State<MoleculeTool> createState() => _MoleculeToolState();
}

class _MoleculeToolState extends State<MoleculeTool> {
  int _sel = 0;
  double _rx = -0.4, _ry = 0.6;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final m = kMolecules[_sel];
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Pick<int>(
          label: L(t, 'molecule'),
          values: List.generate(kMolecules.length, (i) => i),
          text: (i) => '${C(t, kMolecules[i].name)} · ${kMolecules[i].formula}',
          value: _sel,
          onChanged: (v) => setState(() => _sel = v),
        ),
      ),
      AppPanel(
        child: GestureDetector(
          onPanUpdate: (d) => setState(() {
            _ry += d.delta.dx * 0.01;
            _rx += d.delta.dy * 0.01;
          }),
          child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _MolPainter(m, _rx, _ry))),
        ),
      ),
      BigReadout(m.formula, caption: C(t, m.name)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, children: [
          for (final el in {for (final a in m.atoms) a.el})
            Chip(
              avatar: CircleAvatar(backgroundColor: Color(kCpk[el] ?? 0xFFFF69B4), radius: 8),
              label: Text('$el × ${m.atoms.where((a) => a.el == el).length}'),
            ),
        ]),
      ),
      AppInfoCard(L(t, 'drag_rotate'), icon: Icons.threed_rotation_rounded),
      AppInfoCard(L(t, 'molecule_note')),
    ]);
  }
}

class _MolPainter extends CustomPainter {
  final Molecule m;
  final double rx, ry;
  _MolPainter(this.m, this.rx, this.ry);

  @override
  void paint(Canvas canvas, Size size) {
    // döndür ve yansıt
    final pts = <(double, double, double)>[];
    for (final a in m.atoms) {
      final x1 = a.x * math.cos(ry) + a.z * math.sin(ry);
      final z1 = -a.x * math.sin(ry) + a.z * math.cos(ry);
      final y2 = a.y * math.cos(rx) - z1 * math.sin(rx);
      final z2 = a.y * math.sin(rx) + z1 * math.cos(rx);
      pts.add((x1, y2, z2));
    }
    var ext = 1.0;
    for (final p in pts) {
      ext = math.max<double>(ext, math.max<double>(p.$1.abs(), p.$2.abs()));
    }
    final scale = size.width / 2 / (ext + 1.2);
    final c = size.center(Offset.zero);
    Offset proj((double, double, double) p) => c + Offset(p.$1, -p.$2) * scale;
    final bonds = bondsOf(m);
    final order = List.generate(pts.length, (i) => i)..sort((a, b) => pts[a].$3.compareTo(pts[b].$3));
    final bp = Paint()
      ..color = Colors.white54
      ..strokeWidth = math.max<double>(3, scale * 0.12)
      ..strokeCap = StrokeCap.round;
    for (final (i, j) in bonds) {
      canvas.drawLine(proj(pts[i]), proj(pts[j]), bp);
    }
    for (final i in order) {
      final a = m.atoms[i];
      final r = scale * (a.el == 'H' ? 0.28 : 0.42) * (1 + pts[i].$3 * 0.05);
      final o = proj(pts[i]);
      final col = Color(kCpk[a.el] ?? 0xFFFF69B4);
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.lerp(col, Colors.white, 0.5)!, col, Color.lerp(col, Colors.black, 0.4)!])
              .createShader(Rect.fromCircle(center: o - Offset(r * 0.3, r * 0.3), radius: r * 1.3)),
      );
    }
  }

  @override
  bool shouldRepaint(_MolPainter old) => old.m != m || old.rx != rx || old.ry != ry;
}

// ------------------------------------------------------------ atlas

class AtlasTool extends StatefulWidget {
  final ToolContext t;
  const AtlasTool(this.t, {super.key});

  @override
  State<AtlasTool> createState() => _AtlasToolState();
}

class _AtlasToolState extends State<AtlasTool> {
  final _r = math.Random();
  String _q = '';
  String _cont = '';
  int? _sel;
  bool _quiz = false;
  int _qi = 0, _score = 0, _asked = 0;
  List<int> _opts = [];
  int? _picked;

  ToolContext get t => widget.t;

  void _newQ() {
    final pool = [for (var i = 0; i < kCountries.length; i++) if (_cont.isEmpty || kCountries[i].continent == _cont) i];
    pool.shuffle(_r);
    setState(() {
      _qi = pool.first;
      _opts = pool.take(4).toList()..shuffle(_r);
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conts = Ls(t, 'continents');
    const codes = ['AF', 'AS', 'EU', 'NA', 'SA', 'OC'];
    final q = _q.toLowerCase();
    final list = [
      for (var i = 0; i < kCountries.length; i++)
        if ((_cont.isEmpty || kCountries[i].continent == _cont) &&
            (q.isEmpty || C(t, kCountries[i].name).toLowerCase().contains(q) || kCountries[i].capital.toLowerCase().contains(q)))
          i,
    ];
    list.sort((a, b) => C(t, kCountries[a].name).compareTo(C(t, kCountries[b].name)));
    final accent = AppLook.of(context).accent;
    return ToolList(children: [
      Choice<String>(
        values: const ['', ...codes],
        labels: [t.tx('all'), ...conts],
        selected: _cont,
        onChanged: (v) => setState(() => _cont = v),
      ),
      AppPanel(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 2,
          child: CustomPaint(
            painter: _MapPainter(
              [for (final i in list) (kCountries[i].lat, kCountries[i].lng)],
              _quiz ? (kCountries[_qi].lat, kCountries[_qi].lng) : (_sel == null ? null : (kCountries[_sel!].lat, kCountries[_sel!].lng)),
              accent,
            ),
          ),
        ),
      ),
      Choice<bool>(
        values: const [false, true],
        labels: [L(t, 'browse'), L(t, 'quiz')],
        selected: _quiz,
        onChanged: (v) {
          setState(() => _quiz = v);
          if (v) _newQ();
        },
      ),
      if (_quiz) ...[
        AppPanel(
          child: Column(children: [
            Text(Lf(t, 'capital_of', {'c': C(t, kCountries[_qi].name)}),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final o in _opts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _picked == null
                          ? null
                          : (o == _qi ? Colors.green.withValues(alpha: 0.4) : (o == _picked ? Colors.red.withValues(alpha: 0.4) : null)),
                    ),
                    onPressed: _picked != null
                        ? null
                        : () => setState(() {
                              _picked = o;
                              _asked++;
                              if (o == _qi) _score++;
                            }),
                    child: Text(kCountries[o].capital.replaceAll('*', '')),
                  ),
                ),
              ),
            Text('${L(t, 'score')}: $_score / $_asked'),
          ]),
        ),
        if (_picked != null) AppButton(label: L(t, 'next'), icon: Icons.skip_next_rounded, onPressed: _newQ),
      ] else ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: t.tx('search')),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(Lf(t, 'n_countries', {'n': list.length}), style: const TextStyle(color: Colors.white60)),
        ),
        for (final i in list)
          ListTile(
            dense: true,
            selected: _sel == i,
            onTap: () => setState(() => _sel = i),
            title: Text(C(t, kCountries[i].name), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${L(t, 'capital')}: ${kCountries[i].capital} · ${conts[codes.indexOf(kCountries[i].continent)]}'),
          ),
      ],
      AppInfoCard(L(t, 'atlas_note')),
    ]);
  }
}

class _MapPainter extends CustomPainter {
  final List<(double, double)> pts;
  final (double, double)? sel;
  final Color accent;
  _MapPainter(this.pts, this.sel, this.accent);

  Offset _p(Size s, double lat, double lng) => Offset((lng + 180) / 360 * s.width, (90 - lat) / 180 * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (var lng = -180; lng <= 180; lng += 30) {
      final x = (lng + 180) / 360 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var lat = -60; lat <= 60; lat += 30) {
      final y = (90 - lat) / 180 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lat == 0 ? (Paint()..color = Colors.white30) : grid);
    }
    final dot = Paint()..color = Colors.white70;
    for (final p in pts) {
      canvas.drawCircle(_p(size, p.$1, p.$2), 2.2, dot);
    }
    final s = sel;
    if (s != null) {
      final o = _p(size, s.$1, s.$2);
      canvas.drawCircle(o, 7, Paint()..color = accent);
      canvas.drawCircle(o, 12, Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => true;
}

// ------------------------------------------------------------ gökyüzü

class SkyTool extends StatefulWidget {
  final ToolContext t;
  const SkyTool(this.t, {super.key});

  @override
  State<SkyTool> createState() => _SkyToolState();
}

class _SkyToolState extends State<SkyTool> {
  Place? _place;
  DateTime _time = DateTime.now();
  bool _lines = false;
  bool _follow = false;
  final _acc = SensorWatch<AccelerometerEvent>();
  final _mag = SensorWatch<MagnetometerEvent>();
  double _heading = 0;
  String? _tapped;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    loadPlace(t).then((p) {
      if (mounted) setState(() => _place = p);
    });
    t.unlockedToday('sky_lines').then((u) {
      if (mounted && u) setState(() => _lines = true);
    });
  }

  @override
  void dispose() {
    _acc.stop();
    _mag.stop();
    super.dispose();
  }

  void _setFollow(bool v) {
    setState(() => _follow = v);
    if (v) {
      _acc.start(() => accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval), (_) {}, () => setState(() {}));
      _mag.start(() => magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval), (_) => _update(), () => setState(() {}));
    } else {
      _acc.stop();
      _mag.stop();
    }
  }

  void _update() {
    final a = _acc.last, m = _mag.last;
    if (a == null || m == null) return;
    var hx = m.y * a.z - m.z * a.y, hy = m.z * a.x - m.x * a.z, hz = m.x * a.y - m.y * a.x;
    final n = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (n < 0.1) return;
    hx /= n;
    hy /= n;
    hz /= n;
    final na = math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    final my = a.z / na * hx - a.x / na * hz;
    var h = math.atan2(hy, my) * 180 / math.pi;
    if (h < 0) h += 360;
    var d = h - _heading;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    setState(() => _heading = (_heading + d * 0.15 + 360) % 360);
  }

  @override
  Widget build(BuildContext context) {
    final p = _place;
    if (p == null) return const Center(child: CircularProgressIndicator());
    final stars = <(Star, double, double)>[];
    for (final s in kStars) {
      final h = horizontal(s.ra, s.dec, p.lat, p.lng, _time);
      if (h.alt > -2) stars.add((s, h.alt, h.az));
    }
    final sun = sunRaDec(_time);
    final sunH = horizontal(sun.ra, sun.dec, p.lat, p.lng, _time);
    final accent = AppLook.of(context).accent;
    final rot = _follow ? _heading : 0.0;
    return ToolList(children: [
      PlaceRow(
        t: t,
        place: p,
        onChanged: (v) {
          setState(() => _place = v);
          unawaited(savePlace(t, v));
        },
      ),
      AppPanel(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (c, box) {
            return GestureDetector(
              onTapUp: (d) {
                final size = box.biggest;
                String? best;
                var bd = 28.0;
                for (final s in stars) {
                  final o = _SkyPainter.project(size, s.$2, s.$3, rot);
                  final dist = (o - d.localPosition).distance;
                  if (dist < bd) {
                    bd = dist;
                    best = '${s.$1.name} · ${s.$2.toStringAsFixed(0)}° / ${s.$3.toStringAsFixed(0)}°';
                  }
                }
                setState(() => _tapped = best);
              },
              child: CustomPaint(
                painter: _SkyPainter(stars, _lines, rot, Ls(t, 'cardinals'), accent, sunH.alt),
              ),
            );
          }),
        ),
      ),
      if (_tapped != null) AppInfoCard(_tapped!, icon: Icons.star_rounded),
      if (sunH.alt > -6) AppInfoCard(L(t, 'sun_up_note'), icon: Icons.wb_sunny_rounded),
      AppPanel(
        child: Column(children: [
          Text('${fmtDate(context, _time)} ${hhmm(_time)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Slider(
            value: _time.hour + _time.minute / 60,
            min: 0,
            max: 23.9,
            onChanged: (v) => setState(() {
              final d = dayOnly(_time);
              _time = d.add(Duration(minutes: (v * 60).round()));
            }),
          ),
          TextButton(onPressed: () => setState(() => _time = DateTime.now()), child: Text(L(t, 'now'))),
          if (!t.isWeb)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(L(t, 'follow_compass')),
              value: _follow,
              onChanged: _setFollow,
            ),
          if (_follow && (_mag.available == false || _acc.available == false)) notAvailable(t),
        ]),
      ),
      if (!_lines)
        UnlockCard(t: t, feature: 'sky_lines', onUnlocked: () => setState(() => _lines = true))
      else
        AppInfoCard(t.tx('unlocked_today'), icon: Icons.auto_awesome_rounded),
      AppInfoCard(L(t, 'sky_note')),
    ]);
  }
}

class _SkyPainter extends CustomPainter {
  final List<(Star, double, double)> stars;
  final bool lines;
  final double rot;
  final List<String> names;
  final Color accent;
  final double sunAlt;
  _SkyPainter(this.stars, this.lines, this.rot, this.names, this.accent, this.sunAlt);

  /// Ufuk koordinatını kutup izdüşümüyle (zenit merkezde) çizime çevirir.
  static Offset project(Size s, double alt, double az, double rot) {
    final r = (90 - alt) / 90 * (s.width / 2 - 14);
    final a = (az - rot) * math.pi / 180;
    return s.center(Offset.zero) + Offset(math.sin(a) * r, -math.cos(a) * r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rr = size.width / 2 - 14;
    final dayness = ((sunAlt + 12) / 18).clamp(0.0, 1.0);
    canvas.drawCircle(c, rr, Paint()..color = Color.lerp(const Color(0xFF050A1A), const Color(0xFF3B6EA5), dayness)!);
    canvas.drawCircle(c, rr, Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke);
    canvas.drawCircle(c, rr * 2 / 3, Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke);
    canvas.drawCircle(c, rr / 3, Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke);
    for (var k = 0; k < 4; k++) {
      final o = project(size, -6, k * 90.0, rot);
      final tp = TextPainter(
        text: TextSpan(text: names[k], style: TextStyle(color: k == 0 ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
    final pos = {for (final s in stars) s.$1.name: project(size, s.$2, s.$3, rot)};
    if (lines) {
      final lp = Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 1.2;
      for (final (_, segs) in kConstellations) {
        for (var i = 0; i + 1 < segs.length; i += 2) {
          final a = pos[segs[i]], b = pos[segs[i + 1]];
          if (a != null && b != null) canvas.drawLine(a, b, lp);
        }
      }
    }
    for (final s in stars) {
      final o = pos[s.$1.name]!;
      final r = (3.6 - s.$1.mag * 0.9).clamp(1.0, 5.0);
      canvas.drawCircle(o, r, Paint()..color = Colors.white);
      if (s.$1.mag < 1.0) {
        final tp = TextPainter(
          text: TextSpan(text: s.$1.name, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, o + const Offset(5, -5));
      }
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}

// ------------------------------------------------------------ Ay ve Güneş

class MoonSunTool extends StatefulWidget {
  final ToolContext t;
  const MoonSunTool(this.t, {super.key});

  @override
  State<MoonSunTool> createState() => _MoonSunToolState();
}

class _MoonSunToolState extends State<MoonSunTool> {
  Place? _place;
  DateTime _day = dayOnly(DateTime.now());

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    loadPlace(t).then((p) {
      if (mounted) setState(() => _place = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _place;
    if (p == null) return const Center(child: CircularProgressIndicator());
    final noonish = _day.add(const Duration(hours: 12));
    final at = dayOnly(_day) == dayOnly(DateTime.now()) ? DateTime.now() : noonish;
    final m = moonPhase(at);
    final phases = Ls(t, 'moon_phases');
    final sunDay = prayerTimes(_day, p.lat, p.lng, p.offsetOn(_day), const PrayerMethod('civil', 'civil', 6, isha: 6));
    final rise = sunDay.sunrise, set = sunDay.maghrib, noon = sunDay.dhuhr;
    final civilDawn = sunDay.fajr, civilDusk = sunDay.isha;
    String len() {
      if (rise == null || set == null) return '—';
      final d = set.difference(rise);
      return '${d.inHours} ${L(t, 'hours')} ${d.inMinutes % 60} ${L(t, 'minutes')}';
    }

    String hm(DateTime? d) => d == null ? '—' : hhmm(d);
    return ToolList(children: [
      PlaceRow(
        t: t,
        place: p,
        onChanged: (v) {
          setState(() => _place = v);
          unawaited(savePlace(t, v));
        },
      ),
      Row(children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _day = DateTime(_day.year, _day.month, _day.day - 1))),
        Expanded(
          child: TextButton(
            onPressed: () => setState(() => _day = dayOnly(DateTime.now())),
            child: Text(fmtDate(context, _day), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => _day = DateTime(_day.year, _day.month, _day.day + 1))),
      ]),
      AppPanel(
        child: Row(children: [
          SizedBox(width: 110, height: 110, child: CustomPaint(painter: _MoonPainter(m.age / synodicMonth, p.lat < 0))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(phases[m.phase], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text('${L(t, 'illumination')}: ${(m.illumination * 100).round()}%'),
              Text('${L(t, 'moon_age')}: ${m.age.toStringAsFixed(1)} ${L(t, 'days')}'),
            ]),
          ),
        ]),
      ),
      AppPanel(
        child: Column(children: [
          AppResult(label: L(t, 'next_new_moon'), value: fmtDate(context, nextLunation(at, 0)), lang: t.lang),
          AppResult(label: L(t, 'next_full_moon'), value: fmtDate(context, nextLunation(at, 180)), lang: t.lang),
        ]),
      ),
      AppHeading(L(t, 'sun'), icon: Icons.wb_sunny_rounded),
      AppPanel(
        child: Column(children: [
          AppResult(label: L(t, 'civil_dawn'), value: hm(civilDawn), lang: t.lang),
          AppResult(label: L(t, 'sunrise'), value: hm(rise), lang: t.lang, big: true),
          AppResult(label: L(t, 'solar_noon'), value: hm(noon), lang: t.lang),
          AppResult(label: L(t, 'sunset'), value: hm(set), lang: t.lang, big: true),
          AppResult(label: L(t, 'civil_dusk'), value: hm(civilDusk), lang: t.lang),
          AppResult(label: L(t, 'day_length'), value: len(), lang: t.lang),
        ]),
      ),
      AppInfoCard(L(t, 'astro_note')),
    ]);
  }
}

class _MoonPainter extends CustomPainter {
  /// 0 yeni ay … 0,5 dolunay … 1
  final double f;
  final bool south;
  _MoonPainter(this.f, this.south);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF263238));
    final waxing = f < 0.5;
    final k = math.cos(2 * math.pi * f); // 1 yeni, -1 dolunay
    final path = Path();
    // aydınlık yarım daire
    final rightLit = waxing != south;
    path.addArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, rightLit ? math.pi : -math.pi);
    // terminatör elipsi
    final ex = r * k.abs();
    final ell = Rect.fromCenter(center: c, width: 2 * ex, height: 2 * r);
    path.arcTo(ell, math.pi / 2, (k > 0) == rightLit ? -math.pi : math.pi, false);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF8E1));
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.f != f || old.south != south;
}
