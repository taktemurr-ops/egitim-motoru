/// Ders ve sınav: sınav geri sayımı, deneme net hesaplayıcı, periyodik
/// tablo ve formül kitabı.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../data/elements.dart';
import '../data/formulas.dart';
import '../learn_core.dart';

// ------------------------------------------------------------ sınav geri sayımı

/// Resmî sınav tarihleri (ÖSYM 2027 sınav takvimi, MEB 2027 LGS duyurusu;
/// 25.11.2026 itibarıyla). Her yıl güncellenmeli; kullanıcı değiştirebilir.
const List<(String, String)> kExamDates = [
  ('MSÜ 2027', '2027-03-20'),
  ('ALES/1 2027', '2027-04-18'),
  ('LGS 2027', '2027-06-13'),
  ('YKS 2027 · TYT', '2027-06-19'),
  ('YKS 2027 · AYT / YDT', '2027-06-20'),
  ('ALES/2 2027', '2027-07-11'),
  ('DGS 2027', '2027-07-18'),
  ('KPSS 2027 · GY-GK', '2027-09-12'),
  ('KPSS 2027 · Alan Bilgisi', '2027-09-18'),
  ('ALES/3 2027', '2027-11-28'),
];
const String kExamSource = 'ÖSYM 2027 sınav takvimi · MEB';
const String kExamAsOf = '2026-11-25';

class ExamCountdownTool extends StatefulWidget {
  final ToolContext t;
  const ExamCountdownTool(this.t, {super.key});

  @override
  State<ExamCountdownTool> createState() => _ExamCountdownToolState();
}

class _ExamCountdownToolState extends State<ExamCountdownTool> {
  List<Map<String, Object?>> _mine = [];
  Set<String> _hidden = {};
  Timer? _tick;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    () async {
      final m = await t.store.readList('mine');
      final h = await t.store.readStrings('hidden');
      if (mounted) setState(() {
        _mine = m;
        _hidden = h.toSet();
      });
    }();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    var date = DateTime.now().add(const Duration(days: 30));
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(controller: name, label: L(t, 'exam_name')),
            DateRow(label: L(t, 'date'), value: date, onChanged: (v) => set(() => date = v), first: DateTime.now()),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(L(t, 'cancel'))),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(L(t, 'save'))),
          ],
        ),
      ),
    );
    final n = name.text.trim();
    name.dispose();
    if (ok != true || n.isEmpty) return;
    setState(() => _mine.add({'id': newId(), 'name': n, 'date': isoDay(date)}));
    await t.store.writeList('mine', _mine);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = <(String, DateTime, String?)>[
      for (final e in kExamDates)
        if (!_hidden.contains(e.$1)) (e.$1, DateTime.parse(e.$2).add(const Duration(hours: 10, minutes: 15)), null),
      for (final m in _mine) ('${m['name']}', DateTime.parse('${m['date']}').add(const Duration(hours: 10)), '${m['id']}'),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final upcoming = items.where((e) => e.$2.isAfter(now)).toList();
    final s = AppLook.of(context);
    return ToolList(children: [
      if (upcoming.isNotEmpty)
        BigReadout('${upcoming.first.$2.difference(now).inDays}', unit: L(t, 'days'), caption: upcoming.first.$1),
      for (final e in items)
        AppPanel(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(fmtDate(context, e.$2), style: const TextStyle(color: Colors.white60)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                e.$2.isAfter(now)
                    ? '${e.$2.difference(now).inDays} ${L(t, 'days')} ${e.$2.difference(now).inHours % 24} ${L(t, 'hours')}'
                    : L(t, 'passed'),
                style: TextStyle(color: s.accent, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () async {
                  if (e.$3 != null) {
                    setState(() => _mine.removeWhere((m) => m['id'] == e.$3));
                    await t.store.writeList('mine', _mine);
                  } else {
                    setState(() => _hidden.add(e.$1));
                    await t.store.writeStrings('hidden', _hidden.toList());
                  }
                },
              ),
            ]),
          ),
        ),
      AppButton(label: L(t, 'add_exam'), icon: Icons.add_rounded, onPressed: _add),
      if (_hidden.isNotEmpty)
        TextButton(
          onPressed: () async {
            setState(() => _hidden.clear());
            await t.store.writeStrings('hidden', const []);
          },
          child: Text(L(t, 'show_all')),
        ),
      AppInfoCard('${t.tx('source', {'src': kExamSource})} · ${t.tx('as_of', {'date': kExamAsOf})}\n${L(t, 'exam_note')}'),
    ]);
  }
}

