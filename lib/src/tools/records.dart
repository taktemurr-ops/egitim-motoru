/// Kayıt tabanlı uygulamaların ortak motoru: alan tanımlarıyla (metin,
/// sayı, tarih, aralık, onay kutusu, seçim) liste, düzenleme, hazır listeler,
/// vade hesabı (aralık / yıllık / son tarih), toplamlar ve isteğe bağlı
/// bildirim. Bitki sulama, ev envanteri, doğum günü, kontrol listeleri,
/// bakım planları, kiler, evcil hayvan, konu takibi ve günlük bu motoru
/// kendi alanlarıyla kullanır.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../platform/notify.dart';

enum FType { text, multiline, number, date, days, check, choice }

class FieldSpec {
  final String key;

  /// Etiket anahtarı (kEgitimL).
  final String label;
  final FType type;

  /// Seçim alanı için etiket anahtarları.
  final List<String> choices;
  final bool optional;
  const FieldSpec(this.key, this.label, this.type, {this.choices = const [], this.optional = true});
}

enum DueMode { none, interval, yearly, expiry }

enum SortMode { insert, due, dateDesc, group }

/// Hazır kayıt: ad (içerik [tr, en]) ve alan değerleri.
class RecordTemplate {
  final List<String> name;
  final Map<String, Object?> values;
  const RecordTemplate(this.name, [this.values = const {}]);
}

class RecordSpec {
  final List<FieldSpec> fields;

  /// Başlık alanı (zorunlu metin).
  final String titleField;
  final DueMode due;
  final String? dateField;
  final String? daysField;

  /// "Yapıldı" düğmesi tarih alanını bugüne çeker (aralık modu).
  final bool canMarkDone;
  final bool notify;

  /// Onay kutusu alanı (kontrol listesi ilerlemesi için).
  final String? checkField;

  /// Durum alanı ve "bitti" değeri (ilerleme için).
  final String? statusField;
  final String? statusDone;
  final String? sumField;
  final String? groupField;
  final SortMode sort;
  final List<RecordTemplate> templates;

  /// Bir kez doldurulan serbest metin alanları (ör. aile planı).
  final List<String> planFields;
  const RecordSpec({
    required this.fields,
    this.titleField = 'name',
    this.due = DueMode.none,
    this.dateField,
    this.daysField,
    this.canMarkDone = false,
    this.notify = false,
    this.checkField,
    this.statusField,
    this.statusDone,
    this.sumField,
    this.groupField,
    this.sort = SortMode.insert,
    this.templates = const [],
    this.planFields = const [],
  });
}

// ------------------------------------------------------------ saf mantık

