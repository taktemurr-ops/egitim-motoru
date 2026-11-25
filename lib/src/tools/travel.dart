/// Seyahat: park yeri bulucu, gider bölüşme, saat dilimi planlayıcı ve
/// seyahat ifadeleri cep sözlüğü.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:url_launcher/url_launcher.dart';

import '../astro.dart' show greatCircleKm;
import '../common.dart';
import '../data/phrases.dart';
import '../geo.dart';

// ------------------------------------------------------------ park yeri

class ParkTool extends StatefulWidget {
  final ToolContext t;
  const ParkTool(this.t, {super.key});

  @override
  State<ParkTool> createState() => _ParkToolState();
}

class _ParkToolState extends State<ParkTool> {
  Map<String, Object?> _spot = {};
  final _note = TextEditingController();
  double? _distKm;
  double? _bearing;
  bool _busy = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.readMap('spot').then((m) {
      if (!mounted) return;
      setState(() => _spot = m);
      _note.text = '${m['note'] ?? ''}';
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double? get _lat => (_spot['lat'] as num?)?.toDouble();
  double? get _lng => (_spot['lng'] as num?)?.toDouble();

  Future<void> _save() async {
    setState(() => _busy = true);
    final p = await currentPosition(context, t);
    if (!mounted) return;
    setState(() => _busy = false);
    if (p == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.tx(t.isWeb ? 'web_unavailable' : 'not_available'))));
      return;
    }
    final m = {
      'lat': p.latitude,
      'lng': p.longitude,
      'acc': p.accuracy,
      'at': DateTime.now().toIso8601String(),
      'note': _note.text.trim(),
    };
    setState(() {
      _spot = m;
      _distKm = 0;
      _bearing = null;
    });
    await t.store.writeMap('spot', m);
  }

  Future<void> _where() async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    setState(() => _busy = true);
    final p = await currentPosition(context, t);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (p != null) {
        _distKm = greatCircleKm(p.latitude, p.longitude, lat, lng);
        _bearing = bearing(p.latitude, p.longitude, lat, lng);
      }
    });
  }

  Future<void> _openMap() async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lat = _lat, lng = _lng;
    final at = DateTime.tryParse('${_spot['at'] ?? ''}');
    final names = Ls(t, 'cardinals');
    String dir(double d) {
      const combos = [
        [0], [0, 1], [1], [2, 1], [2], [2, 3], [3], [0, 3],
      ];
      return combos[(((d + 22.5) % 360) ~/ 45) % 8].map((k) => names[k]).join();
    }

    return ToolList(children: [
      AppTextField(controller: _note, label: L(t, 'park_note')),
      AppButton(label: L(t, 'save_spot'), icon: Icons.local_parking_rounded, onPressed: _busy ? null : _save),
      if (_busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      if (lat != null && lng != null) ...[
        AppPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L(t, 'saved_spot'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (at != null) Text('${fmtDate(context, at)} ${hhmm(at)}', style: const TextStyle(color: Colors.white70)),
            if ('${_spot['note'] ?? ''}'.isNotEmpty) Text('${_spot['note']}'),
            Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)} (±${((_spot['acc'] as num?) ?? 0).round()} m)',
                style: const TextStyle(color: Colors.white60)),
          ]),
        ),
        if (_distKm != null)
          BigReadout(_distKm! < 1 ? '${(_distKm! * 1000).round()}' : _distKm!.toStringAsFixed(2),
              unit: _distKm! < 1 ? 'm' : 'km', caption: _bearing == null ? null : '${L(t, 'direction')}: ${dir(_bearing!)}'),
        AppButton(label: L(t, 'how_far'), icon: Icons.near_me_rounded, onPressed: _busy ? null : _where),
        OutlinedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map_rounded), label: Text(L(t, 'open_map'))),
        TextButton.icon(
          onPressed: () async {
            setState(() {
              _spot = {};
              _distKm = null;
            });
            await t.store.remove('spot');
          },
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(L(t, 'clear')),
        ),
      ] else
        AppInfoCard(L(t, 'park_hint'), icon: Icons.local_parking_rounded),
      AppInfoCard(L(t, 'perm_location')),
    ]);
  }
}

