/// Dil ve kültür uygulamaları: 33 dilde temel kelimeler, tarih zaman
/// çizelgesi, ehliyet sınavı pratiği (Türkiye, özgün sorular) ve Türkçe
/// dilbilgisi ve yazım. Hepsi çevrimdışıdır.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../data/core_words.dart';
import '../data/ehliyet.dart';
import '../data/phrases.dart';
import '../data/timeline.dart';
import '../data/turkce.dart';
import '../turkce_core.dart';

/// Türkçe içerikli araçlarda, arayüz dili Türkçe değilse gösterilen not.
Widget trContentNote(ToolContext t) =>
    t.lang == 'tr' ? const SizedBox.shrink() : AppInfoCard(L(t, 'content_tr_note'), icon: Icons.translate_rounded);

/// 4 şıklı seçenek düğmesi (doğru/yanlış renklendirmesiyle).
class OptionButton extends StatelessWidget {
  final String text;
  final bool? state; // null: cevaplanmadı, true: doğru, false: yanlış seçildi
  final bool selected;
  final VoidCallback? onTap;
  const OptionButton(this.text, {super.key, this.state, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = state == true
        ? Colors.green.withValues(alpha: 0.35)
        : state == false
            ? Colors.red.withValues(alpha: 0.35)
            : selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
              if (state == true) const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              if (state == false) const Icon(Icons.cancel_rounded, color: Colors.redAccent),
            ]),
          ),
        ),
      ),
    );
  }
}

// =================================================================== kelimeler

/// Kategori kimliği → (etiket anahtarı, simge emojisi).
const Map<String, (String, String)> kVocabCats = {
  'greet': ('vc_greet', '👋'), 'num': ('vc_num', '🔢'), 'time': ('vc_time', '⏰'), 'day': ('vc_day', '📅'),
  'month': ('vc_month', '🗓️'), 'color': ('vc_color', '🎨'), 'shape': ('vc_shape', '🔷'), 'people': ('vc_people', '👪'),
  'body': ('vc_body', '👂'), 'clothes': ('vc_clothes', '👕'), 'food': ('vc_food', '🍞'), 'fruit': ('vc_fruit', '🍎'),
  'animal': ('vc_animal', '🐶'), 'home': ('vc_home', '🏠'), 'nature': ('vc_nature', '🌳'), 'transport': ('vc_transport', '🚗'),
  'place': ('vc_place', '🏫'), 'feel': ('vc_feel', '😊'), 'direction': ('vc_direction', '🧭'),
};

/// Bir kategorinin kelimeleri: (emoji, 33 dilde). Selamlaşma seyahat ifadelerinden gelir.
List<(String, List<String>)> vocabOf(String cat) {
  if (cat == 'greet') return [for (final p in kPhrases.where((p) => p.cat == 0)) ('💬', p.text)];
  return [for (final w in kCoreWords.where((w) => w.cat == cat)) (w.emoji, w.w)];
}

/// Test sorusu: doğru kelime + 3 çeldirici (aynı kategoriden), karışık.
({int answer, List<int> options}) vocabQuestion(int count, int answer, math.Random r) {
  final pool = [for (var i = 0; i < count; i++) if (i != answer) i]..shuffle(r);
  final opts = [answer, ...pool.take(math.min(3, pool.length))]..shuffle(r);
  return (answer: answer, options: opts);
}

class CoreVocabTool extends StatefulWidget {
  final ToolContext t;
  const CoreVocabTool(this.t, {super.key});
  @override
  State<CoreVocabTool> createState() => _CoreVocabState();
}