// ------------------------------------------------------------ deneme neti

/// Sınav türü: ad, yanlış oranı, dersler (ad, soru sayısı).
class ExamKind {
  final String name;
  final int ratio;
  final List<(List<String>, int)> parts;
  const ExamKind(this.name, this.ratio, this.parts);
}

const List<ExamKind> kExamKinds = [
  ExamKind('TYT', 4, [
    (['Türkçe', 'Turkish'], 40),
    (['Sosyal Bilimler', 'Social sciences'], 20),
    (['Temel Matematik', 'Basic mathematics'], 40),
    (['Fen Bilimleri', 'Science'], 20),
  ]),
  ExamKind('AYT · Sayısal', 4, [
    (['Matematik', 'Mathematics'], 40),
    (['Fizik', 'Physics'], 14),
    (['Kimya', 'Chemistry'], 13),
    (['Biyoloji', 'Biology'], 13),
  ]),
  ExamKind('AYT · Eşit Ağırlık', 4, [
    (['Matematik', 'Mathematics'], 40),
    (['Türk Dili ve Edebiyatı', 'Turkish literature'], 24),
    (['Tarih-1', 'History-1'], 10),
    (['Coğrafya-1', 'Geography-1'], 6),
  ]),
  ExamKind('AYT · Sözel', 4, [
    (['Türk Dili ve Edebiyatı', 'Turkish literature'], 24),
    (['Tarih-1', 'History-1'], 10),
    (['Coğrafya-1', 'Geography-1'], 6),
    (['Tarih-2', 'History-2'], 11),
    (['Coğrafya-2', 'Geography-2'], 11),
    (['Felsefe Grubu', 'Philosophy group'], 12),
    (['Din Kültürü / ek felsefe', 'Religious culture / extra philosophy'], 6),
  ]),
  ExamKind('YDT', 4, [
    (['Yabancı Dil', 'Foreign language'], 80),
  ]),
  ExamKind('LGS', 3, [
    (['Türkçe', 'Turkish'], 20),
    (['Matematik', 'Mathematics'], 20),
    (['Fen Bilimleri', 'Science'], 20),
    (['T.C. İnkılap Tarihi', 'Revolution history'], 10),
    (['Din Kültürü', 'Religious culture'], 10),
    (['Yabancı Dil', 'Foreign language'], 10),
  ]),
  ExamKind('KPSS · GY-GK', 4, [
    (['Türkçe', 'Turkish'], 30),
    (['Matematik', 'Mathematics'], 30),
    (['Tarih', 'History'], 27),
    (['Coğrafya', 'Geography'], 18),
    (['Vatandaşlık', 'Citizenship'], 9),
    (['Güncel Bilgiler', 'Current affairs'], 6),
  ]),
];

class NetCalcTool extends StatefulWidget {
  final ToolContext t;
  const NetCalcTool(this.t, {super.key});

  @override
  State<NetCalcTool> createState() => _NetCalcToolState();
}

class _NetCalcToolState extends State<NetCalcTool> {
  int _kind = 0;
  final Map<String, TextEditingController> _c = {};

  ToolContext get t => widget.t;

  TextEditingController _ctl(String key) => _c.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _int(String key) => (parseNumber(_ctl(key).text) ?? 0).round().clamp(0, 999);