/// Başlangıç yönü (derece, kuzeyden saat yönünde).
double bearing(double lat1, double lng1, double lat2, double lng2) {
  final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180, dl = (lng2 - lng1) * math.pi / 180;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

// ------------------------------------------------------------ gider bölüşme

/// Harcama: kim ödedi, ne kadar, kimler arasında bölünecek.
class Expense {
  final String id;
  final String title;
  final double amount;
  final String payer;
  final List<String> among;
  const Expense(this.id, this.title, this.amount, this.payer, this.among);

  Map<String, Object?> toMap() => {'id': id, 'title': title, 'amount': amount, 'payer': payer, 'among': among};
  static Expense fromMap(Map<String, Object?> m) => Expense('${m['id']}', '${m['title'] ?? ''}',
      (m['amount'] as num?)?.toDouble() ?? 0, '${m['payer']}', [for (final x in (m['among'] as List? ?? const [])) '$x']);
}

/// Kişi başı bakiye (+ alacaklı, − borçlu).
Map<String, double> balances(List<String> people, List<Expense> ex) {
  final b = {for (final p in people) p: 0.0};
  for (final e in ex) {
    final among = e.among.where(b.containsKey).toList();
    if (among.isEmpty || !b.containsKey(e.payer)) continue;
    b[e.payer] = b[e.payer]! + e.amount;
    final share = e.amount / among.length;
    for (final p in among) {
      b[p] = b[p]! - share;
    }
  }
  return b;
}

/// En az sayıda ödemeyle hesaplaşma (açgözlü eşleştirme).
List<(String, String, double)> settle(Map<String, double> b) {
  final debt = b.entries.where((e) => e.value < -0.005).map((e) => [e.key, -e.value]).toList();
  final cred = b.entries.where((e) => e.value > 0.005).map((e) => [e.key, e.value]).toList();
  debt.sort((a, c) => (c[1] as double).compareTo(a[1] as double));
  cred.sort((a, c) => (c[1] as double).compareTo(a[1] as double));
  final out = <(String, String, double)>[];
  var i = 0, j = 0;
  while (i < debt.length && j < cred.length) {
    final x = math.min<double>(debt[i][1] as double, cred[j][1] as double);
    out.add((debt[i][0] as String, cred[j][0] as String, (x * 100).round() / 100));
    debt[i][1] = (debt[i][1] as double) - x;
    cred[j][1] = (cred[j][1] as double) - x;
    if ((debt[i][1] as double) < 0.005) i++;
    if ((cred[j][1] as double) < 0.005) j++;
  }
  return out;
}

class SplitTool extends StatefulWidget {
  final ToolContext t;
  const SplitTool(this.t, {super.key});

  @override
  State<SplitTool> createState() => _SplitToolState();
}

class _SplitToolState extends State<SplitTool> {
  List<String> _people = [];
  List<Expense> _ex = [];
  bool _loaded = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    () async {
      final p = await t.store.readStrings('people');
      final e = await t.store.readList('expenses');
      if (!mounted) return;
      setState(() {
        _people = p;
        _ex = e.map(Expense.fromMap).toList();
        _loaded = true;
      });
    }();
  }

  Future<void> _save() async {
    await t.store.writeStrings('people', _people);
    await t.store.writeList('expenses', [for (final e in _ex) e.toMap()]);
  }

  Future<String?> _ask(String label) async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(L(t, 'save'))),
        ],
      ),
    );
    c.dispose();
    return r == null || r.isEmpty ? null : r;
  }

  Future<void> _addExpense() async {
    if (_people.isEmpty) return;
    final title = TextEditingController(), amount = TextEditingController();
    var payer = _people.first;
    final among = {..._people};
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(L(t, 'expense')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AppTextField(controller: title, label: L(t, 'description')),
              AppNumberField(controller: amount, label: L(t, 'amount')),
              Pick<String>(label: L(t, 'paid_by'), values: _people, text: (s) => s, value: payer, onChanged: (v) => set(() => payer = v)),
              Align(alignment: AlignmentDirectional.centerStart, child: Text(L(t, 'split_with'))),
              Wrap(spacing: 6, children: [
                for (final p in _people)
                  FilterChip(
                    label: Text(p),
                    selected: among.contains(p),
                    onSelected: (v) => set(() => v ? among.add(p) : among.remove(p)),
                  ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(L(t, 'cancel'))),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(L(t, 'save'))),
          ],
        ),
      ),
    );
    final a = parseNumber(amount.text);
    final ti = title.text.trim();
    title.dispose();
    amount.dispose();
    if (ok != true || a == null || a <= 0 || among.isEmpty) return;
    setState(() => _ex.add(Expense(newId(), ti.isEmpty ? L(t, 'expense') : ti, a, payer, among.toList())));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final b = balances(_people, _ex);
    final total = _ex.fold<double>(0, (s, e) => s + e.amount);
    return ToolList(children: [
      AppHeading(L(t, 'people'), icon: Icons.groups_rounded),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          for (final p in _people)
            InputChip(
              label: Text(p),
              onDeleted: _ex.any((e) => e.payer == p || e.among.contains(p))
                  ? null
                  : () {
                      setState(() => _people.remove(p));
                      unawaited(_save());
                    },
            ),
          ActionChip(
            avatar: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(L(t, 'add')),
            onPressed: () async {
              final n = await _ask(L(t, 'name'));
              if (n == null || _people.contains(n)) return;
              setState(() => _people.add(n));
              await _save();
            },
          ),
        ]),
      ),
      if (_people.length < 2) AppInfoCard(L(t, 'split_hint'), icon: Icons.info_outline_rounded),
      if (_people.isNotEmpty) AppButton(label: L(t, 'add_expense'), icon: Icons.receipt_long_rounded, onPressed: _addExpense),
      if (_ex.isNotEmpty) ...[
        AppPanel(child: AppResult(label: L(t, 'total'), value: formatNumber(total, digits: 2), lang: t.lang, big: true)),
        AppHeading(L(t, 'settle'), icon: Icons.swap_horiz_rounded),
        AppPanel(
          child: Column(children: [
            for (final s in settle(b))
              AppResult(label: '${s.$1} → ${s.$2}', value: formatNumber(s.$3, digits: 2), lang: t.lang),
            if (settle(b).isEmpty) Text(L(t, 'all_settled')),
          ]),
        ),
        AppHeading(L(t, 'balances')),
        AppPanel(
          child: Column(children: [
            for (final e in b.entries)
              AppResult(label: e.key, value: '${e.value >= 0 ? '+' : ''}${formatNumber(e.value, digits: 2)}', lang: t.lang),
          ]),
        ),
        AppHeading(L(t, 'expenses')),
        for (final e in _ex.reversed)
          AppPanel(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.title),
              subtitle: Text('${e.payer} · ${e.among.join(', ')}', style: const TextStyle(color: Colors.white60)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(formatNumber(e.amount, digits: 2), style: const TextStyle(fontWeight: FontWeight.w800)),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    if (!await confirmDelete(context, t, e.title)) return;
                    setState(() => _ex.remove(e));
                    await _save();
                  },
                ),
              ]),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(L(t, 'new_trip')),
          onPressed: () async {
            if (!await confirmDelete(context, t, L(t, 'new_trip'))) return;
            setState(() => _ex.clear());
            await _save();
          },
        ),
      ],
    ]);
  }
}