class _CoreVocabState extends State<CoreVocabTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  int _learn = 1, _know = 0;
  String _cat = 'greet';
  int _mode = 0; // 0 liste, 1 kartlar, 2 test
  Set<String> _known = {};
  int _card = 0;
  bool _flipped = false;
  ({int answer, List<int> options})? _q;
  int? _picked;
  int _score = 0, _asked = 0;

  @override
  void initState() {
    super.initState();
    _know = math.max(0, kLangCodes.indexOf(t.lang));
    _learn = _know == 1 ? 0 : 1;
    () async {
      final m = await t.store.readMap('vocab');
      if (!mounted) return;
      setState(() {
        _learn = ((m['learn'] as num?)?.toInt() ?? _learn).clamp(0, 32);
        _know = ((m['know'] as num?)?.toInt() ?? _know).clamp(0, 32);
        if (m['known'] is List) _known = (m['known'] as List).whereType<String>().toSet();
      });
    }();
  }

  void _persist() => t.store.writeMap('vocab', {'learn': _learn, 'know': _know, 'known': _known.toList()});

  List<(String, List<String>)> get _words => vocabOf(_cat);

  String _key(List<String> w) => '${kLangCodes[_learn]}:${w[1]}';

  void _newQuestion() {
    final ws = _words;
    if (ws.length < 2) return;
    setState(() {
      _q = vocabQuestion(ws.length, _rnd.nextInt(ws.length), _rnd);
      _picked = null;
    });
  }

  void _resetMode() {
    _card = 0;
    _flipped = false;
    _q = null;
    _picked = null;
    _score = 0;
    _asked = 0;
    if (_mode == 2) _newQuestion();
  }

  Widget _langPickers() => Row(children: [
        Expanded(
          child: Pick<int>(
            label: L(t, 'learn_lang'),
            values: List<int>.generate(33, (i) => i),
            text: (i) => kLangNames[i],
            value: _learn,
            onChanged: (i) {
              setState(() {
                _learn = i;
                _resetMode();
              });
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
              _resetMode();
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
              setState(() {
                _know = i;
                _resetMode();
              });
              _persist();
            },
          ),
        ),
      ]);

  Widget _list() {
    final ws = _words;
    return Column(children: [
      for (final w in ws)
        Card(
          child: ListTile(
            leading: Text(w.$1, style: const TextStyle(fontSize: 28)),
            title: Text(w.$2[_learn], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            subtitle: Text(w.$2[_know]),
            trailing: IconButton(
              icon: Icon(_known.contains(_key(w.$2)) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: _known.contains(_key(w.$2)) ? Colors.greenAccent : Colors.white38),
              tooltip: L(t, 'known'),
              onPressed: () {
                setState(() => _known.contains(_key(w.$2)) ? _known.remove(_key(w.$2)) : _known.add(_key(w.$2)));
                _persist();
              },
            ),
          ),
        ),
    ]);
  }

  Widget _cards() {
    final ws = _words;
    if (ws.isEmpty) return const SizedBox.shrink();
    final w = ws[_card % ws.length];
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _flipped = !_flipped),
        child: AppPanel(
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(w.$1, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(_flipped ? w.$2[_know] : w.$2[_learn],
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(_flipped ? kLangNames[_know] : L(t, 'tap_to_flip'), style: const TextStyle(color: Colors.white54)),
            ]),
          ),
        ),
      ),
      Text('${_card % ws.length + 1} / ${ws.length}', style: const TextStyle(color: Colors.white60)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.replay_rounded),
          label: Text(L(t, 'not_yet')),
          onPressed: () => setState(() {
            _known.remove(_key(w.$2));
            _card++;
            _flipped = false;
            _persist();
          }),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          icon: const Icon(Icons.check_rounded),
          label: Text(L(t, 'known')),
          onPressed: () => setState(() {
            _known.add(_key(w.$2));
            _card++;
            _flipped = false;
            _persist();
          }),
        ),
      ]),
    ]);
  }

  Widget _quiz() {
    final ws = _words;
    final q = _q;
    if (q == null || ws.length < 2) return const SizedBox.shrink();
    final w = ws[q.answer];
    return Column(children: [
      AppPanel(
        child: Column(children: [
          Text(w.$1, style: const TextStyle(fontSize: 48)),
          Text(w.$2[_learn], textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ]),
      ),
      for (final o in q.options)
        OptionButton(
          ws[o].$2[_know],
          state: _picked == null ? null : (o == q.answer ? true : (o == _picked ? false : null)),
          onTap: _picked != null
              ? null
              : () {
                  setState(() {
                    _picked = o;
                    _asked++;
                    if (o == q.answer) {
                      _score++;
                      _known.add(_key(w.$2));
                    }
                  });
                  _persist();
                },
        ),
      Text('${L(t, 'score')}: $_score / $_asked', style: const TextStyle(fontSize: 16)),
      if (_picked != null) AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: _newQuestion),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final knownHere = _words.where((w) => _known.contains(_key(w.$2))).length;
    return ToolList(children: [
      _langPickers(),
      SizedBox(
        height: 48,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final e in kVocabCats.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: Text('${e.value.$2} ${L(t, e.value.$1)}'),
                selected: _cat == e.key,
                onSelected: (_) => setState(() {
                  _cat = e.key;
                  _resetMode();
                }),
              ),
            ),
        ]),
      ),
      Choice<int>(
        values: const [0, 1, 2],
        labels: [L(t, 'mode_list'), L(t, 'mode_cards'), L(t, 'quiz')],
        selected: _mode,
        onChanged: (m) => setState(() {
          _mode = m;
          _resetMode();
        }),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: LinearProgressIndicator(value: _words.isEmpty ? 0 : knownHere / _words.length),
      ),
      Text('${L(t, 'known')}: $knownHere / ${_words.length}', textAlign: TextAlign.center),
      if (_mode == 0) _list() else if (_mode == 1) _cards() else _quiz(),
      AppInfoCard(L(t, 'vocab_note'), icon: Icons.info_outline_rounded),
    ]);
  }
}

