/// Namaz vakitleri, kıble pusulası, zikirmatik, imsakiye ve Hicri takvim.
/// Bütün hesaplar cihazda yapılır; yöntem ekranda gösterilir ve
/// değiştirilebilir. Uygulamalar dini hüküm vermez.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:studio_core/apps/apps.dart';

import '../astro.dart';
import '../common.dart';
import '../geo.dart';

// ------------------------------------------------------------ ortak ayar

class _FaithSettings {
  Place place;
  String method;
  bool hanafi;
  _FaithSettings(this.place, this.method, this.hanafi);

  static Future<_FaithSettings> load(ToolContext t) async {
    final place = await loadPlace(t);
    final m = await t.store.read('method') ?? (place.city != null && place.city!.std == 3 && t.lang == 'tr' ? 'diyanet' : 'mwl');
    return _FaithSettings(place, m, await t.store.readBool('hanafi'));
  }

  Future<void> save(ToolContext t) async {
    await savePlace(t, place);
    await t.store.write('method', method);
    await t.store.writeBool('hanafi', hanafi);
  }

  PrayerDay day(DateTime d) => prayerTimes(d, place.lat, place.lng, place.offsetOn(d), methodById(method), hanafi: hanafi);
}

String _hm(DateTime? d) => d == null ? '—' : hhmm(d);

/// Yöntem ve ikindi seçimi.
class _MethodPanel extends StatelessWidget {
  final ToolContext t;
  final _FaithSettings s;
  final VoidCallback onChanged;
  const _MethodPanel(this.t, this.s, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final m = methodById(s.method);
    return AppPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Pick<PrayerMethod>(
          label: L(t, 'method'),
          values: prayerMethods,
          text: (v) => v.name,
          value: m,
          onChanged: (v) {
            s.method = v.id;
            onChanged();
          },
        ),
        Text('${L(t, 'fajr_isha_angles')}: ${m.summary}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 6),
        Choice<bool>(
          values: const [false, true],
          labels: [L(t, 'asr_standard'), L(t, 'asr_hanafi')],
          selected: s.hanafi,
          onChanged: (v) {
            s.hanafi = v;
            onChanged();
          },
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------ vakitler

class PrayerTimesTool extends StatefulWidget {
  final ToolContext t;
  const PrayerTimesTool(this.t, {super.key});

  @override
  State<PrayerTimesTool> createState() => _PrayerTimesToolState();
}

class _PrayerTimesToolState extends State<PrayerTimesTool> {
  _FaithSettings? _s;
  DateTime _day = dayOnly(DateTime.now());
  Timer? _tick;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _FaithSettings.load(t).then((s) {
      if (mounted) setState(() => _s = s);
    });
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    unawaited(_s!.save(t));
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final names = Ls(t, 'prayer_names');
    final pd = s.day(_day);
    final now = DateTime.now();
    // Sonraki vakit (bugün yoksa yarının imsakı).
    DateTime? next;
    var nextName = '';
    final today = s.day(dayOnly(now));
    for (var i = 0; i < 6; i++) {
      final v = today.times[i];
      if (v != null && v.isAfter(now)) {
        next = v;
        nextName = names[i];
        break;
      }
    }
    if (next == null) {
      next = s.day(dayOnly(now).add(const Duration(days: 1))).fajr;
      nextName = names[0];
    }
    final left = next?.difference(now);
    return ToolList(children: [
      PlaceRow(
        t: t,
        place: s.place,
        onChanged: (p) {
          s.place = p;
          _changed();
        },
      ),
      if (left != null)
        BigReadout('${left.inHours}:${two(left.inMinutes % 60)}', caption: '${L(t, 'next_time')}: $nextName'),
      AppPanel(
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _day = dayOnly(DateTime.now())),
                child: Text(fmtDate(context, _day), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))),
            ),
          ]),
          for (var i = 0; i < 6; i++)
            AppResult(
              label: names[i],
              value: _hm(pd.times[i]),
              lang: t.lang,
              big: pd.times[i] != null && pd.times[i] == next,
            ),
        ]),
      ),
      _MethodPanel(t, s, _changed),
      AppInfoCard(L(t, 'calc_note'), icon: Icons.info_outline_rounded),
    ]);
  }
}