// ------------------------------------------------------------ saat dilimi

/// Ana saatin hangi saatlerinde (0–23) bütün şehirler mesai içindedir?
/// [offsets]: UTC farkları; ilki ana şehir.
List<int> overlapHours(List<double> offsets, {int start = 9, int end = 18}) {
  final out = <int>[];
  for (var h = 0; h < 24; h++) {
    final utc = h - offsets.first;
    var ok = true;
    for (final o in offsets) {
      final local = ((utc + o) % 24 + 24) % 24;
      if (local < start || local >= end) {
        ok = false;
        break;
      }
    }
    if (ok) out.add(h);
  }
  return out;
}

class TimeZoneTool extends StatefulWidget {
  final ToolContext t;
  const TimeZoneTool(this.t, {super.key});

  @override
  State<TimeZoneTool> createState() => _TimeZoneToolState();
}

class _TimeZoneToolState extends State<TimeZoneTool> {
  List<String> _cities = [];
  double _hour = DateTime.now().hour.toDouble();
  int _start = 9, _end = 18;
  bool _loaded = false;
  Timer? _tick;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    () async {
      final c = await t.store.readStrings('cities');
      if (!mounted) return;
      setState(() {
        _cities = c.isEmpty ? ['London', 'New York', 'Tokyo'] : c;
        _loaded = true;
      });
    }();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final now = DateTime.now();
    final myOff = now.timeZoneOffset.inMinutes / 60;
    final utcNow = now.toUtc();
    final offs = [myOff, for (final c in _cities) cityByName(c).offsetAt(utcNow)];
    final overlap = overlapHours(offs, start: _start, end: _end);
    final pickedUtc = DateTime.utc(utcNow.year, utcNow.month, utcNow.day).add(Duration(minutes: ((_hour - myOff) * 60).round()));
    String at(double off) => hhmm(pickedUtc.add(Duration(minutes: (off * 60).round())));
    String off(double o) => 'UTC${o >= 0 ? '+' : '−'}${formatNumber(o.abs())}';
    return ToolList(children: [
      AppPanel(
        child: Column(children: [
          Text('${L(t, 'your_time')}: ${two(_hour.floor())}:${two(((_hour % 1) * 60).round())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Slider(value: _hour, min: 0, max: 23.5, divisions: 47, onChanged: (v) => setState(() => _hour = v)),
          TextButton(onPressed: () => setState(() => _hour = now.hour + (now.minute >= 30 ? 0.5 : 0)), child: Text(L(t, 'now'))),
        ]),
      ),
      AppPanel(
        child: Column(children: [
          AppResult(label: '${L(t, 'my_location')} (${off(myOff)})', value: at(myOff), lang: t.lang, big: true),
          for (var i = 0; i < _cities.length; i++)
            Row(children: [
              Expanded(child: AppResult(label: '${_cities[i]} (${off(offs[i + 1])})', value: at(offs[i + 1]), lang: t.lang)),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  setState(() => _cities.removeAt(i));
                  unawaited(t.store.writeStrings('cities', _cities));
                },
              ),
            ]),
        ]),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(L(t, 'add_city')),
        onPressed: () async {
          final c = await pickCity(context, t);
          if (c == null || _cities.contains(c.name)) return;
          setState(() => _cities.add(c.name));
          await t.store.writeStrings('cities', _cities);
        },
      ),
      AppHeading(L(t, 'work_overlap'), icon: Icons.handshake_rounded),
      AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RangeSlider(
            values: RangeValues(_start.toDouble(), _end.toDouble()),
            min: 0,
            max: 24,
            divisions: 24,
            labels: RangeLabels('$_start:00', '$_end:00'),
            onChanged: (v) => setState(() {
              _start = v.start.round();
              _end = math.max<int>(v.end.round(), _start + 1);
            }),
          ),
          Text('${L(t, 'work_hours')}: $_start:00–$_end:00', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var h = 0; h < 24; h++)
              Container(
                width: 34,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: overlap.contains(h) ? Colors.greenAccent.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.05),
                ),
                child: Text(two(h), textAlign: TextAlign.center),
              ),
          ]),
          const SizedBox(height: 6),
          Text(overlap.isEmpty ? L(t, 'no_overlap') : L(t, 'overlap_hint'), style: const TextStyle(color: Colors.white60)),
        ]),
      ),
      AppInfoCard(L(t, 'dst_note')),
    ]);
  }
}

