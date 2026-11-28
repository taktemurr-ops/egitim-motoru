/// Mutfak: tarif kutusu (app-007'den taşındı: porsiyon ölçekleme, sık
/// kullanılanlar, alışveriş listesi, JSON yedek) ve haftalık yemek
/// planlayıcı (app-008'den taşındı: gün/öğün planı ve birleşik alışveriş
/// listesi). Beslenme hedefi ya da kalori önerisi içermez.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studio_core/app/studio_ui.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';

// ------------------------------------------------------------ model

class Ingredient {
  final String name;
  final double qty;
  final String unit;
  const Ingredient(this.name, this.qty, this.unit);

  Map<String, Object?> toMap() => {'name': name, 'qty': qty, 'unit': unit};
  static Ingredient fromMap(Map<String, Object?> m) =>
      Ingredient('${m['name'] ?? ''}', (m['qty'] as num?)?.toDouble() ?? 0, '${m['unit'] ?? ''}');

  /// "200 g un", "2 yumurta", "un" gibi satırları ayrıştırır.
  static Ingredient parse(String line) {
    final s = line.trim();
    final m = RegExp(r'^([0-9]+(?:[.,][0-9]+)?(?:/[0-9]+)?)\s*([^\s0-9]*)\s+(.+)$').firstMatch(s);
    if (m == null) {
      final only = RegExp(r'^([0-9]+(?:[.,][0-9]+)?)\s+(.+)$').firstMatch(s);
      if (only != null) return Ingredient(only.group(2)!, parseNumber(only.group(1)!) ?? 0, '');
      return Ingredient(s, 0, '');
    }
    var q = 0.0;
    final raw = m.group(1)!;
    if (raw.contains('/')) {
      final p = raw.split('/');
      final a = parseNumber(p[0]) ?? 0, b = parseNumber(p[1]) ?? 1;
      q = b == 0 ? 0 : a / b;
    } else {
      q = parseNumber(raw) ?? 0;
    }
    final unit = m.group(2)!;
    // Birim gibi görünmüyorsa (ör. "2 yumurta") adı birleştir.
    if (unit.length > 6) return Ingredient('$unit ${m.group(3)!}', q, '');
    return Ingredient(m.group(3)!, q, unit);
  }

  String show([double factor = 1]) {
    if (qty <= 0) return name;
    final q = formatNumber(qty * factor, digits: 2);
    return unit.isEmpty ? '$q $name' : '$q $unit $name';
  }
}

class Recipe {
  final String id;
  final String title;
  final int servings;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final List<String> tags;
  final bool favorite;
  const Recipe(this.id, this.title, this.servings, this.ingredients, this.steps, this.tags, {this.favorite = false});

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'servings': servings,
        'ingredients': [for (final i in ingredients) i.toMap()],
        'steps': steps,
        'tags': tags,
        'favorite': favorite,
      };

  static Recipe fromMap(Map<String, Object?> m) => Recipe(
        '${m['id']}',
        '${m['title'] ?? ''}',
        ((m['servings'] as num?)?.toInt() ?? 1).clamp(1, 1000),
        [for (final i in (m['ingredients'] as List? ?? const [])) Ingredient.fromMap(Map<String, Object?>.from(i as Map))],
        [for (final s in (m['steps'] as List? ?? const [])) '$s'],
        [for (final s in (m['tags'] as List? ?? const [])) '$s'],
        favorite: m['favorite'] == true,
      );

  Recipe copyWith({bool? favorite}) => Recipe(id, title, servings, ingredients, steps, tags, favorite: favorite ?? this.favorite);
}

/// Malzemeleri ad+birime göre toplar (büyük/küçük harf duyarsız).
List<Ingredient> aggregate(Iterable<(Ingredient, double)> items) {
  final total = <String, double>{};
  final first = <String, Ingredient>{};
  for (final (i, f) in items) {
    final k = '${i.name.trim().toLowerCase()}|${i.unit.trim().toLowerCase()}';
    total[k] = (total[k] ?? 0) + i.qty * f;
    first.putIfAbsent(k, () => i);
  }
  final keys = total.keys.toList()..sort();
  return [for (final k in keys) Ingredient(first[k]!.name, total[k]!, first[k]!.unit)];
}