// ------------------------------------------------------------ kıble

class QiblaTool extends StatefulWidget {
  final ToolContext t;
  const QiblaTool(this.t, {super.key});

  @override
  State<QiblaTool> createState() => _QiblaToolState();
}

class _QiblaToolState extends State<QiblaTool> {
  final _acc = SensorWatch<AccelerometerEvent>();
  final _mag = SensorWatch<MagnetometerEvent>();
  Place? _place;
  double? _heading;
  double _smooth = 0;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    loadPlace(t).then((p) {
      if (mounted) setState(() => _place = p);
    });
    if (!t.isWeb) {
      _acc.start(() => accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval), (_) {}, _changed);
      _mag.start(() => magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval), (_) => _update(), _changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  // Android getRotationMatrix + getOrientation ile aynı hesap (pilot pusula).
  void _update() {
    final a = _acc.last, m = _mag.last;
    if (a == null || m == null) return;
    final ax = a.x, ay = a.y, az = a.z;
    var hx = m.y * az - m.z * ay, hy = m.z * ax - m.x * az, hz = m.x * ay - m.y * ax;
    final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < 0.1) return;
    hx /= normH;
    hy /= normH;
    hz /= normH;
    final normA = math.sqrt(ax * ax + ay * ay + az * az);
    final nx = ax / normA, nz = az / normA;
    final my = nz * hx - nx * hz;
    var h = math.atan2(hy, my) * 180 / math.pi;
    if (h < 0) h += 360;
    var diff = h - _smooth;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    _smooth = (_smooth + diff * 0.2) % 360;
    if (_smooth < 0) _smooth += 360;
    setState(() => _heading = _smooth);
  }

  @override
  void dispose() {
    _acc.stop();
    _mag.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _place;
    if (p == null) return const Center(child: CircularProgressIndicator());
    final q = qiblaBearing(p.lat, p.lng);
    final km = greatCircleKm(p.lat, p.lng, kaabaLat, kaabaLng);
    final sensor = !t.isWeb && _mag.available != false && _acc.available != false;
    final h = _heading;
    final rel = h == null ? null : ((q - h) % 360 + 360) % 360;
    final aligned = rel != null && (rel < 4 || rel > 356);
    final accent = AppLook.of(context).accent;
    return ToolList(children: [
      PlaceRow(
        t: t,
        place: p,
        onChanged: (v) {
          setState(() => _place = v);
          unawaited(savePlace(t, v));
        },
      ),
      BigReadout('${q.toStringAsFixed(1)}°', caption: L(t, 'qibla_from_north')),
      if (sensor)
        Center(
          child: SizedBox(
            width: 290,
            height: 290,
            child: Transform.rotate(
              angle: -(h ?? 0) * math.pi / 180,
              child: CustomPaint(painter: _QiblaDial(q, Ls(t, 'cardinals'), aligned ? Colors.greenAccent : accent)),
            ),
          ),
        ),
      if (sensor && h == null) AppInfoCard(L(t, 'calib8')),
      if (sensor && h != null)
        AppInfoCard(aligned ? L(t, 'qibla_aligned') : L(t, 'qibla_turn'),
            icon: aligned ? Icons.check_circle_rounded : Icons.rotate_right_rounded),
      if (!sensor) notAvailable(t),
      AppPanel(child: AppResult(label: L(t, 'distance'), value: '${km.round()} km', lang: t.lang)),
      AppInfoCard(L(t, 'qibla_note')),
    ]);
  }
}

