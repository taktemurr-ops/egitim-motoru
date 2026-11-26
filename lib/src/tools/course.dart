/// 33 dilde adım adım dil kursu: üniteler (selamlaşma, sayılar, renkler …,
/// günlük ifadeler), kısa dersler, anlam/karşılık seçme ve ifade kurma
/// alıştırmaları, aralıklı tekrar (SM-2), günlük seri ve XP. Kelimeler ve
/// ifadeler mevcut 33 dilli veriden gelir; seslendirme cihazın TTS motoruyla.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../data/phrases.dart';
import '../ek4_core.dart';
import '../learn_core.dart';
import '../speech.dart';

enum _Screen { home, intro, exercise, done }

class CourseTool extends StatefulWidget {
  final ToolContext t;
  const CourseTool(this.t, {super.key});

  @override
  State<CourseTool> createState() => _CourseState();
}

class _CourseState extends State<CourseTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  final List<CourseUnit> _units = buildCourse();

  int _learn = 1, _know = 0;
  int _xp = 0, _streak = 0;
  String? _last;
  bool _sound = true;
  Map<String, Object?> _prog = {}; // dil kodu → {'done': [...], 'srs': {...}}

  _Screen _screen = _Screen.home;
  List<CourseItem> _items = const [];
  String? _lessonKey; // null: tekrar oturumu
  List<(CourseItem, ExKind?)> _queue = [];
  int _qi = 0;
  Exercise? _ex;
  int? _picked;
  final List<int> _built = [];
  bool? _ok;
  final Set<String> _missed = {};
  final Set<String> _requeued = {};
  int _gained = 0;

  String get _lc => kLangCodes[_learn];

  @override
  void initState() {
    super.initState();
    _know = math.max(0, kLangCodes.indexOf(t.lang));
    _learn = _know == 1 ? 0 : 1;
    unawaited(() async {
      final m = await t.store.readMap('course');
      if (!mounted) return;
      setState(() {
        _learn = ((m['learn'] as num?)?.toInt() ?? _learn).clamp(0, 32);
        _know = ((m['know'] as num?)?.toInt() ?? _know).clamp(0, 32);
        _xp = (m['xp'] as num?)?.toInt() ?? 0;
        _streak = (m['streak'] as num?)?.toInt() ?? 0;
        _last = m['last'] is String ? m['last'] as String : null;
        _sound = m['sound'] != false;
        final p = m['p'];
        if (p is Map) _prog = {for (final e in p.entries) '${e.key}': e.value};
      });
    }());
  }

  @override
  void dispose() {
    unawaited(Speaker.instance.stop());
    super.dispose();
  }

  void _persist() => unawaited(t.store.writeMap('course', {
        'learn': _learn, 'know': _know, 'xp': _xp, 'streak': _streak, 'last': _last, 'sound': _sound, 'p': _prog,
      }));

  Map<String, Object?> get _langProg {
    final v = _prog[_lc];
    if (v is Map) return {for (final e in v.entries) '${e.key}': e.value};
    return {};
  }

  Set<String> get _done {
    final d = _langProg['done'];
    return d is List ? d.whereType<String>().toSet() : <String>{};
  }

  Map<String, CardState> get _srs {
    final s = _langProg['srs'];
    final out = <String, CardState>{};
    if (s is Map) {
      for (final e in s.entries) {
        final c = cardFromJson(e.value);
        if (c != null) out['${e.key}'] = c;
      }
    }
    return out;
  }

  void _saveLang(Set<String> done, Map<String, CardState> srs) {
    _prog[_lc] = {'done': done.toList(), 'srs': {for (final e in srs.entries) e.key: cardToJson(e.value)}};
  }

  List<CourseItem> get _allItems => [for (final u in _units) for (final l in u.lessons) ...l];

  List<CourseItem> _due() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final srs = _srs;
    return [for (final it in _allItems) if (srs[it.id] != null && !srs[it.id]!.due.isAfter(today)) it];
  }

  Future<void> _say(String text) async {
    if (!_sound) return;
    final ok = await Speaker.instance.speak(text, _lc);
    if (!ok && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(L(t, 'course_no_voice')), duration: const Duration(seconds: 2)));
    }
  }

  // ------------------------------------------------------------ oturum

  void _openLesson(int u, int l) {
    final items = _units[u].lessons[l];
    final earlier = <CourseItem>[
      for (var i = 0; i <= u; i++)
        for (var j = 0; j < _units[i].lessons.length; j++)
          if (i < u || j < l) ..._units[i].lessons[j],
    ];
    setState(() {
      _items = items;
      _lessonKey = '$u-$l';
      _queue = lessonQueue(_rnd, items, earlier.length > 40 ? earlier.sublist(earlier.length - 40) : earlier);
      _screen = _Screen.intro;
      _resetSession();
    });
  }

  void _openReview() {
    final due = _due()..shuffle(_rnd);
    final items = due.take(15).toList();
    if (items.isEmpty) return;
    setState(() {
      _items = items;
      _lessonKey = null;
      _queue = [for (final it in items) (it, null)];
      _resetSession();
      _screen = _Screen.exercise;
      _nextExercise(first: true);
    });
  }

  void _resetSession() {
    _qi = 0;
    _missed.clear();
    _requeued.clear();
    _gained = 0;
    _ex = null;
  }

  List<CourseItem> get _pool {
    // Çeldiriciler: aynı ünitedeki ve kursun tüm öğeleri.
    final all = _allItems;
    return [..._items, ...all];
  }

  void _nextExercise({bool first = false}) {
    if (!first) _qi++;
    _picked = null;
    _built.clear();
    _ok = null;
    if (_qi >= _queue.length) {
      _finish();
      return;
    }
    final (item, kind) = _queue[_qi];
    _ex = makeExercise(_rnd, item, _pool, _learn, _know, kind: kind);
    if (_ex!.kind == ExKind.meaning) unawaited(_say(item.text[_learn]));
  }

  void _answer(bool ok) {
    final ex = _ex;
    if (ex == null) return;
    setState(() {
      _ok = ok;
      if (ok) {
        _gained += 10;
      } else {
        _missed.add(ex.item.id);
        if (_requeued.add(ex.item.id)) _queue.add((ex.item, null));
      }
    });
    if (ex.kind != ExKind.meaning) unawaited(_say(ex.item.text[_learn]));
  }

  void _finish() {
    final now = DateTime.now();
    final done = _done;
    final srs = _srs;
    for (final it in _items) {
      final q = _missed.contains(it.id) ? (_lessonKey == null ? 2 : 3) : 5;
      srs[it.id] = sm2(srs[it.id] ?? CardState(due: now), q, now);
    }
    final key = _lessonKey;
    if (key != null) done.add(key);
    _saveLang(done, srs);
    _xp += _gained;
    _streak = bumpStreak(_streak, _last, now);
    _last = isoDay(now);
    _screen = _Screen.done;
    _persist();
  }

  // ------------------------------------------------------------ ekranlar

  Widget _langPickers() => Row(children: [
        Expanded(
          child: Pick<int>(
            label: L(t, 'learn_lang'),
            values: List<int>.generate(33, (i) => i),
            text: (i) => kLangNames[i],
            value: _learn,
            onChanged: (i) {
              setState(() => _learn = i);
              _persist();
            },
          ),
        ),
        IconButton(
          tooltip: L(t, 'swap'),
          icon: const Icon(Icons.swap_horiz_rounded),
          onPressed: () {
            setState(() {
              final x = _learn;
              _learn = _know;
              _know = x;
            });
            _persist();
          },
        ),
        Expanded(
          child: Pick<int>(
            label: L(t, 'know_lang'),
            values: List<int>.generate(33, (i) => i),
            text: (i) => kLangNames[i],
            value: _know,
            onChanged: (i) {
              setState(() => _know = i);
              _persist();
            },
          ),
        ),
      ]);

  String _unitTitle(CourseUnit u) {
    final key = unitLabelKey(u.cat);
    if (key == 'phrase_cats') {
      final names = Ls(t, 'phrase_cats');
      return names[phraseCatOf(u.cat).clamp(0, names.length - 1)].trim();
    }
    return L(t, key);
  }

  Widget _home() {
    final s = AppLook.of(context);
    final done = _done;
    final dueN = _due().length;
    final learned = _srs.length;
    // Sıradaki ders: ilk bitmemiş.
    String? next;
    outer:
    for (var u = 0; u < _units.length; u++) {
      for (var l = 0; l < _units[u].lessons.length; l++) {
        if (!done.contains('$u-$l')) {
          next = '$u-$l';
          break outer;
        }
      }
    }
    var lessonNo = 0;
    return ToolList(children: [
      _langPickers(),
      if (_learn == _know) AppInfoCard(L(t, 'course_same_lang'), icon: Icons.warning_amber_rounded),
      AppPanel(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat('🔥', Lf(t, 'course_streak', {'n': _streak})),
          _stat('⭐', '$_xp XP'),
          _stat('📚', Lf(t, 'course_learned', {'n': learned})),
        ]),
      ),
      if (dueN > 0)
        AppButton(label: Lf(t, 'course_review_n', {'n': math.min(dueN, 15)}), icon: Icons.replay_rounded, onPressed: _learn == _know ? null : _openReview)
      else if (learned > 0)
        AppInfoCard(L(t, 'all_done_today'), icon: Icons.check_circle_outline_rounded),
      SwitchListTile(
        value: _sound,
        secondary: const Icon(Icons.volume_up_rounded),
        title: Text(L(t, 'course_sound')),
        onChanged: (v) {
          setState(() => _sound = v);
          _persist();
        },
      ),
      for (var u = 0; u < _units.length; u++) ...[
        AppHeading('${_units[u].lessons.first.first.emoji}  ${_unitTitle(_units[u])}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (var l = 0; l < _units[u].lessons.length; l++)
              () {
                lessonNo++;
                final key = '$u-$l';
                final isDone = done.contains(key);
                final isNext = key == next;
                final locked = !isDone && !isNext;
                return ActionChip(
                  avatar: Icon(isDone ? Icons.check_circle_rounded : (locked ? Icons.lock_rounded : Icons.play_circle_fill_rounded),
                      size: 20, color: isDone ? Colors.greenAccent : (locked ? Colors.white38 : s.accent)),
                  label: Text(Lf(t, 'course_lesson', {'n': lessonNo})),
                  onPressed: () {
                    if (_learn == _know) return;
                    if (locked) {
                      ScaffoldMessenger.maybeOf(context)
                          ?.showSnackBar(SnackBar(content: Text(L(t, 'course_locked')), duration: const Duration(seconds: 2)));
                      return;
                    }
                    _openLesson(u, l);
                  },
                );
              }(),
          ]),
        ),
      ],
      AppInfoCard(L(t, 'course_note'), icon: Icons.info_outline_rounded),
    ]);
  }

  Widget _stat(String icon, String text) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);

  Widget _progressBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: L(t, 'cancel'),
            onPressed: () => setState(() => _screen = _Screen.home),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(minHeight: 10, value: _queue.isEmpty ? 0 : _qi / _queue.length),
            ),
          ),
        ]),
      );

  Widget _intro() => ToolList(children: [
        _progressBar(),
        AppHeading(L(t, 'course_new'), icon: Icons.fiber_new_rounded),
        for (final it in _items)
          Card(
            child: ListTile(
              leading: Text(it.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(it.text[_learn], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              subtitle: Text(it.text[_know]),
              trailing: IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                tooltip: L(t, 'course_sound'),
                onPressed: () => unawaited(Speaker.instance.speak(it.text[_learn], _lc)),
              ),
            ),
          ),
        AppButton(
          label: L(t, 'course_start'),
          icon: Icons.play_arrow_rounded,
          onPressed: () => setState(() {
            _screen = _Screen.exercise;
            _nextExercise(first: true);
          }),
        ),
      ]);

  Widget _exercise() {
    final ex = _ex;
    if (ex == null) return const SizedBox.shrink();
    final item = ex.item;
    final answered = _ok != null;
    final children = <Widget>[_progressBar()];
    switch (ex.kind) {
      case ExKind.meaning:
        children.addAll([
          AppHeading(L(t, 'course_meaning'), icon: Icons.help_outline_rounded),
          AppPanel(
            child: Column(children: [
              if (answered && !item.phrase) Text(item.emoji, style: const TextStyle(fontSize: 44)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: Text(item.text[_learn], textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ),
                IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: () => unawaited(Speaker.instance.speak(item.text[_learn], _lc))),
              ]),
            ]),
          ),
          for (var i = 0; i < ex.options.length; i++) _option(ex, i, ex.options[i].text[_know]),
        ]);
      case ExKind.word:
        children.addAll([
          AppHeading(L(t, 'course_word'), icon: Icons.translate_rounded),
          AppPanel(
            child: Column(children: [
              if (!item.phrase) Text(item.emoji, style: const TextStyle(fontSize: 44)),
              Text(item.text[_know], textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
          ),
          for (var i = 0; i < ex.options.length; i++) _option(ex, i, ex.options[i].text[_learn]),
        ]);
      case ExKind.build:
        final s = AppLook.of(context);
        children.addAll([
          AppHeading(L(t, 'course_build'), icon: Icons.extension_rounded),
          AppPanel(child: Text(item.text[_know], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: s.accent, width: 2))),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final i in _built)
                  ActionChip(
                    label: Text(ex.tokens[i], style: const TextStyle(fontSize: 17)),
                    onPressed: answered ? null : () => setState(() => _built.remove(i)),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < ex.tokens.length; i++)
                if (!_built.contains(i))
                  ActionChip(
                    label: Text(ex.tokens[i], style: const TextStyle(fontSize: 17)),
                    onPressed: answered ? null : () => setState(() => _built.add(i)),
                  ),
            ]),
          ),
          if (!answered)
            AppButton(
              label: L(t, 'check'),
              icon: Icons.check_rounded,
              onPressed: _built.length == ex.tokens.length
                  ? () => _answer(buildCorrect([for (final i in _built) ex.tokens[i]], item, _learn))
                  : null,
            ),
        ]);
    }
    if (answered) {
      children.addAll([
        AppPanel(
          child: Row(children: [
            Icon(_ok! ? Icons.check_circle_rounded : Icons.cancel_rounded, color: _ok! ? Colors.greenAccent : Colors.redAccent, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(L(t, _ok! ? 'correct' : 'wrong'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('${item.text[_learn]} — ${item.text[_know]}'),
              ]),
            ),
          ]),
        ),
        AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: () => setState(_nextExercise)),
      ]);
    }
    return ToolList(children: children);
  }

  Widget _option(Exercise ex, int i, String text) {
    final answered = _ok != null;
    final isAnswer = i == ex.answer;
    final color = !answered
        ? Colors.white.withValues(alpha: 0.06)
        : isAnswer
            ? Colors.green.withValues(alpha: 0.35)
            : (i == _picked ? Colors.red.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.06));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: answered
              ? null
              : () {
                  setState(() => _picked = i);
                  _answer(isAnswer);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(text, style: const TextStyle(fontSize: 17)),
          ),
        ),
      ),
    );
  }

  Widget _doneScreen() => ToolList(children: [
        AppPanel(
          child: Column(children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            Text(L(t, 'course_done'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('+$_gained XP · 🔥 ${Lf(t, 'course_streak', {'n': _streak})}', style: const TextStyle(fontSize: 18)),
          ]),
        ),
        AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: () => setState(() => _screen = _Screen.home)),
      ]);

  @override
  Widget build(BuildContext context) => switch (_screen) {
        _Screen.home => _home(),
        _Screen.intro => _intro(),
        _Screen.exercise => _exercise(),
        _Screen.done => _doneScreen(),
      };
}