/// JSON yedeği (app-007 ile uyumlu sürüm alanı).
String exportRecipes(List<Recipe> list) => jsonEncode({'schemaVersion': 2, 'recipes': [for (final r in list) r.toMap()]});

List<Recipe> importRecipes(String source) {
  if (source.length > 2000000) throw const FormatException('too large');
  final data = jsonDecode(source);
  if (data is! Map || data['recipes'] is! List) throw const FormatException('format');
  final out = <Recipe>[];
  for (final raw in data['recipes'] as List) {
    final m = Map<String, Object?>.from(raw as Map);
    // app-007 biçimi: quantity alanı
    final ing = [
      for (final i in (m['ingredients'] as List? ?? const []))
        () {
          final x = Map<String, Object?>.from(i as Map);
          return {'name': x['name'], 'qty': x['qty'] ?? x['quantity'], 'unit': x['unit']};
        }(),
    ];
    final r = Recipe.fromMap({...m, 'ingredients': ing});
    if (r.title.trim().isEmpty) continue;
    out.add(r);
  }
  return out;
}

// ------------------------------------------------------------ tarif kutusu

class RecipeTool extends StatefulWidget {
  final ToolContext t;
  const RecipeTool(this.t, {super.key});

  @override
  State<RecipeTool> createState() => _RecipeToolState();
}