  @override
  Widget build(BuildContext context) {
    final k = kExamKinds[_kind];
    var total = 0.0;
    var warn = false;
    final rows = <Widget>[];
    for (var i = 0; i < k.parts.length; i++) {
      final (name, q) = k.parts[i];
      final dk = '$_kind.$i.d', yk = '$_kind.$i.y';
      final d = _int(dk), y = _int(yk);
      final over = d + y > q;
      warn = warn || over;
      final net = netScore(d, y, k.ratio);
      total += net;
      rows.add(AppPanel(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${C(t, name)} ($q)', style: const TextStyle(fontWeight: FontWeight.w800))),
            Text('${L(t, 'net')}: ${net.toStringAsFixed(2)}',
                style: TextStyle(color: over ? Colors.redAccent : AppLook.of(context).accent, fontWeight: FontWeight.w800)),
          ]),
          Row(children: [
            Expanded(
                child: AppNumberField(controller: _ctl(dk), label: L(t, 'correct'), decimal: false, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(
                child: AppNumberField(controller: _ctl(yk), label: L(t, 'wrong'), decimal: false, onChanged: (_) => setState(() {}))),
          ]),
        ]),
      ));
    }
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Pick<int>(
          label: L(t, 'exam_type'),
          values: List.generate(kExamKinds.length, (i) => i),
          text: (i) => kExamKinds[i].name,
          value: _kind,
          onChanged: (v) => setState(() => _kind = v),
        ),
      ),
      BigReadout(total.toStringAsFixed(2), caption: L(t, 'total_net')),
      if (warn) AppInfoCard(L(t, 'too_many_answers'), icon: Icons.warning_amber_rounded),
      ...rows,
      AppInfoCard(Lf(t, 'net_rule', {'n': k.ratio})),
      AppInfoCard(L(t, 'net_note')),
    ]);
  }
}

// ------------------------------------------------------------ periyodik tablo

const Map<String, int> kCatColors = {
  'alkali': 0xFFE57373,
  'alkaline': 0xFFFFB74D,
  'transition': 0xFF90A4AE,
  'post': 0xFF80CBC4,
  'metalloid': 0xFFAED581,
  'nonmetal': 0xFF64B5F6,
  'halogen': 0xFFFFF176,
  'noble': 0xFFCE93D8,
  'lanthanide': 0xFFF48FB1,
  'actinide': 0xFFBCAAA4,
};

class PeriodicTableTool extends StatefulWidget {
  final ToolContext t;
  const PeriodicTableTool(this.t, {super.key});

  @override
  State<PeriodicTableTool> createState() => _PeriodicTableToolState();
}