DateTime? parseDay(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

/// Bir kaydın sıradaki vade tarihi (yoksa null).
DateTime? nextDue(RecordSpec spec, Map<String, Object?> r, DateTime today) {
  final d = spec.dateField == null ? null : parseDay(r[spec.dateField]);
  switch (spec.due) {
    case DueMode.none:
      return null;
    case DueMode.expiry:
      return d;
    case DueMode.interval:
      final n = (r[spec.daysField] as num?)?.toInt() ?? 0;
      if (n <= 0) return null;
      if (d == null) return dayOnly(today);
      return DateTime(d.year, d.month, d.day + n);
    case DueMode.yearly:
      if (d == null) return null;
      return nextAnniversary(d, today);
  }
}

/// [d]'nin [today] ya da sonrasındaki ilk yıldönümü (29 Şubat → 28 Şubat).
DateTime nextAnniversary(DateTime d, DateTime today) {
  DateTime on(int y) {
    final last = DateTime(y, d.month + 1, 0).day;
    return DateTime(y, d.month, d.day > last ? last : d.day);
  }

  final t = dayOnly(today);
  final a = on(t.year);
  return a.isBefore(t) ? on(t.year + 1) : a;
}

/// İlerleme (tamamlanan, toplam) — kontrol ya da durum alanından.
(int, int) progressOf(RecordSpec spec, List<Map<String, Object?>> items) {
  var done = 0;
  for (final r in items) {
    if (spec.checkField != null && r[spec.checkField] == true) done++;
    if (spec.statusField != null && r[spec.statusField] == spec.statusDone) done++;
  }
  return (done, items.length);
}

double sumOf(RecordSpec spec, List<Map<String, Object?>> items) {
  if (spec.sumField == null) return 0;
  var s = 0.0;
  for (final r in items) {
    s += (r[spec.sumField] as num?)?.toDouble() ?? 0;
  }
  return s;
}

/// Bildirim kimliği (kayıt başına sabit, pozitif 31 bit).
int notifyId(String toolId, String itemId) {
  var h = 17;
  for (final c in '$toolId/$itemId'.codeUnits) {
    h = (h * 31 + c) & 0x3fffffff;
  }
  return h;
}

// ------------------------------------------------------------ arayüz

class RecordsTool extends StatefulWidget {
  final ToolContext t;
  final RecordSpec spec;

  /// Liste üstünde ek bilgi kartı (ör. uyarı).
  final List<Widget> Function(ToolContext t)? header;
  const RecordsTool(this.t, this.spec, {super.key, this.header});

  @override
  State<RecordsTool> createState() => _RecordsToolState();
}

class _RecordsToolState extends State<RecordsTool> {
  List<Map<String, Object?>> _items = [];
  Map<String, Object?> _plan = {};
  bool _notify = false;
  bool _loaded = false;

  ToolContext get t => widget.t;
  RecordSpec get spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await t.store.readList('items');
    final plan = await t.store.readMap('plan');
    final n = await t.store.readBool('notify');
    if (!mounted) return;
    setState(() {
      _items = items;
      _plan = plan;
      _notify = n;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await t.store.writeList('items', _items);
    if (spec.notify && _notify) await _reschedule();
  }

  Future<void> _reschedule() async {
    if (!Notify.supported) return;
    final now = DateTime.now();
    for (final r in _items) {
      final id = notifyId(t.toolId, '${r['id']}');
      await Notify.cancel(id);
      final due = nextDue(spec, r, now);
      if (due == null) continue;
      var at = DateTime(due.year, due.month, due.day, 9);
      if (!at.isAfter(now)) continue;
      await Notify.schedule(id, '${r[spec.titleField]}', dueText(t, daysBetween(now, due)), at);
    }
  }

  Future<void> _setNotify(bool v) async {
    if (v) {
      if (!await rationaleOnce(context, t, 'notify', Icons.notifications_active_rounded)) return;
      await Notify.requestPermission();
    } else {
      for (final r in _items) {
        await Notify.cancel(notifyId(t.toolId, '${r['id']}'));
      }
    }
    setState(() => _notify = v);
    await t.store.writeBool('notify', v);
    if (v) await _reschedule();
  }

  String _fieldText(BuildContext context, FieldSpec f, Object? v) {
    if (v == null || (v is String && v.isEmpty)) return '';
    switch (f.type) {
      case FType.date:
        final d = parseDay(v);
        return d == null ? '' : fmtDate(context, d);
      case FType.number:
        return formatNumber((v as num).toDouble(), digits: 2);
      case FType.days:
        return '${(v as num).toInt()} ${L(t, 'days')}';
      case FType.choice:
        return L(t, '$v');
      case FType.check:
        return '';
      case FType.text:
      case FType.multiline:
        return '$v';
    }
  }

  List<Map<String, Object?>> _sorted() {
    final list = [..._items];
    final now = DateTime.now();
    switch (spec.sort) {
      case SortMode.insert:
        break;
      case SortMode.due:
        list.sort((a, b) {
          final x = nextDue(spec, a, now), y = nextDue(spec, b, now);
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return x.compareTo(y);
        });
      case SortMode.dateDesc:
        list.sort((a, b) => '${b[spec.dateField]}'.compareTo('${a[spec.dateField]}'));
      case SortMode.group:
        list.sort((a, b) => '${a[spec.groupField] ?? ''}'.toLowerCase().compareTo('${b[spec.groupField] ?? ''}'.toLowerCase()));
    }
    return list;
  }

  Future<void> _edit([Map<String, Object?>? item]) async {
    final r = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _RecordForm(t: t, spec: spec, initial: item),
    );
    if (r == null) return;
    setState(() {
      if (r['__delete'] == true) {
        _items.removeWhere((e) => e['id'] == item?['id']);
        unawaited(Notify.cancel(notifyId(t.toolId, '${item?['id']}')));
      } else if (item == null) {
        _items.add({...r, 'id': newId()});
      } else {
        final i = _items.indexWhere((e) => e['id'] == item['id']);
        if (i >= 0) _items[i] = {...r, 'id': item['id']};
      }
    });
    await _save();
  }

  Future<void> _addTemplates() async {
    final chosen = <int>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(L(t, 'templates')),
          content: SizedBox(
            width: 420,
            child: ListView(shrinkWrap: true, children: [
              for (var i = 0; i < spec.templates.length; i++)
                CheckboxListTile(
                  dense: true,
                  value: chosen.contains(i),
                  title: Text(C(t, spec.templates[i].name)),
                  onChanged: (v) => set(() => v == true ? chosen.add(i) : chosen.remove(i)),
                ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => set(() => chosen.length == spec.templates.length
                  ? chosen.clear()
                  : chosen.addAll(List.generate(spec.templates.length, (i) => i))),
              child: Text(L(t, 'select_all')),
            ),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(L(t, 'add'))),
          ],
        ),
      ),
    );
    if (ok != true || chosen.isEmpty) return;
    final base = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      for (final i in chosen.toList()..sort()) {
        final tp = spec.templates[i];
        _items.add({spec.titleField: C(t, tp.name), ...tp.values, 'id': (base + i).toRadixString(36)});
      }
    });
    await _save();
  }

  Widget _dueBadge(DateTime due) {
    final n = daysBetween(DateTime.now(), due);
    final color = n < 0 ? Colors.redAccent : (n <= 3 ? Colors.amberAccent : Colors.white70);
    final text = spec.due == DueMode.expiry && n < 0 ? L(t, 'expired') : dueText(t, n);
    return Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800));
  }

  Widget _tile(BuildContext context, Map<String, Object?> r) {
    final now = DateTime.now();
    final due = nextDue(spec, r, now);
    final parts = <String>[];
    for (final f in spec.fields) {
      if (f.key == spec.titleField || f.key == spec.groupField && spec.sort == SortMode.group) continue;
      final s = _fieldText(context, f, r[f.key]);
      if (s.isNotEmpty) parts.add(f.type == FType.multiline ? s : '${L(t, f.label)}: $s');
    }
    final checked = spec.checkField != null && r[spec.checkField] == true;
    final extra = spec.due == DueMode.yearly && parseDay(r[spec.dateField]) != null && due != null
        ? ' · ${Lf(t, 'turns_age', {'n': due.year - parseDay(r[spec.dateField])!.year})}'
        : '';
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 6),
        onTap: () => _edit(r),
        leading: spec.checkField == null
            ? null
            : Checkbox(
                value: checked,
                onChanged: (v) {
                  final i = _items.indexWhere((e) => e['id'] == r['id']);
                  setState(() => _items[i] = {...r, spec.checkField!: v == true});
                  unawaited(_save());
                },
              ),
        title: Text('${r[spec.titleField] ?? ''}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? Colors.white54 : Colors.white,
            )),
        subtitle: parts.isEmpty && extra.isEmpty
            ? null
            : Text(parts.join('\n') + extra, style: const TextStyle(color: Colors.white60)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (due != null) _dueBadge(due),
          if (spec.canMarkDone)
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                final i = _items.indexWhere((e) => e['id'] == r['id']);
                setState(() => _items[i] = {...r, spec.dateField!: isoDay(DateTime.now())});
                unawaited(_save());
              },
              child: Text(L(t, 'mark_done')),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final list = _sorted();
    final (done, total) = progressOf(spec, _items);
    final hasProgress = spec.checkField != null || spec.statusField != null;
    final children = <Widget>[
      ...?widget.header?.call(t),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: AppButton(label: L(t, 'add'), icon: Icons.add_rounded, onPressed: () => _edit())),
          if (spec.templates.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.playlist_add_rounded),
                label: Text(L(t, 'templates')),
                onPressed: _addTemplates,
              ),
            ),
          ],
        ]),
      ),
      if (hasProgress && total > 0)
        AppPanel(
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(Lf(t, 'progress', {'a': done, 'b': total}), style: const TextStyle(fontWeight: FontWeight.w800))),
              if (spec.checkField != null && done > 0)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _items = [for (final r in _items) {...r, spec.checkField!: false}];
                    });
                    unawaited(_save());
                  },
                  child: Text(L(t, 'uncheck_all')),
                ),
            ]),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: done / total, minHeight: 8, borderRadius: BorderRadius.circular(8)),
          ]),
        ),
      if (spec.sumField != null && _items.isNotEmpty)
        AppPanel(
          child: AppResult(
            label: '${L(t, 'total')} · ${L(t, spec.fields.firstWhere((f) => f.key == spec.sumField).label)}',
            value: formatNumber(sumOf(spec, _items), digits: 2),
            lang: t.lang,
            big: true,
          ),
        ),
      if (spec.notify)
        AppPanel(
          child: Notify.supported
              ? SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_rounded),
                  title: Text(L(t, 'reminders')),
                  subtitle: Text(L(t, 'reminders_note'), style: const TextStyle(color: Colors.white60)),
                  value: _notify,
                  onChanged: _setNotify,
                )
              : Text(L(t, 'reminders_web'), style: const TextStyle(color: Colors.white70)),
        ),
      if (spec.planFields.isNotEmpty) _PlanPanel(t: t, keys: spec.planFields, values: _plan),
      if (list.isEmpty) AppInfoCard(L(t, 'empty_list'), icon: Icons.inbox_rounded),
    ];
    String? group;
    for (final r in list) {
      if (spec.sort == SortMode.group) {
        final f = spec.fields.firstWhere((f) => f.key == spec.groupField);
        final g = _fieldText(context, f, r[spec.groupField]);
        if (g != group) {
          group = g;
          children.add(AppHeading(g.isEmpty ? '—' : g));
        }
      }
      children.add(_tile(context, r));
    }
    return ToolList(children: children);
  }
}