// =================================================================== zaman çizelgesi

/// Dönemler: (etiket anahtarı, başlangıç yılı dâhil, bitiş yılı hariç).
const List<(String, int, int)> kEras = [
  ('era_ancient', -100000, 476),
  ('era_medieval', 476, 1453),
  ('era_early_modern', 1453, 1789),
  ('era_modern', 1789, 1945),
  ('era_contemporary', 1945, 100000),
];

const List<String> kKindKeys = ['kind_science', 'kind_exploration', 'kind_invention', 'kind_structure', 'kind_culture', 'kind_history'];
const List<IconData> kKindIcons = [
  Icons.science_rounded, Icons.explore_rounded, Icons.lightbulb_rounded, Icons.account_balance_rounded,
  Icons.emoji_events_rounded, Icons.history_edu_rounded,
];

int eraOf(int year) => kEras.indexWhere((e) => year >= e.$2 && year < e.$3);

/// Yıl metni: MÖ yıllar etiketle ("MÖ 776").
String yearText(ToolContext t, int y) => y < 0 ? Lf(t, 'bce', {'y': -y}) : '$y';

class TimelineTool extends StatefulWidget {
  final ToolContext t;
  const TimelineTool(this.t, {super.key});
  @override
  State<TimelineTool> createState() => _TimelineState();
}

