/// Bahçe planlayıcı: yataklar, bitki aralıkları, ekim ayları ve komşu
/// bitki uyumu.
library;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../data/garden.dart';

/// Yataklar arasındaki kötü komşulukları bulur (aynı bahçede).
List<(String, String)> badPairs(List<String> cropIds) {
  final out = <(String, String)>[];
  final set = cropIds.toSet().toList();
  for (var i = 0; i < set.length; i++) {
    for (var j = i + 1; j < set.length; j++) {
      final a = cropById(set[i]), b = cropById(set[j]);
      if (a.bad.contains(b.id) || b.bad.contains(a.id)) out.add((a.id, b.id));
    }
  }
  return out;
}

class GardenTool extends StatefulWidget {
  final ToolContext t;
  const GardenTool(this.t, {super.key});

  @override
  State<GardenTool> createState() => _GardenToolState();
}

class _GardenToolState extends State<GardenTool> {
  List<Map<String, Object?>> _beds = [];
  bool _loaded = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.readList('beds').then((b) {
      if (mounted) setState(() {
        _beds = b;
        _loaded = true;
      });
    });
  }

  Future<void> _save() => t.store.writeList('beds', _beds);

  Future<void> _edit([Map<String, Object?>? bed]) async {
    var crop = '${bed?['crop'] ?? kCrops.first.id}';
    final w = TextEditingController(text: '${bed?['w'] ?? 120}');
    final l = TextEditingController(text: '${bed?['l'] ?? 300}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Pick<String>(
                label: L(t, 'plant'),
                values: [for (final c in kCrops) c.id],
                text: (id) => C(t, cropById(id).name),
                value: crop,
                onChanged: (v) => set(() => crop = v),
              ),
              AppNumberField(controller: w, label: L(t, 'bed_width'), suffix: 'cm'),
              AppNumberField(controller: l, label: L(t, 'bed_length'), suffix: 'cm'),
            ]),
          ),
          actions: [
            if (bed != null)
              TextButton(onPressed: () => Navigator.pop(d, null), child: Text(L(t, 'cancel'))),
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(bed == null ? L(t, 'cancel') : L(t, 'delete'))),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(L(t, 'save'))),
          ],
        ),
      ),
    );
    final wv = parseNumber(w.text), lv = parseNumber(l.text);
    w.dispose();
    l.dispose();
    if (ok == null) return;
    setState(() {
      if (ok == false) {
        if (bed != null) _beds.removeWhere((b) => b['id'] == bed['id']);
        return;
      }
      final m = {'id': bed?['id'] ?? newId(), 'crop': crop, 'w': (wv ?? 100).clamp(10, 10000), 'l': (lv ?? 100).clamp(10, 10000)};
      final i = _beds.indexWhere((b) => b['id'] == m['id']);
      if (i >= 0) {
        _beds[i] = m;
      } else {
        _beds.add(m);
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final month = DateTime.now().month;
    final bad = badPairs([for (final b in _beds) '${b['crop']}']);
    final sowNow = kCrops.where((c) => c.months.contains(month)).toList();
    return ToolList(children: [
      AppButton(label: L(t, 'add_bed'), icon: Icons.add_rounded, onPressed: () => _edit()),
      for (final (a, b) in bad)
        AppInfoCard(Lf(t, 'bad_neighbors', {'a': C(t, cropById(a).name), 'b': C(t, cropById(b).name)}), icon: Icons.warning_amber_rounded),
      for (final bed in _beds)
        () {
          final c = cropById('${bed['crop']}');
          final w = (bed['w'] as num).toDouble(), l = (bed['l'] as num).toDouble();
          return AppPanel(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: () => _edit(bed),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(C(t, c.name), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  Text('${w.round()} × ${l.round()} cm', style: const TextStyle(color: Colors.white60)),
                ]),
                AppResult(label: L(t, 'plants_fit'), value: '${plantsFit(c, w, l)}', lang: t.lang, big: true),
                Text('${L(t, 'spacing')}: ${c.inRow} × ${c.betweenRows} cm · ${L(t, 'harvest_days')}: ~${c.days}',
                    style: const TextStyle(color: Colors.white70)),
                Text('${L(t, 'sow_months')}: ${c.months.map((m) => monthName(context, m)).join(', ')}',
                    style: const TextStyle(color: Colors.white70)),
                if (c.good.isNotEmpty)
                  Text('${L(t, 'good_neighbors')}: ${c.good.map((g) => C(t, cropById(g).name)).join(', ')}',
                      style: const TextStyle(color: Colors.lightGreenAccent)),
                if (c.bad.isNotEmpty)
                  Text('${L(t, 'avoid_neighbors')}: ${c.bad.map((g) => C(t, cropById(g).name)).join(', ')}',
                      style: const TextStyle(color: Colors.orangeAccent)),
              ]),
            ),
          );
        }(),
      if (_beds.isEmpty) AppInfoCard(L(t, 'empty_list'), icon: Icons.yard_rounded),
      AppHeading('${L(t, 'sow_this_month')} · ${monthName(context, month)}', icon: Icons.calendar_month_rounded),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 6, runSpacing: 6, children: [for (final c in sowNow) Chip(label: Text(C(t, c.name)))]),
      ),
      AppInfoCard(L(t, 'garden_note')),
    ]);
  }
}