class _QiblaDial extends CustomPainter {
  final double qibla;
  final List<String> names;
  final Color color;
  _QiblaDial(this.qibla, this.names, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: 0.06));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white38);
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final l = i % 18 == 0 ? 16.0 : (i % 2 == 0 ? 9.0 : 5.0);
      final o = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + o * (r - l), c + o * r, Paint()..color = Colors.white54);
    }
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
            text: names[k],
            style: TextStyle(color: k == 0 ? Colors.redAccent : Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      final o = c + Offset(math.sin(a), -math.cos(a)) * (r - 32);
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
    final qa = qibla * math.pi / 180;
    final dir = Offset(math.sin(qa), -math.cos(qa));
    canvas.drawLine(
        c,
        c + dir * (r - 44),
        Paint()
          ..color = color
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(c + dir * (r - 44), 12, Paint()..color = color);
    canvas.drawCircle(c, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_QiblaDial old) => old.qibla != qibla || old.color != color;
}

// ------------------------------------------------------------ zikirmatik

/// Hazır zikirler (transliterasyon; kullanıcı kendi zikrini ekleyebilir).
const List<List<String>> kDhikrPresets = [
  ['Sübhânallah', 'Subhanallah'],
  ['Elhamdülillah', 'Alhamdulillah'],
  ['Allâhu ekber', 'Allahu akbar'],
  ['Lâ ilâhe illallah', 'La ilaha illallah'],
  ['Estağfirullah', 'Astaghfirullah'],
];

class ZikirTool extends StatefulWidget {
  final ToolContext t;
  const ZikirTool(this.t, {super.key});

  @override
  State<ZikirTool> createState() => _ZikirToolState();
}

class _ZikirToolState extends State<ZikirTool> {
  List<Map<String, Object?>> _items = [];
  int _sel = 0;
  bool _vibrate = true;
  bool _loaded = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var items = await t.store.readList('items');
    if (items.isEmpty) {
      items = [
        for (final p in kDhikrPresets) {'name': C(t, p), 'count': 0, 'target': 33, 'laps': 0},
      ];
    }
    final sel = await t.store.readInt('sel');
    final vib = await t.store.readBool('vibrate', true);
    if (!mounted) return;
    setState(() {
      _items = items;
      _sel = sel.clamp(0, items.length - 1);
      _vibrate = vib;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await t.store.writeList('items', _items);
    await t.store.write('sel', '$_sel');
  }

  int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  void _tap() {
    final it = _items[_sel];
    var c = _int(it['count']) + 1;
    final target = _int(it['target']);
    var laps = _int(it['laps']);
    if (target > 0 && c >= target) {
      laps++;
      c = 0;
      if (_vibrate) unawaited(HapticFeedback.heavyImpact());
    } else if (_vibrate) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _items[_sel] = {...it, 'count': c, 'laps': laps});
    unawaited(_save());
  }

  Future<void> _add() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(L(t, 'add')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: L(t, 'name'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(L(t, 'save'))),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty) return;
    setState(() {
      _items.add({'name': name, 'count': 0, 'target': 33, 'laps': 0});
      _sel = _items.length - 1;
    });
    unawaited(_save());
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final it = _items[_sel];
    final target = _int(it['target']);
    final s = AppLook.of(context);
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Pick<int>(
          label: L(t, 'dhikr'),
          values: List.generate(_items.length, (i) => i),
          text: (i) => '${_items[i]['name']}',
          value: _sel,
          onChanged: (i) {
            setState(() => _sel = i);
            unawaited(_save());
          },
        ),
      ),
      Choice<int>(
        values: const [33, 99, 100, 1000, 0],
        labels: ['33', '99', '100', '1000', '∞'],
        selected: const [33, 99, 100, 1000, 0].contains(target) ? target : 33,
        onChanged: (v) {
          setState(() => _items[_sel] = {...it, 'target': v});
          unawaited(_save());
        },
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          button: true,
          label: L(t, 'tap_count'),
          child: InkWell(
            borderRadius: BorderRadius.circular(200),
            onTap: _tap,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [s.accent.withValues(alpha: 0.55), s.card]),
                  border: Border.all(color: s.accent, width: 3),
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_int(it['count'])}',
                        style: TextStyle(color: s.number, fontSize: 84, fontWeight: FontWeight.w900)),
                    Text(target > 0 ? '/ $target · ${L(t, 'laps')}: ${_int(it['laps'])}' : '${L(t, 'laps')}: ${_int(it['laps'])}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(L(t, 'reset')),
            onPressed: () {
              setState(() => _items[_sel] = {...it, 'count': 0, 'laps': 0});
              unawaited(_save());
            },
          ),
          OutlinedButton.icon(icon: const Icon(Icons.add_rounded), label: Text(L(t, 'add')), onPressed: _add),
          if (_items.length > 1)
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(L(t, 'delete')),
              onPressed: () async {
                if (!await confirmDelete(context, t, '${it['name']}')) return;
                setState(() {
                  _items.removeAt(_sel);
                  _sel = 0;
                });
                unawaited(_save());
              },
            ),
          FilterChip(
            label: Text(L(t, 'vibrate')),
            selected: _vibrate,
            onSelected: (v) {
              setState(() => _vibrate = v);
              unawaited(t.store.writeBool('vibrate', v));
            },
          ),
        ]),
      ),
    ]);
  }
}