class _RecipeToolState extends State<RecipeTool> {
  List<Recipe> _list = [];
  bool _loaded = false;
  String _q = '';
  bool _favOnly = false;
  final Set<String> _cart = {};

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.readList('recipes').then((l) {
      if (mounted) setState(() {
        _list = l.map(Recipe.fromMap).toList();
        _loaded = true;
      });
    });
  }

  Future<void> _save() => t.store.writeList('recipes', [for (final r in _list) r.toMap()]);

  Future<void> _edit([Recipe? r]) async {
    final out = await Navigator.of(context).push<Recipe>(MaterialPageRoute(builder: (_) => _RecipeEditor(t: t, initial: r)));
    if (out == null) return;
    setState(() {
      final i = _list.indexWhere((x) => x.id == out.id);
      if (i >= 0) {
        _list[i] = out;
      } else {
        _list.add(out);
      }
    });
    await _save();
  }

  Future<void> _view(Recipe r) async {
    var serv = r.servings;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(c).size.height * 0.85,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text(r.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              if (r.tags.isNotEmpty) Wrap(spacing: 6, children: [for (final g in r.tags) Chip(label: Text(g))]),
              Row(children: [
                Text('${L(t, 'servings')}: $serv', style: const TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: serv > 1 ? () => set(() => serv--) : null, icon: const Icon(Icons.remove_circle_outline)),
                IconButton(onPressed: serv < 100 ? () => set(() => serv++) : null, icon: const Icon(Icons.add_circle_outline)),
              ]),
              Text(L(t, 'ingredient'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              for (final i in r.ingredients) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• ${i.show(serv / r.servings)}')),
              const SizedBox(height: 12),
              Text(L(t, 'steps'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              for (var k = 0; k < r.steps.length; k++)
                Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${k + 1}. ${r.steps[k]}', style: const TextStyle(height: 1.4))),
              const SizedBox(height: 12),
              Row(children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(L(t, 'edit')),
                  onPressed: () {
                    Navigator.pop(c);
                    _edit(r);
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(L(t, 'delete')),
                  onPressed: () async {
                    if (!await confirmDelete(c, t, r.title)) return;
                    setState(() {
                      _list.removeWhere((x) => x.id == r.id);
                      _cart.remove(r.id);
                    });
                    await _save();
                    if (c.mounted) Navigator.pop(c);
                  },
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _shopping() {
    final items = aggregate([
      for (final r in _list.where((r) => _cart.contains(r.id)))
        for (final i in r.ingredients) (i, 1.0),
    ]);
    final text = items.map((i) => '☐ ${i.show()}').join('\n');
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(L(t, 'shopping_list')),
        content: SingleChildScrollView(child: SelectableText(text.isEmpty ? '—' : text)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(d);
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.tx('copied'))));
            },
            child: Text(L(t, 'copy')),
          ),
        ],
      ),
    );
  }

  Future<void> _backup() async {
    final ctl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(L(t, 'backup')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(L(t, 'backup_hint'), style: const TextStyle(color: Colors.white70)),
          AppTextField(controller: ctl, label: 'JSON', maxLines: 4),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportRecipes(_list)));
              Navigator.pop(d);
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.tx('copied'))));
            },
            child: Text(L(t, 'export')),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final got = importRecipes(ctl.text);
                setState(() {
                  for (final r in got) {
                    if (!_list.any((x) => x.id == r.id)) _list.add(r);
                  }
                });
                await _save();
                if (d.mounted) Navigator.pop(d);
              } catch (_) {
                if (d.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(L(t, 'invalid'))));
                }
              }
            },
            child: Text(L(t, 'import')),
          ),
        ],
      ),
    );
    ctl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final q = _q.toLowerCase();
    final list = _list
        .where((r) => !_favOnly || r.favorite)
        .where((r) =>
            q.isEmpty ||
            r.title.toLowerCase().contains(q) ||
            r.tags.any((g) => g.toLowerCase().contains(q)) ||
            r.ingredients.any((i) => i.name.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: AppButton(label: L(t, 'add_recipe'), icon: Icons.add_rounded, onPressed: () => _edit())),
          IconButton(tooltip: L(t, 'backup'), onPressed: _backup, icon: const Icon(Icons.import_export_rounded)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: L(t, 'recipe_search')),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _favOnly = !_favOnly),
            icon: Icon(_favOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _favOnly ? Colors.pinkAccent : null),
          ),
        ]),
      ),
      if (_cart.isNotEmpty)
        AppButton(label: '${L(t, 'shopping_list')} (${_cart.length})', icon: Icons.shopping_cart_rounded, onPressed: _shopping),
      if (list.isEmpty) AppInfoCard(L(t, 'empty_list'), icon: Icons.menu_book_rounded),
      for (final r in list)
        AppPanel(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: ListTile(
            onTap: () => _view(r),
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${r.servings} ${L(t, 'servings').toLowerCase()} · ${r.ingredients.length} ${L(t, 'ingredient').toLowerCase()}',
                style: const TextStyle(color: Colors.white60)),
            leading: IconButton(
              icon: Icon(r.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: r.favorite ? Colors.pinkAccent : null),
              onPressed: () {
                final i = _list.indexWhere((x) => x.id == r.id);
                setState(() => _list[i] = r.copyWith(favorite: !r.favorite));
                unawaited(_save());
              },
            ),
            trailing: Checkbox(
              value: _cart.contains(r.id),
              onChanged: (v) => setState(() => v == true ? _cart.add(r.id) : _cart.remove(r.id)),
            ),
          ),
        ),
    ]);
  }
}

class _RecipeEditor extends StatefulWidget {
  final ToolContext t;
  final Recipe? initial;
  const _RecipeEditor({required this.t, this.initial});

  @override
  State<_RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<_RecipeEditor> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _serv = TextEditingController(text: '${widget.initial?.servings ?? 4}');
  late final _ing = TextEditingController(text: widget.initial?.ingredients.map((i) => i.show()).join('\n') ?? '');
  late final _steps = TextEditingController(text: widget.initial?.steps.join('\n') ?? '');
  late final _tags = TextEditingController(text: widget.initial?.tags.join(', ') ?? '');
  bool _error = false;

  ToolContext get t => widget.t;