class _PlanPanel extends StatefulWidget {
  final ToolContext t;
  final List<String> keys;
  final Map<String, Object?> values;
  const _PlanPanel({required this.t, required this.keys, required this.values});

  @override
  State<_PlanPanel> createState() => _PlanPanelState();
}

class _PlanPanelState extends State<_PlanPanel> {
  late final Map<String, TextEditingController> _c = {
    for (final k in widget.keys) k: TextEditingController(text: '${widget.values[k] ?? ''}'),
  };
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _persist();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _persist() {
    unawaited(widget.t.store.writeMap('plan', {for (final e in _c.entries) e.key: e.value.text}));
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(L(widget.t, 'family_plan'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        for (final k in widget.keys)
          AppTextField(
            controller: _c[k]!,
            label: L(widget.t, k),
            maxLines: k.endsWith('notes') ? 4 : 1,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 600), _persist);
            },
          ),
      ]),
    );
  }
}

class _RecordForm extends StatefulWidget {
  final ToolContext t;
  final RecordSpec spec;
  final Map<String, Object?>? initial;
  const _RecordForm({required this.t, required this.spec, this.initial});

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final Map<String, TextEditingController> _c = {};
  final Map<String, Object?> _v = {};
  bool _error = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? const {};
    for (final f in widget.spec.fields) {
      final v = init[f.key];
      switch (f.type) {
        case FType.text:
        case FType.multiline:
          _c[f.key] = TextEditingController(text: v == null ? '' : '$v');
        case FType.number:
        case FType.days:
          _c[f.key] = TextEditingController(text: v == null ? '' : formatNumber((v as num).toDouble(), digits: 2));
        case FType.date:
          _v[f.key] = v ?? (f.optional ? null : isoDay(DateTime.now()));
        case FType.check:
          _v[f.key] = v == true;
        case FType.choice:
          _v[f.key] = v ?? f.choices.first;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final out = <String, Object?>{};
    for (final f in widget.spec.fields) {
      switch (f.type) {
        case FType.text:
        case FType.multiline:
          final s = _c[f.key]!.text.trim();
          if (s.isNotEmpty) out[f.key] = s;
        case FType.number:
          final n = parseNumber(_c[f.key]!.text);
          if (n != null && n.isFinite) out[f.key] = n;
        case FType.days:
          final n = parseNumber(_c[f.key]!.text);
          if (n != null && n.isFinite && n > 0) out[f.key] = n.round().clamp(1, 3650);
        case FType.date:
        case FType.check:
        case FType.choice:
          if (_v[f.key] != null) out[f.key] = _v[f.key];
      }
    }
    if ('${out[widget.spec.titleField] ?? ''}'.isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.pop(context, out);
  }

  Widget _field(FieldSpec f) {
    final label = L(t, f.label);
    switch (f.type) {
      case FType.text:
        return AppTextField(controller: _c[f.key]!, label: label);
      case FType.multiline:
        return AppTextField(controller: _c[f.key]!, label: label, maxLines: 5);
      case FType.number:
        return AppNumberField(controller: _c[f.key]!, label: label);
      case FType.days:
        return AppNumberField(controller: _c[f.key]!, label: label, suffix: L(t, 'days'), decimal: false);
      case FType.date:
        final d = parseDay(_v[f.key]);
        return Row(children: [
          Expanded(
            child: d == null
                ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_rounded),
                    title: Text(label),
                    subtitle: const Text('—'),
                    onTap: () async {
                      final p = await showDatePicker(
                          context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2200));
                      if (p != null) setState(() => _v[f.key] = isoDay(p));
                    },
                  )
                : DateRow(label: label, value: d, onChanged: (p) => setState(() => _v[f.key] = isoDay(p))),
          ),
          if (d != null && f.optional)
            IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _v[f.key] = null)),
        ]);
      case FType.check:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: _v[f.key] == true,
          onChanged: (v) => setState(() => _v[f.key] = v),
        );
      case FType.choice:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Choice<String>(
            values: f.choices,
            labels: [for (final c in f.choices) L(t, c)],
            selected: '${_v[f.key]}',
            onChanged: (v) => setState(() => _v[f.key] = v),
          ),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final f in widget.spec.fields) _field(f),
            if (_error) Text(L(t, 'name_required'), style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            Row(children: [
              if (widget.initial != null)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(L(t, 'delete')),
                  onPressed: () async {
                    if (!await confirmDelete(context, t, '${widget.initial![widget.spec.titleField] ?? ''}')) return;
                    if (context.mounted) Navigator.pop(context, {'__delete': true});
                  },
                ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(L(t, 'cancel'))),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: Text(L(t, 'save'))),
            ]),
          ]),
        ),
      ),
    );
  }
}