// ------------------------------------------------------------ imsakiye

class ImsakiyeTool extends StatefulWidget {
  final ToolContext t;
  const ImsakiyeTool(this.t, {super.key});

  @override
  State<ImsakiyeTool> createState() => _ImsakiyeToolState();
}

class _ImsakiyeToolState extends State<ImsakiyeTool> {
  _FaithSettings? _s;
  bool _ramadan = true;
  int _adjust = 0;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _FaithSettings.load(t).then((s) async {
      final a = await t.store.readInt('adjust');
      if (mounted) setState(() {
        _s = s;
        _adjust = a;
      });
    });
  }

  void _changed() {
    setState(() {});
    unawaited(_s!.save(t));
  }

  /// Gösterilecek günler: yaklaşan (ya da süren) Ramazan veya bu ay.
  List<DateTime> _days() {
    final now = dayOnly(DateTime.now());
    if (!_ramadan) {
      final n = DateTime(now.year, now.month + 1, 0).day;
      return [for (var i = 1; i <= n; i++) DateTime(now.year, now.month, i)];
    }
    return ramadanDays(now, adjust: _adjust);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final names = Ls(t, 'prayer_names');
    final today = dayOnly(DateTime.now());
    final days = _days();
    TextStyle st(bool b) => TextStyle(color: b ? AppLook.of(context).number : Colors.white, fontWeight: b ? FontWeight.w900 : FontWeight.w500);
    return ToolList(children: [
      PlaceRow(
        t: t,
        place: s.place,
        onChanged: (p) {
          s.place = p;
          _changed();
        },
      ),
      Choice<bool>(
        values: const [true, false],
        labels: [L(t, 'ramadan'), L(t, 'this_month')],
        selected: _ramadan,
        onChanged: (v) => setState(() => _ramadan = v),
      ),
      AppPanel(
        child: Table(
          columnWidths: const {0: FlexColumnWidth(2.2)},
          children: [
            TableRow(children: [
              for (final h in [L(t, 'date'), names[0], names[1], L(t, 'iftar')])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(h, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w800)),
                ),
            ]),
            for (final d in days)
              () {
                final p = s.day(d);
                final b = d == today;
                return TableRow(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(MaterialLocalizations.of(context).formatShortMonthDay(d), style: st(b))),
                  Text(_hm(p.fajr), style: st(b)),
                  Text(_hm(p.sunrise), style: st(b)),
                  Text(_hm(p.maghrib), style: st(b)),
                ]);
              }(),
          ],
        ),
      ),
      _MethodPanel(t, s, _changed),
      if (_ramadan)
        AppPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L(t, 'hijri_adjust'), style: const TextStyle(color: Colors.white70)),
            Choice<int>(
              values: const [-2, -1, 0, 1, 2],
              labels: const ['-2', '-1', '0', '+1', '+2'],
              selected: _adjust,
              onChanged: (v) {
                setState(() => _adjust = v);
                unawaited(t.store.write('adjust', '$v'));
              },
            ),
          ]),
        ),
      AppInfoCard(L(t, 'calc_note')),
      AppInfoCard(L(t, 'hijri_note')),
    ]);
  }
}