  @override
  void dispose() {
    for (final c in [_title, _serv, _ing, _steps, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  void _done() {
    final title = _title.text.trim();
    final ing = _ing.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).map(Ingredient.parse).toList();
    final steps = _steps.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (title.isEmpty || ing.isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.pop(
      context,
      Recipe(
        widget.initial?.id ?? newId(),
        title.length > 120 ? title.substring(0, 120) : title,
        (parseNumber(_serv.text) ?? 1).round().clamp(1, 1000),
        ing.take(100).toList(),
        steps.take(100).toList(),
        _tags.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).take(30).toList(),
        favorite: widget.initial?.favorite ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudioLook.of(context).base,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: StudioTitle(widget.initial == null ? L(t, 'add_recipe') : L(t, 'edit'), icon: Icons.restaurant_menu_rounded),
        actions: [IconButton(onPressed: _done, icon: const Icon(Icons.check_rounded))],
      ),
      body: StudioBackdrop(child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        AppTextField(controller: _title, label: L(t, 'recipe_name')),
        AppNumberField(controller: _serv, label: L(t, 'servings'), decimal: false),
        AppTextField(controller: _ing, label: L(t, 'ingredients_hint'), maxLines: 8),
        AppTextField(controller: _steps, label: L(t, 'steps_hint'), maxLines: 8),
        AppTextField(controller: _tags, label: L(t, 'tags')),
        if (_error) Text(L(t, 'name_required'), style: const TextStyle(color: Colors.redAccent)),
        AppButton(label: L(t, 'save'), icon: Icons.check_rounded, onPressed: _done),
      ]))),
    );
  }
}

// ------------------------------------------------------------ yemek planı

/// Haftanın günleri (pazartesi başlangıç) yyyy-mm-dd.
List<String> weekDays(DateTime anyDay) {
  final d = dayOnly(anyDay);
  final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
  return [for (var i = 0; i < 7; i++) isoDay(DateTime(monday.year, monday.month, monday.day + i))];
}

/// [from] haftasının öğünlerini [to] haftasındaki boş yerlere kopyalar
/// ("yendi" işareti kopyalanmaz). Kopyalanan öğün sayısını döndürür.
int copyWeekPlan(Map<String, Object?> plan, List<String> from, List<String> to, int slots) {
  var n = 0;
  for (var i = 0; i < from.length && i < to.length; i++) {
    for (var s = 0; s < slots; s++) {
      final src = plan['${from[i]}|$s'];
      final key = '${to[i]}|$s';
      if (src is Map && plan[key] == null) {
        plan[key] = {'dish': src['dish'], 'ing': [for (final x in (src['ing'] as List? ?? const [])) '$x']};
        n++;
      }
    }
  }
  return n;
}

class MealPlanTool extends StatefulWidget {
  final ToolContext t;
  const MealPlanTool(this.t, {super.key});

  @override
  State<MealPlanTool> createState() => _MealPlanToolState();
}