class _TimelineState extends State<TimelineTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  final TextEditingController _search = TextEditingController();
  int _tab = 0;
  int? _era, _kind;
  // test
  int _quizMode = 0; // 0 hangisi önce, 1 yılı tahmin et
  List<int> _pair = [];
  List<int> _yearOpts = [];
  int? _picked;
  int _streak = 0, _best = 0, _score = 0, _asked = 0;

  @override
  void initState() {
    super.initState();
    t.store.readInt('best').then((b) {
      if (mounted) setState(() => _best = b);
    });
    _next();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _next() {
    final n = kTimeline.length;
    setState(() {
      _picked = null;
      if (_quizMode == 0) {
        int a, b;
        do {
          a = _rnd.nextInt(n);
          b = _rnd.nextInt(n);
        } while (kTimeline[a].year == kTimeline[b].year);
        _pair = [a, b];
      } else {
        final i = _rnd.nextInt(n);
        _pair = [i];
        _yearOpts = yearOptions(kTimeline[i].year, _rnd);
      }
    });
  }

  void _answer(int i) {
    if (_picked != null) return;
    final ok = _quizMode == 0
        ? kTimeline[_pair[i]].year == math.min(kTimeline[_pair[0]].year, kTimeline[_pair[1]].year)
        : _yearOpts[i] == kTimeline[_pair[0]].year;
    setState(() {
      _picked = i;
      _asked++;
      if (ok) {
        _score++;
        _streak++;
        if (_streak > _best) {
          _best = _streak;
          t.store.write('best', '$_best');
        }
      } else {
        _streak = 0;
      }
    });
  }

  Widget _event(TimeEvent e, {bool showYear = true}) {
    final now = DateTime.now().year;
    final ago = now - e.year + (e.year < 0 ? -1 : 0); // MÖ 1'den MS 1'e sıfır yılı yok.
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(kKindIcons[e.kind], size: 20)),
        title: Text(t.t(e.text)),
        subtitle: showYear ? Text('${yearText(t, e.year)} · ${Lf(t, 'years_ago', {'n': ago})}') : null,
      ),
    );
  }

  Widget _timeline() {
    final q = trLower(_search.text.trim());
    final list = [
      for (final e in kTimeline)
        if ((_era == null || eraOf(e.year) == _era) &&
            (_kind == null || e.kind == _kind) &&
            (q.isEmpty || trLower(t.t(e.text)).contains(q) || '${e.year}'.contains(q)))
          e,
    ];
    int? lastEra;
    final children = <Widget>[];
    for (final e in list) {
      final era = eraOf(e.year);
      if (era != lastEra) {
        children.add(AppHeading(L(t, kEras[era].$1), icon: Icons.timeline_rounded));
        lastEra = era;
      }
      children.add(_event(e));
    }
    return Column(children: [
      AppTextField(controller: _search, label: L(t, 'search_event'), onChanged: (_) => setState(() {})),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(label: Text(t.tx('all')), selected: _era == null, onSelected: (_) => setState(() => _era = null)),
          ),
          for (var i = 0; i < kEras.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(label: Text(L(t, kEras[i].$1)), selected: _era == i, onSelected: (_) => setState(() => _era = i)),
            ),
        ]),
      ),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(label: Text(t.tx('all')), selected: _kind == null, onSelected: (_) => setState(() => _kind = null)),
          ),
          for (var i = 0; i < kKindKeys.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                avatar: Icon(kKindIcons[i], size: 16),
                label: Text(L(t, kKindKeys[i])),
                selected: _kind == i,
                onSelected: (_) => setState(() => _kind = i),
              ),
            ),
        ]),
      ),
      Text('${list.length} / ${kTimeline.length}', style: const TextStyle(color: Colors.white60)),
      ...children,
    ]);
  }

  Widget _quiz() {
    if (_pair.isEmpty) return const SizedBox.shrink();
    final opts = _quizMode == 0 ? [for (final i in _pair) t.t(kTimeline[i].text)] : [for (final y in _yearOpts) yearText(t, y)];
    final correct = _quizMode == 0
        ? _pair.indexWhere((i) => kTimeline[i].year == math.min(kTimeline[_pair[0]].year, kTimeline[_pair[1]].year))
        : _yearOpts.indexOf(kTimeline[_pair[0]].year);
    return Column(children: [
      Choice<int>(
        values: const [0, 1],
        labels: [L(t, 'which_first'), L(t, 'guess_year')],
        selected: _quizMode,
        onChanged: (m) {
          _quizMode = m;
          _next();
        },
      ),
      AppPanel(
        child: Text(
          _quizMode == 0 ? L(t, 'which_first_q') : t.t(kTimeline[_pair[0]].text),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      for (var i = 0; i < opts.length; i++)
        OptionButton(
          opts[i],
          state: _picked == null ? null : (i == correct ? true : (i == _picked ? false : null)),
          onTap: _picked == null ? () => _answer(i) : null,
        ),
      if (_picked != null && _quizMode == 0)
        for (final i in _pair) _event(kTimeline[i]),
      const SizedBox(height: 8),
      Text('${L(t, 'score')}: $_score / $_asked   ·   ${L(t, 'streak')}: $_streak   ·   ${L(t, 'best')}: $_best',
          textAlign: TextAlign.center),
      if (_picked != null) AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: _next),
    ]);
  }

  @override
  Widget build(BuildContext context) => ToolList(children: [
        Choice<int>(
          values: const [0, 1],
          labels: [L(t, 'timeline'), L(t, 'quiz')],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (_tab == 0) _timeline() else _quiz(),
        AppInfoCard(L(t, 'timeline_note'), icon: Icons.info_outline_rounded),
      ]);
}

/// "Yılı tahmin et" için 4 seçenek: doğru yıl ve yakın ama farklı yıllar.
List<int> yearOptions(int year, math.Random r) {
  final spread = year < 0 ? 400 : (year < 1500 ? 150 : (year < 1900 ? 40 : 15));
  final set = <int>{year};
  var guard = 0;
  while (set.length < 4 && guard++ < 200) {
    var d = (r.nextInt(spread * 2) - spread);
    if (d == 0) d = spread ~/ 3 + 1;
    final y = year + d;
    if (year > 0 && y > DateTime.now().year) continue;
    if (y == 0) continue;
    set.add(y);
  }
  return set.toList()..shuffle(r);
}

// =================================================================== ehliyet

/// Konu dağılımına göre karışık deneme sınavı (soru sırası karışık).
List<int> buildExam(math.Random r, {List<int> mix = kExamMix}) {
  final out = <int>[];
  for (var c = 0; c < mix.length; c++) {
    final pool = [for (var i = 0; i < kExamQuestions.length; i++) if (kExamQuestions[i].cat == c) i]..shuffle(r);
    out.addAll(pool.take(mix[c]));
  }
  return out..shuffle(r);
}

/// Puan: her doğru 100/soru sayısı; geçme 70.
int examScore(int correct, int total) => total == 0 ? 0 : (correct * 100 / total).round();

const int kPassScore = 70;
const int kExamMinutes = 45;

class DrivingExamTool extends StatefulWidget {
  final ToolContext t;
  const DrivingExamTool(this.t, {super.key});
  @override
  State<DrivingExamTool> createState() => _DrivingExamState();
}

class _DrivingExamState extends State<DrivingExamTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  Set<int> _wrong = {};
  int _exams = 0, _best = 0, _last = -1;

  @override
  void initState() {
    super.initState();
    () async {
      final m = await t.store.readMap('ehliyet');
      if (!mounted) return;
      setState(() {
        if (m['wrong'] is List) _wrong = (m['wrong'] as List).whereType<num>().map((e) => e.toInt()).where((i) => i < kExamQuestions.length).toSet();
        _exams = (m['exams'] as num?)?.toInt() ?? 0;
        _best = (m['best'] as num?)?.toInt() ?? 0;
        _last = (m['last'] as num?)?.toInt() ?? -1;
      });
    }();
  }

  void _persist() => t.store.writeMap('ehliyet', {'wrong': _wrong.toList(), 'exams': _exams, 'best': _best, 'last': _last});

  Future<void> _run(List<int> qs, {required bool exam}) async {
    if (qs.isEmpty) return;
    final res = await Navigator.of(context).push<Map<int, int>>(MaterialPageRoute<Map<int, int>>(
      builder: (_) => _ExamPage(t: t, questions: qs, exam: exam),
    ));
    if (res == null || !mounted) return;
    setState(() {
      for (final q in qs) {
        final a = res[q];
        if (a == null) continue;
        if (a == kExamQuestions[q].answer) {
          _wrong.remove(q);
        } else {
          _wrong.add(q);
        }
      }
      if (exam) {
        final correct = qs.where((q) => res[q] == kExamQuestions[q].answer).length;
        _last = examScore(correct, qs.length);
        _exams++;
        if (_last > _best) _best = _last;
      }
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['cat_firstaid', 'cat_traffic', 'cat_engine', 'cat_manners'];
    return ToolList(children: [
      AppPanel(
        child: Column(children: [
          Text(L(t, 'exam_mode'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(Lf(t, 'exam_info', {'n': 50, 'm': kExamMinutes, 'p': kPassScore}), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          AppButton(label: L(t, 'start'), icon: Icons.play_arrow_rounded, onPressed: () => _run(buildExam(_rnd), exam: true)),
          if (_exams > 0)
            Text('${L(t, 'exams_taken')}: $_exams · ${L(t, 'best')}: $_best · ${L(t, 'last_score')}: $_last',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ]),
      ),
      AppHeading(L(t, 'study_topic'), icon: Icons.menu_book_rounded),
      for (var c = 0; c < cats.length; c++)
        Card(
          child: ListTile(
            leading: Icon([Icons.medical_services_rounded, Icons.traffic_rounded, Icons.build_rounded, Icons.handshake_rounded][c]),
            title: Text(L(t, cats[c])),
            subtitle: Text('${kExamQuestions.where((q) => q.cat == c).length}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _run(
              [for (var i = 0; i < kExamQuestions.length; i++) if (kExamQuestions[i].cat == c) i]..shuffle(_rnd),
              exam: false,
            ),
          ),
        ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline_rounded),
          title: Text(L(t, 'my_mistakes')),
          subtitle: Text('${_wrong.length}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _wrong.isEmpty ? null : () => _run(_wrong.toList()..shuffle(_rnd), exam: false),
        ),
      ),
      trContentNote(t),
      AppInfoCard(Lf(t, 'ehliyet_note', {'date': kEhliyetReviewed}), icon: Icons.update_rounded),
    ]);
  }
}

class _ExamPage extends StatefulWidget {
  final ToolContext t;
  final List<int> questions;
  final bool exam;
  const _ExamPage({required this.t, required this.questions, required this.exam});
  @override
  State<_ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<_ExamPage> {
  ToolContext get t => widget.t;
  final Map<int, int> _answers = {};
  int _i = 0;
  bool _finished = false;
  Timer? _timer;
  late DateTime _end;
  late final List<List<int>> _order; // her soru için karışık şık sırası

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _order = [for (var k = 0; k < widget.questions.length; k++) [0, 1, 2, 3]..shuffle(r)];
    _end = DateTime.now().add(const Duration(minutes: kExamMinutes));
    if (widget.exam) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (DateTime.now().isAfter(_end)) {
          _finish();
        } else {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    _timer?.cancel();
    setState(() => _finished = true);
  }

  int get _correct => widget.questions.where((q) => _answers[q] == kExamQuestions[q].answer).length;

  Widget _question(int k, {bool review = false}) {
    final qi = widget.questions[k];
    final q = kExamQuestions[qi];
    final picked = _answers[qi];
    final reveal = review || (!widget.exam && picked != null);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppPanel(child: Text(q.q, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      for (var j = 0; j < 4; j++)
        Builder(builder: (_) {
          final o = _order[k][j];
          bool? state;
          if (reveal) state = o == q.answer ? true : (o == picked ? false : null);
          return OptionButton(
            '${'ABCD'[j]}) ${q.options[o]}',
            state: state,
            selected: !reveal && picked == o,
            onTap: reveal || _finished ? null : () => setState(() => _answers[qi] = o),
          );
        }),
      if (reveal) AppInfoCard(q.why, icon: Icons.lightbulb_outline_rounded),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.questions.length;
    final left = _end.difference(DateTime.now());
    return PopScope<Map<int, int>>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _answers);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context, _answers)),
          title: Text(_finished ? L(t, 'results') : Lf(t, 'question_n', {'n': _i + 1, 't': n})),
          actions: [
            if (widget.exam && !_finished)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        body: _finished ? _results() : _running(n),
      ),
    );
  }

  Widget _running(int n) => ToolList(children: [
        LinearProgressIndicator(value: (_i + 1) / n),
        _question(_i),
        Row(children: [
          if (_i > 0)
            OutlinedButton.icon(onPressed: () => setState(() => _i--), icon: const Icon(Icons.arrow_back_rounded), label: Text(L(t, 'back'))),
          const Spacer(),
          if (_i < n - 1)
            FilledButton.icon(onPressed: () => setState(() => _i++), icon: const Icon(Icons.arrow_forward_rounded), label: Text(L(t, 'next')))
          else
            FilledButton.icon(onPressed: _finish, icon: const Icon(Icons.flag_rounded), label: Text(L(t, 'finish'))),
        ]),
        if (widget.exam && _i < n - 1)
          Center(child: TextButton(onPressed: _finish, child: Text(L(t, 'finish')))),
        if (widget.exam)
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var k = 0; k < n; k++)
              InkWell(
                onTap: () => setState(() => _i = k),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _answers.containsKey(widget.questions[k]) ? Colors.white24 : Colors.white10,
                    border: Border.all(color: k == _i ? Colors.white : Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${k + 1}', style: const TextStyle(fontSize: 12)),
                ),
              ),
          ]),
      ]);

  Widget _results() {
    final n = widget.questions.length;
    final correct = _correct;
    final answered = widget.questions.where(_answers.containsKey).length;
    final score = examScore(correct, n);
    final passed = score >= kPassScore;
    return ToolList(children: [
      if (widget.exam)
        AppPanel(
          child: Column(children: [
            Icon(passed ? Icons.verified_rounded : Icons.replay_rounded, size: 56, color: passed ? Colors.greenAccent : Colors.orangeAccent),
            Text('$score', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900)),
            Text(L(t, passed ? 'passed' : 'not_passed'), style: const TextStyle(fontSize: 18)),
          ]),
        ),
      Text('${L(t, 'correct')}: $correct · ${L(t, 'wrong')}: ${answered - correct} · ${L(t, 'empty')}: ${n - answered}',
          textAlign: TextAlign.center),
      AppButton(label: L(t, 'done'), icon: Icons.check_rounded, onPressed: () => Navigator.pop(context, _answers)),
      AppHeading(L(t, 'review'), icon: Icons.fact_check_rounded),
      for (var k = 0; k < n; k++)
        if (_answers[widget.questions[k]] != kExamQuestions[widget.questions[k]].answer) _question(k, review: true),
    ]);
  }
}