/// Bugünü içeren ya da sıradaki Ramazan'ın Miladi günleri.
List<DateTime> ramadanDays(DateTime today, {int adjust = 0}) {
  final h = toHijri(today, adjust: adjust);
  final y = h.$2 > 9 ? h.$1 + 1 : h.$1;
  final start = fromHijri(y, 9, 1, adjust: adjust);
  final n = hijriMonthLength(y, 9);
  return [for (var i = 0; i < n; i++) DateTime(start.year, start.month, start.day + i)];
}

// ------------------------------------------------------------ Hicri takvim

const List<List<String>> kHijriMonths = [
  ['Muharrem', 'Muharram'],
  ['Safer', 'Safar'],
  ['Rebiülevvel', "Rabi' al-Awwal"],
  ['Rebiülahir', "Rabi' al-Thani"],
  ['Cemaziyelevvel', 'Jumada al-Ula'],
  ['Cemaziyelahir', 'Jumada al-Akhira'],
  ['Recep', 'Rajab'],
  ['Şaban', "Sha'ban"],
  ['Ramazan', 'Ramadan'],
  ['Şevval', 'Shawwal'],
  ['Zilkade', "Dhu al-Qi'dah"],
  ['Zilhicce', 'Dhu al-Hijjah'],
];

/// Dini gün: ad ve Hicri yıl içindeki Miladi tarihini veren kural.
class HolyDay {
  final List<String> name;
  final DateTime Function(int hy, int adjust) date;
  const HolyDay(this.name, this.date);
}

DateTime _h(int y, int m, int d, int a) => fromHijri(y, m, d, adjust: a);

/// Kandil geceleri, geleneğe uygun olarak bir önceki günün akşamına yazılır.
final List<HolyDay> kHolyDays = [
  HolyDay(const ['Hicri Yılbaşı', 'Islamic New Year'], (y, a) => _h(y, 1, 1, a)),
  HolyDay(const ['Aşure Günü', 'Day of Ashura'], (y, a) => _h(y, 1, 10, a)),
  HolyDay(const ['Mevlid Kandili', 'Mawlid (eve)'], (y, a) => _h(y, 3, 11, a)),
  HolyDay(const ['Regaib Kandili', 'Laylat al-Raghaib'], (y, a) {
    var d = _h(y, 7, 1, a);
    while (d.weekday != DateTime.friday) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return DateTime(d.year, d.month, d.day - 1);
  }),
  HolyDay(const ['Miraç Kandili', "Isra and Mi'raj (eve)"], (y, a) => _h(y, 7, 26, a)),
  HolyDay(const ['Berat Kandili', "Laylat al-Bara'ah (eve)"], (y, a) => _h(y, 8, 14, a)),
  HolyDay(const ['Ramazan Başlangıcı', 'First day of Ramadan'], (y, a) => _h(y, 9, 1, a)),
  HolyDay(const ['Kadir Gecesi', 'Laylat al-Qadr (eve of 27th)'], (y, a) => _h(y, 9, 26, a)),
  HolyDay(const ['Ramazan Bayramı', 'Eid al-Fitr'], (y, a) => _h(y, 10, 1, a)),
  HolyDay(const ['Arefe', 'Day of Arafah'], (y, a) => _h(y, 12, 9, a)),
  HolyDay(const ['Kurban Bayramı', 'Eid al-Adha'], (y, a) => _h(y, 12, 10, a)),
];