class _PeriodicTableToolState extends State<PeriodicTableTool> {
  int _sel = 26;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final e = kElements[_sel - 1];
    final (g, p) = elementCell(e.z);
    final cat = elementCategory(e.z);
    final cats = Ls(t, 'element_cats');
    const order = ['alkali', 'alkaline', 'transition', 'post', 'metalloid', 'nonmetal', 'halogen', 'noble', 'lanthanide', 'actinide'];
    final q = _q.toLowerCase();
    final match = q.isEmpty
        ? null
        : kElements
            .where((x) => x.symbol.toLowerCase() == q || C(t, x.name).toLowerCase().contains(q) || '${x.z}' == q)
            .map((x) => x.z)
            .toSet();
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: t.tx('search')),
          onChanged: (v) {
            setState(() => _q = v.trim());
            final hit = kElements.where((x) => x.symbol.toLowerCase() == v.trim().toLowerCase()).toList();
            if (hit.isNotEmpty) setState(() => _sel = hit.first.z);
          },
        ),
      ),
      AppPanel(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 18 * 34,
            height: 10 * 38,
            child: Stack(children: [
              for (final x in kElements)
                () {
                  final (gg, pp) = elementCell(x.z);
                  final row = pp >= 8 ? pp + 0.4 : pp.toDouble();
                  final dim = match != null && !match.contains(x.z);
                  return Positioned(
                    left: (gg - 1) * 34,
                    top: (row - 1) * 36,
                    child: GestureDetector(
                      onTap: () => setState(() => _sel = x.z),
                      child: Container(
                        width: 32,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(kCatColors[elementCategory(x.z)]!).withValues(alpha: dim ? 0.15 : 0.85),
                          borderRadius: BorderRadius.circular(5),
                          border: x.z == _sel ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        // Büyük yazıda hücreye sığsın diye küçülür.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('${x.z}', style: const TextStyle(fontSize: 8, color: Colors.black87)),
                            Text(x.symbol, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                          ]),
                        ),
                      ),
                    ),
                  );
                }(),
            ]),
          ),
        ),
      ),
      AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Color(kCatColors[cat]!), borderRadius: BorderRadius.circular(12)),
              child: Text(e.symbol, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(C(t, e.name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(cats[order.indexOf(cat)], style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          AppResult(label: L(t, 'atomic_number'), value: '${e.z}', lang: t.lang),
          AppResult(label: L(t, 'atomic_mass'), value: e.mass, lang: t.lang),
          AppResult(label: L(t, 'group'), value: p >= 8 ? '3 (f)' : '$g', lang: t.lang),
          AppResult(label: L(t, 'period'), value: p >= 8 ? '${p - 2}' : '$p', lang: t.lang),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < order.length; i++)
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: CircleAvatar(backgroundColor: Color(kCatColors[order[i]]!), radius: 6),
              label: Text(cats[i], style: const TextStyle(fontSize: 12)),
            ),
        ]),
      ),
    ]);
  }
}

// ------------------------------------------------------------ formül kitabı

class FormulaTool extends StatefulWidget {
  final ToolContext t;
  const FormulaTool(this.t, {super.key});

  @override
  State<FormulaTool> createState() => _FormulaToolState();
}

class _FormulaToolState extends State<FormulaTool> {
  int _cat = 0;
  int? _open;
  final Map<String, TextEditingController> _c = {};

  TextEditingController _ctl(String k) => _c.putIfAbsent(k, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final cats = Ls(t, 'formula_cats');
    final list = [for (var i = 0; i < kFormulas.length; i++) if (kFormulas[i].cat == _cat) i];
    return ToolList(children: [
      Choice<int>(
        values: List.generate(cats.length, (i) => i),
        labels: cats,
        selected: _cat,
        onChanged: (v) => setState(() {
          _cat = v;
          _open = null;
        }),
      ),
      for (final i in list)
        () {
          final f = kFormulas[i];
          final vals = [for (var j = 0; j < f.vars.length; j++) parseNumber(_ctl('$i.$j').text)];
          double? res;
          if (vals.every((v) => v != null)) {
            final r = f.calc([for (final v in vals) v!]);
            if (r.isFinite) res = r;
          }
          return AppPanel(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              InkWell(
                onTap: () => setState(() => _open = _open == i ? null : i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(C(t, f.title), style: const TextStyle(color: Colors.white70)),
                        Text(f.expr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    Icon(_open == i ? Icons.expand_less_rounded : Icons.calculate_rounded),
                  ]),
                ),
              ),
              if (_open == i) ...[
                for (var j = 0; j < f.vars.length; j++)
                  AppNumberField(
                    controller: _ctl('$i.$j'),
                    label: '${f.vars[j].sym} · ${C(t, f.vars[j].name)}',
                    suffix: f.vars[j].unit,
                    signed: true,
                    onChanged: (_) => setState(() {}),
                  ),
                AppResult(
                  label: '${f.result.sym} · ${C(t, f.result.name)}',
                  value: res == null ? '—' : '${formatNumber(res, digits: 4)} ${f.result.unit}'.trim(),
                  lang: t.lang,
                  big: true,
                ),
              ],
            ]),
          );
        }(),
    ]);
  }
}