// =================================================================== Türkçe

class TurkishGrammarTool extends StatefulWidget {
  final ToolContext t;
  const TurkishGrammarTool(this.t, {super.key});
  @override
  State<TurkishGrammarTool> createState() => _TurkishGrammarState();
}

class _TurkishGrammarState extends State<TurkishGrammarTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  final TextEditingController _word = TextEditingController(text: 'kitap');
  final TextEditingController _text = TextEditingController();
  int _tab = 0;
  // test
  int _qType = 0; // 0 sözcük yazımı, 1 cümle
  List<String> _opts = [];
  int _correctIdx = 0;
  String _why = '';
  int? _picked;
  int _score = 0, _asked = 0;
  late final List<(String, String)> _pairs = spellingPairs();

  @override
  void initState() {
    super.initState();
    _nextQ();
  }

  @override
  void dispose() {
    _word.dispose();
    _text.dispose();
    super.dispose();
  }

  void _nextQ() {
    setState(() {
      _picked = null;
      _qType = _rnd.nextInt(2);
      if (_qType == 0) {
        final p = _pairs[_rnd.nextInt(_pairs.length)];
        _opts = [p.$1, p.$2]..shuffle(_rnd);
        _correctIdx = _opts.indexOf(p.$1);
        _why = '';
      } else {
        final s = kSentencePairs[_rnd.nextInt(kSentencePairs.length)];
        _opts = [s.$1, s.$2]..shuffle(_rnd);
        _correctIdx = _opts.indexOf(s.$1);
        _why = s.$3;
      }
    });
  }

  Widget _rules() => Column(children: [
        for (final g in kGrammarTopics)
          Card(
            child: ExpansionTile(
              title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.body),
                const SizedBox(height: 8),
                for (final e in g.examples) Text('• $e', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
      ]);

  Widget _suffixes() {
    final w = _word.text.trim();
    final rows = <(String, Suffix)>[
      ('sf_plural', Suffix.plural), ('sf_accusative', Suffix.accusative), ('sf_dative', Suffix.dative),
      ('sf_locative', Suffix.locative), ('sf_ablative', Suffix.ablative), ('sf_genitive', Suffix.genitive),
      ('sf_possessive', Suffix.possessive1), ('sf_with', Suffix.instrumental),
    ];
    final syl = syllables(w);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(controller: _word, label: L(t, 'enter_word'), onChanged: (_) => setState(() {})),
      if (w.isNotEmpty) ...[
        AppPanel(
          child: Column(children: [
            for (final r in rows) AppResult(label: L(t, r.$1), value: addSuffix(w, r.$2), lang: t.lang),
          ]),
        ),
        AppHeading(L(t, 'syllables_harmony'), icon: Icons.segment_rounded),
        AppPanel(
          child: Column(children: [
            AppResult(label: L(t, 'syllables'), value: '${syl.join(' - ')} (${syl.length})', lang: t.lang),
            AppResult(label: L(t, 'vowels'), value: vowelsOf(w).join(', '), lang: t.lang),
            AppResult(label: L(t, 'big_harmony'), value: bigHarmony(w) ? '✓' : '✗', lang: t.lang),
            AppResult(label: L(t, 'small_harmony'), value: smallHarmony(w) ? '✓' : '✗', lang: t.lang),
          ]),
        ),
        AppInfoCard(L(t, 'suffix_note'), icon: Icons.info_outline_rounded),
      ],
    ]);
  }

  Widget _spell() {
    final issues = spellIssues(_text.text);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(controller: _text, label: L(t, 'paste_text'), maxLines: 6, onChanged: (_) => setState(() {})),
      if (_text.text.trim().isNotEmpty)
        if (issues.isEmpty)
          AppInfoCard(L(t, 'no_spell_issues'), icon: Icons.check_circle_outline_rounded)
        else ...[
          Text(Lf(t, 'spell_found', {'n': issues.length}), style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final i in issues)
            Card(
              child: ListTile(
                leading: const Icon(Icons.spellcheck_rounded),
                title: Text.rich(TextSpan(children: [
                  TextSpan(text: i.$1, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent)),
                  const TextSpan(text: '  →  '),
                  TextSpan(text: i.$2, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700)),
                ])),
              ),
            ),
          AppButton(
            label: L(t, 'fix_all'),
            icon: Icons.auto_fix_high_rounded,
            onPressed: () {
              var s = _text.text;
              for (final i in issues.reversed) {
                s = s.replaceRange(i.$3, i.$3 + i.$1.length, i.$2);
              }
              setState(() => _text.text = s);
            },
          ),
        ],
      AppInfoCard(L(t, 'spell_note'), icon: Icons.info_outline_rounded),
    ]);
  }

  Widget _quiz() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppPanel(child: Text(L(t, 'which_correct'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        for (var i = 0; i < _opts.length; i++)
          OptionButton(
            _opts[i],
            state: _picked == null ? null : (i == _correctIdx ? true : (i == _picked ? false : null)),
            onTap: _picked != null
                ? null
                : () => setState(() {
                      _picked = i;
                      _asked++;
                      if (i == _correctIdx) _score++;
                    }),
          ),
        if (_picked != null && _why.isNotEmpty) AppInfoCard(_why, icon: Icons.lightbulb_outline_rounded),
        Text('${L(t, 'score')}: $_score / $_asked', textAlign: TextAlign.center),
        if (_picked != null) AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: _nextQ),
      ]);

  @override
  Widget build(BuildContext context) => ToolList(children: [
        trContentNote(t),
        Choice<int>(
          values: const [0, 1, 2, 3],
          labels: [L(t, 'rules'), L(t, 'suffixes'), L(t, 'spell_check'), L(t, 'quiz')],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (_tab == 0) _rules() else if (_tab == 1) _suffixes() else if (_tab == 2) _spell() else _quiz(),
      ]);
}