/// [from] tarihinden itibaren sıradaki dini günler (tarih sırasıyla).
List<(HolyDay, DateTime)> upcomingHolyDays(DateTime from, {int adjust = 0, int count = 11}) {
  final hy = toHijri(from, adjust: adjust).$1;
  final out = <(HolyDay, DateTime)>[];
  for (final y in [hy, hy + 1]) {
    for (final d in kHolyDays) {
      final g = d.date(y, adjust);
      if (!g.isBefore(dayOnly(from))) out.add((d, g));
    }
  }
  out.sort((a, b) => a.$2.compareTo(b.$2));
  return out.take(count).toList();
}

class HijriTool extends StatefulWidget {
  final ToolContext t;
  const HijriTool(this.t, {super.key});

  @override
  State<HijriTool> createState() => _HijriToolState();
}

class _HijriToolState extends State<HijriTool> {
  int _adjust = 0;
  late int _y, _m;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    final h = toHijri(DateTime.now());
    _y = h.$1;
    _m = h.$2;
    t.store.readInt('adjust').then((a) {
      if (!mounted) return;
      final h2 = toHijri(DateTime.now(), adjust: a);
      setState(() {
        _adjust = a;
        _y = h2.$1;
        _m = h2.$2;
      });
    });
  }

  void _shift(int d) {
    setState(() {
      _m += d;
      if (_m > 12) {
        _m = 1;
        _y++;
      } else if (_m < 1) {
        _m = 12;
        _y--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final h = toHijri(today, adjust: _adjust);
    final first = fromHijri(_y, _m, 1, adjust: _adjust);
    final len = hijriMonthLength(_y, _m);
    final lead = (first.weekday - 1) % 7;
    final loc = MaterialLocalizations.of(context);
    final s = AppLook.of(context);
    final wd = loc.narrowWeekdays;
    // narrowWeekdays pazar ile başlar; pazartesiden başlat.
    final heads = [for (var i = 1; i <= 7; i++) wd[i % 7]];
    return ToolList(children: [
      BigReadout('${h.$3} ${C(t, kHijriMonths[h.$2 - 1])}', caption: '${h.$1} AH · ${fmtDate(context, today)}'),
      AppPanel(
        child: Column(children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => _shift(-1)),
            Expanded(
              child: Text('${C(t, kHijriMonths[_m - 1])} $_y',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => _shift(1)),
          ]),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: [
              for (final w in heads) Center(child: Text(w, style: const TextStyle(color: Colors.white60))),
              for (var i = 0; i < lead; i++) const SizedBox(),
              for (var d = 1; d <= len; d++)
                () {
                  final g = DateTime(first.year, first.month, first.day + d - 1);
                  final isToday = g == today;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isToday ? s.accent.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$d', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('${g.day}/${g.month}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ]),
                  );
                }(),
            ],
          ),
        ]),
      ),
      AppHeading(L(t, 'holy_days'), icon: Icons.event_rounded),
      AppPanel(
        child: Column(children: [
          for (final e in upcomingHolyDays(today, adjust: _adjust))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(C(t, e.$1.name), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(fmtDate(context, e.$2)),
              trailing: Text(dueText(t, daysBetween(today, e.$2)), style: TextStyle(color: s.accent)),
            ),
        ]),
      ),
      AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(L(t, 'hijri_adjust'), style: const TextStyle(color: Colors.white70)),
          Choice<int>(
            values: const [-2, -1, 0, 1, 2],
            labels: const ['-2', '-1', '0', '+1', '+2'],
            selected: _adjust,
            onChanged: (v) {
              final h2 = toHijri(DateTime.now(), adjust: v);
              setState(() {
                _adjust = v;
                _y = h2.$1;
                _m = h2.$2;
              });
              unawaited(t.store.write('adjust', '$v'));
            },
          ),
        ]),
      ),
      AppInfoCard(L(t, 'hijri_note')),
    ]);
  }
}