// ------------------------------------------------------------ ifadeler

class PhrasebookTool extends StatefulWidget {
  final ToolContext t;
  const PhrasebookTool(this.t, {super.key});

  @override
  State<PhrasebookTool> createState() => _PhrasebookToolState();
}

class _PhrasebookToolState extends State<PhrasebookTool> {
  int _target = 1;
  int _cat = 0;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.read('target').then((v) {
      final i = kLangCodes.indexOf(v ?? '');
      final mine = kLangCodes.indexOf(t.lang);
      if (mounted) setState(() => _target = i >= 0 ? i : (mine == 1 ? 0 : 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final mine = math.max<int>(0, kLangCodes.indexOf(t.lang));
    final cats = Ls(t, 'phrase_cats');
    final list = kPhrases.where((p) => p.cat == _cat).toList();
    final rtl = const {'ar', 'fa', 'he', 'ur'}.contains(kLangCodes[_target]);
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Pick<int>(
          label: L(t, 'target_lang'),
          values: List.generate(kLangNames.length, (i) => i),
          text: (i) => kLangNames[i],
          value: _target,
          onChanged: (v) {
            setState(() => _target = v);
            unawaited(t.store.write('target', kLangCodes[v]));
          },
        ),
      ),
      Choice<int>(
        values: List.generate(cats.length, (i) => i),
        labels: cats,
        selected: _cat,
        onChanged: (v) => setState(() => _cat = v),
      ),
      for (final p in list)
        AppPanel(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(p.text[mine], style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            SelectableText(
              p.text[_target],
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(color: AppLook.of(context).number, fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ]),
        ),
      AppInfoCard(L(t, 'phrase_note')),
    ]);
  }
}