class _MealPlanToolState extends State<MealPlanTool> {
  /// 'yyyy-mm-dd|slot' → {dish, ing: [satırlar]}
  Map<String, Object?> _plan = {};
  DateTime _week = DateTime.now();
  bool _loaded = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.readMap('plan').then((m) {
      if (mounted) setState(() {
        _plan = m;
        _loaded = true;
      });
    });
  }

  Future<void> _save() => t.store.writeMap('plan', _plan);

  Map<String, Object?>? _cell(String k) => _plan[k] is Map ? Map<String, Object?>.from(_plan[k] as Map) : null;

  Future<void> _edit(String key) async {
    final cur = _cell(key);
    final dish = TextEditingController(text: '${cur?['dish'] ?? ''}');
    final ing = TextEditingController(text: [for (final s in (cur?['ing'] as List? ?? const [])) '$s'].join('\n'));
    final r = await showDialog<int>(
      context: context,
      builder: (d) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(controller: dish, label: L(t, 'dish')),
            AppTextField(controller: ing, label: L(t, 'ingredients_hint'), maxLines: 5),
          ]),
        ),
        actions: [
          if (cur != null) TextButton(onPressed: () => Navigator.pop(d, 2), child: Text(L(t, 'clear'))),
          TextButton(onPressed: () => Navigator.pop(d, 0), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, 1), child: Text(L(t, 'save'))),
        ],
      ),
    );
    final dv = dish.text.trim();
    final iv = ing.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    dish.dispose();
    ing.dispose();
    if (r == 2) {
      setState(() => _plan.remove(key));
    } else if (r == 1 && dv.isNotEmpty) {
      setState(() => _plan[key] = {'dish': dv, 'ing': iv});
    } else {
      return;
    }
    await _save();
  }

  /// Geçen haftanın öğünlerini bu haftanın boş yerlerine kopyalar.
  Future<void> _copyLastWeek() async {
    final now = weekDays(_week);
    final prev = weekDays(DateTime(_week.year, _week.month, _week.day - 7));
    final n = copyWeekPlan(_plan, prev, now, Ls(t, 'meal_slots').length);
    if (n == 0) return;
    setState(() {});
    await _save();
    if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(L(t, 'plan_copied'))));
  }

  Future<void> _toggleEaten(String key) async {
    final cur = _cell(key);
    if (cur == null) return;
    setState(() => _plan[key] = {...cur, 'eaten': cur['eaten'] != true});
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final days = weekDays(_week);
    final slots = Ls(t, 'meal_slots');
    final loc = MaterialLocalizations.of(context);
    final today = isoDay(DateTime.now());
    final shop = aggregate([
      for (final d in days)
        for (var s = 0; s < slots.length; s++)
          if (_cell('$d|$s')?['eaten'] != true)
            for (final line in (_cell('$d|$s')?['ing'] as List? ?? const [])) (Ingredient.parse('$line'), 1.0),
    ]);
    final shopText = shop.map((i) => '☐ ${i.show()}').join('\n');
    return ToolList(children: [
      Row(children: [
        IconButton(
            icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _week = DateTime(_week.year, _week.month, _week.day - 7))),
        Expanded(
          child: TextButton(
            onPressed: () => setState(() => _week = DateTime.now()),
            child: Text('${fmtDate(context, DateTime.parse(days.first))} – ${fmtDate(context, DateTime.parse(days.last))}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => _week = DateTime(_week.year, _week.month, _week.day + 7))),
      ]),
      for (final d in days)
        AppPanel(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.formatFullDate(DateTime.parse(d)),
                style: TextStyle(fontWeight: FontWeight.w900, color: d == today ? AppLook.of(context).accent : Colors.white)),
            for (var s = 0; s < slots.length; s++)
              InkWell(
                onTap: () => _edit('$d|$s'),
                onLongPress: () => _toggleEaten('$d|$s'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(width: 110, child: Text(slots[s], style: const TextStyle(color: Colors.white60))),
                    Expanded(
                      child: Text('${_cell('$d|$s')?['dish'] ?? '+'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: _cell('$d|$s')?['eaten'] == true ? TextDecoration.lineThrough : null,
                          )),
                    ),
                    if (_cell('$d|$s') != null)
                      IconButton(
                        tooltip: L(t, 'eaten'),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(_cell('$d|$s')?['eaten'] == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20, color: _cell('$d|$s')?['eaten'] == true ? AppLook.of(context).accent : Colors.white38),
                        onPressed: () => _toggleEaten('$d|$s'),
                      ),
                  ]),
                ),
              ),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: AppButton(label: L(t, 'copy_last_week'), icon: Icons.content_copy_rounded, onPressed: _copyLastWeek),
      ),
      AppHeading(L(t, 'shopping_list'), icon: Icons.shopping_cart_rounded),
      AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SelectableText(shopText.isEmpty ? L(t, 'shopping_empty') : shopText),
          if (shopText.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded),
              label: Text(L(t, 'copy')),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shopText));
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.tx('copied'))));
              },
            ),
        ]),
      ),
    ]);
  }
}
