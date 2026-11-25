/// Öğrenme: bilgi kartları (aralıklı tekrar), TR-EN kelime ezberi,
/// çevrimdışı sözlük, matematik pratiği, klavye eğitimi, hızlı okuma ve
/// kodlama bulmacaları.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../data/phrases.dart';
import '../data/words.dart';
import '../learn_core.dart';

// ------------------------------------------------------------ kartlar

const int kNewPerDay = 20;

class FlashcardTool extends StatefulWidget {
  final ToolContext t;

  /// Hazır TR-EN sözcük destesiyle başlar (kelime ezberi uygulaması).
  final bool builtinWords;
  const FlashcardTool(this.t, {super.key, this.builtinWords = false});

  @override
  State<FlashcardTool> createState() => _FlashcardToolState();
}

class _FlashcardToolState extends State<FlashcardTool> {
  List<Map<String, Object?>> _cards = [];
  List<String> _decks = [];
  String _deck = '';
  bool _loaded = false;
  bool _studying = false;
  bool _flipped = false;
  int _newToday = 0;
  int _extra = 0;
  final List<String> _queue = [];

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _todayKey => 'new.${isoDay(DateTime.now())}';

  Future<void> _load() async {
    var cards = await t.store.readList('cards');
    var decks = await t.store.readStrings('decks');
    if (widget.builtinWords && cards.isEmpty) {
      // Türkçe konuşana İngilizce, diğerlerine Türkçe öğretir.
      final learnEn = t.lang == 'tr';
      final deck = learnEn ? 'Türkçe → English' : 'Turkish → ${kLangNames[math.max<int>(0, kLangCodes.indexOf(t.lang))]}';
      decks = [deck];
      cards = [
        for (final (i, w) in kWords.indexed)
          {
            'id': 'w$i',
            'deck': deck,
            'front': learnEn ? w.$2 : w.$1,
            'back': learnEn ? w.$1 : w.$2,
          },
      ];
      await t.store.writeList('cards', cards);
      await t.store.writeStrings('decks', decks);
    }
    if (decks.isEmpty) decks = [L(t, 'my_deck')];
    final n = await t.store.readInt(_todayKey);
    final unlocked = await t.unlockedToday('more_cards');
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _decks = decks;
      _deck = decks.first;
      _newToday = n;
      _extra = unlocked ? kNewPerDay : 0;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await t.store.writeList('cards', _cards);
    await t.store.writeStrings('decks', _decks);
  }

  CardState _state(Map<String, Object?> c) => CardState(
        ef: (c['ef'] as num?)?.toDouble() ?? 2.5,
        interval: (c['iv'] as num?)?.toInt() ?? 0,
        reps: (c['reps'] as num?)?.toInt() ?? 0,
        due: DateTime.tryParse('${c['due'] ?? ''}') ?? DateTime(2000),
      );

  bool _isNew(Map<String, Object?> c) => c['due'] == null;

  List<Map<String, Object?>> get _deckCards => _cards.where((c) => c['deck'] == _deck).toList();

  ({int due, int fresh}) _counts() {
    final today = dayOnly(DateTime.now());
    var due = 0, fresh = 0;
    for (final c in _deckCards) {
      if (_isNew(c)) {
        fresh++;
      } else if (!_state(c).due.isAfter(today)) {
        due++;
      }
    }
    return (due: due, fresh: fresh);
  }

  int get _newLeft => math.max<int>(0, kNewPerDay + _extra - _newToday);

  void _start() {
    final today = dayOnly(DateTime.now());
    _queue
      ..clear()
      ..addAll(_deckCards.where((c) => !_isNew(c) && !_state(c).due.isAfter(today)).map((c) => '${c['id']}'))
      ..addAll(_deckCards.where(_isNew).take(_newLeft).map((c) => '${c['id']}'));
    _queue.shuffle();
    setState(() {
      _studying = _queue.isNotEmpty;
      _flipped = false;
    });
  }

  Future<void> _grade(int q) async {
    final id = _queue.removeAt(0);
    final i = _cards.indexWhere((c) => c['id'] == id);
    if (i < 0) return;
    final c = _cards[i];
    if (_isNew(c)) {
      _newToday++;
      await t.store.write(_todayKey, '$_newToday');
    }
    final s = sm2(_state(c), q, DateTime.now());
    _cards[i] = {...c, 'ef': s.ef, 'iv': s.interval, 'reps': s.reps, 'due': isoDay(s.due)};
    if (q < 3) _queue.add(id); // aynı oturumda yeniden
    setState(() {
      _flipped = false;
      if (_queue.isEmpty) _studying = false;
    });
    await _save();
  }

  Future<void> _addCard([Map<String, Object?>? edit]) async {
    final f = TextEditingController(text: '${edit?['front'] ?? ''}');
    final b = TextEditingController(text: '${edit?['back'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          AppTextField(controller: f, label: L(t, 'front'), maxLines: 3),
          AppTextField(controller: b, label: L(t, 'back'), maxLines: 3),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(L(t, 'save'))),
        ],
      ),
    );
    final front = f.text.trim(), back = b.text.trim();
    f.dispose();
    b.dispose();
    if (ok != true || front.isEmpty || back.isEmpty) return;
    setState(() {
      if (edit == null) {
        _cards.add({'id': newId(), 'deck': _deck, 'front': front, 'back': back});
      } else {
        final i = _cards.indexWhere((c) => c['id'] == edit['id']);
        if (i >= 0) _cards[i] = {..._cards[i], 'front': front, 'back': back};
      }
    });
    await _save();
  }

  Future<void> _newDeck() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: L(t, 'deck'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(L(t, 'save'))),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty || _decks.contains(name)) return;
    setState(() {
      _decks.add(name);
      _deck = name;
    });
    await _save();
  }

  Widget _study(BuildContext context) {
    final c = _cards.firstWhere((x) => x['id'] == _queue.first);
    final s = AppLook.of(context);
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(Lf(t, 'cards_left', {'n': _queue.length}), style: const TextStyle(color: Colors.white70)),
      ),
      GestureDetector(
        onTap: () => setState(() => _flipped = !_flipped),
        child: AppPanel(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${c['front']}',
                    textAlign: TextAlign.center, style: TextStyle(color: s.number, fontSize: 30, fontWeight: FontWeight.w900)),
                if (_flipped) ...[
                  const Divider(height: 32),
                  Text('${c['back']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                ] else ...[
                  const SizedBox(height: 18),
                  Text(L(t, 'tap_to_flip'), style: const TextStyle(color: Colors.white54)),
                ],
              ]),
            ),
          ),
        ),
      ),
      if (_flipped)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            for (final (q, key, color) in [
              (1, 'again', Colors.redAccent),
              (3, 'hard', Colors.orangeAccent),
              (4, 'good', Colors.lightGreenAccent),
              (5, 'easy', Colors.cyanAccent),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: color, side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => _grade(q),
                    child: Text(L(t, key), textAlign: TextAlign.center),
                  ),
                ),
              ),
          ]),
        ),
      TextButton(onPressed: () => setState(() => _studying = false), child: Text(L(t, 'stop'))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_studying && _queue.isNotEmpty) return _study(context);
    final cnt = _counts();
    final list = _deckCards;
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: Pick<String>(
              label: L(t, 'deck'),
              values: _decks,
              text: (s) => s,
              value: _deck,
              onChanged: (v) => setState(() => _deck = v),
            ),
          ),
          IconButton(tooltip: L(t, 'add'), icon: const Icon(Icons.create_new_folder_rounded), onPressed: _newDeck),
        ]),
      ),
      AppPanel(
        child: Column(children: [
          AppResult(label: L(t, 'due_cards'), value: '${cnt.due}', lang: t.lang, big: true),
          AppResult(label: L(t, 'new_cards'), value: '${math.min<int>(cnt.fresh, _newLeft)} / ${cnt.fresh}', lang: t.lang),
          AppResult(label: L(t, 'total'), value: '${list.length}', lang: t.lang),
        ]),
      ),
      if (cnt.due + math.min<int>(cnt.fresh, _newLeft) > 0)
        AppButton(label: L(t, 'study'), icon: Icons.school_rounded, onPressed: _start)
      else
        AppInfoCard(list.isEmpty ? L(t, 'empty_list') : L(t, 'all_done_today'), icon: Icons.celebration_rounded),
      if (_newLeft == 0 && cnt.fresh > 0 && _extra == 0)
        UnlockCard(t: t, feature: 'more_cards', onUnlocked: () => setState(() => _extra = kNewPerDay)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(onPressed: () => _addCard(), icon: const Icon(Icons.add_rounded), label: Text(L(t, 'add_card'))),
      ),
      for (final c in list.reversed.take(60))
        ListTile(
          dense: true,
          title: Text('${c['front']}'),
          subtitle: Text('${c['back']}', style: const TextStyle(color: Colors.white60)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: () async {
              if (!await confirmDelete(context, t, '${c['front']}')) return;
              setState(() => _cards.removeWhere((x) => x['id'] == c['id']));
              await _save();
            },
          ),
          onTap: () => _addCard(c),
        ),
      if (list.length > 60) Center(child: Text('… ${list.length - 60}', style: const TextStyle(color: Colors.white54))),
      AppInfoCard(L(t, 'sm2_note')),
    ]);
  }
}

// ------------------------------------------------------------ sözlük

/// Sözlük araması: önce tam eşleşme, sonra başlayan, sonra içeren.
List<(String, String)> searchWords(List<(String, String)> words, String q) {
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return const [];
  int rank((String, String) w) {
    final a = w.$1.toLowerCase(), b = w.$2.toLowerCase();
    if (a == s || b.split(',').map((e) => e.trim()).contains(s)) return 0;
    if (a.startsWith(s) || b.startsWith(s)) return 1;
    if (a.contains(s) || b.contains(s)) return 2;
    return 9;
  }

  final hits = words.where((w) => rank(w) < 9).toList()..sort((x, y) => rank(x).compareTo(rank(y)));
  return hits.take(80).toList();
}

class DictionaryTool extends StatefulWidget {
  final ToolContext t;
  const DictionaryTool(this.t, {super.key});

  @override
  State<DictionaryTool> createState() => _DictionaryToolState();
}

class _DictionaryToolState extends State<DictionaryTool> {
  final _q = TextEditingController();
  List<(String, String)> _mine = [];

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.readList('mine').then((l) {
      if (mounted) setState(() => _mine = [for (final m in l) ('${m['tr']}', '${m['en']}')]);
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final a = TextEditingController(), b = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(L(t, 'add_word')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          AppTextField(controller: a, label: 'Türkçe'),
          AppTextField(controller: b, label: 'English'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(L(t, 'save'))),
        ],
      ),
    );
    final x = a.text.trim(), y = b.text.trim();
    a.dispose();
    b.dispose();
    if (ok != true || x.isEmpty || y.isEmpty) return;
    setState(() => _mine.add((x, y)));
    await t.store.writeList('mine', [for (final m in _mine) {'tr': m.$1, 'en': m.$2}]);
  }

  @override
  Widget build(BuildContext context) {
    final all = [..._mine, ...kWords];
    final hits = searchWords(all, _q.text);
    return ToolList(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _q,
          autofocus: false,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: L(t, 'dict_hint'),
            suffixIcon: _q.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _q.clear())),
          ),
        ),
      ),
      if (_q.text.trim().isEmpty)
        AppInfoCard(Lf(t, 'dict_count', {'n': all.length}), icon: Icons.menu_book_rounded)
      else if (hits.isEmpty)
        AppInfoCard(t.tx('no_results'))
      else
        AppPanel(
          child: Column(children: [
            for (final h in hits)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(h.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                subtitle: Text(h.$2, style: const TextStyle(fontSize: 15, color: Colors.white70)),
              ),
          ]),
        ),
      AppButton(label: L(t, 'add_word'), icon: Icons.add_rounded, onPressed: _add),
      AppInfoCard(L(t, 'dict_note')),
    ]);
  }
}

// ------------------------------------------------------------ matematik

class MathPracticeTool extends StatefulWidget {
  final ToolContext t;
  const MathPracticeTool(this.t, {super.key});

  @override
  State<MathPracticeTool> createState() => _MathPracticeToolState();
}

class _MathPracticeToolState extends State<MathPracticeTool> {
  final _r = math.Random();
  final _answer = TextEditingController();
  final _focus = FocusNode();
  String _op = '?';
  int _level = 1;
  MathQ? _q;
  int _n = 0, _right = 0, _best = 0;
  bool? _last;
  DateTime? _started;
  Duration _time = Duration.zero;
  static const _round = 10;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.readInt('best').then((b) {
      if (mounted) setState(() => _best = b);
    });
  }

  @override
  void dispose() {
    _answer.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _n = 0;
      _right = 0;
      _last = null;
      _started = DateTime.now();
      _q = makeMathQ(_r, _op, _level);
    });
    _answer.clear();
    _focus.requestFocus();
  }

  Future<void> _check() async {
    final q = _q;
    if (q == null) return;
    final v = int.tryParse(_answer.text.trim().replaceAll('−', '-'));
    if (v == null) return;
    final ok = v == q.answer;
    _n++;
    if (ok) _right++;
    _answer.clear();
    if (_n >= _round) {
      _time = DateTime.now().difference(_started!);
      final score = _right * 10 * _level - _time.inSeconds ~/ 5;
      if (score > _best) {
        _best = score;
        await t.store.write('best', '$score');
      }
      setState(() {
        _last = ok;
        _q = null;
      });
      return;
    }
    setState(() {
      _last = ok;
      _q = makeMathQ(_r, _op, _level);
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    if (q == null) {
      return ToolList(children: [
        Choice<String>(
          values: const ['+', '−', '×', '÷', '?'],
          labels: ['+', '−', '×', '÷', L(t, 'mixed')],
          selected: _op,
          onChanged: (v) => setState(() => _op = v),
        ),
        Choice<int>(
          values: const [1, 2, 3],
          labels: Ls(t, 'levels'),
          selected: _level,
          onChanged: (v) => setState(() => _level = v),
        ),
        if (_n >= _round)
          AppPanel(
            child: Column(children: [
              AppResult(label: L(t, 'correct'), value: '$_right / $_round', lang: t.lang, big: true),
              AppResult(label: L(t, 'time'), value: '${_time.inSeconds} s', lang: t.lang),
            ]),
          ),
        AppPanel(child: AppResult(label: L(t, 'best'), value: '$_best', lang: t.lang)),
        AppButton(label: L(t, 'start'), onPressed: _start),
      ]);
    }
    return ToolList(children: [
      LinearProgressIndicator(value: _n / _round, minHeight: 6),
      BigReadout('${q.text} = ?', caption: '${_n + 1} / $_round'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _answer,
          focusNode: _focus,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          onSubmitted: (_) => _check(),
          decoration: InputDecoration(hintText: L(t, 'answer')),
        ),
      ),
      AppButton(label: L(t, 'check'), icon: Icons.check_rounded, onPressed: _check),
      if (_last != null)
        Center(
          child: Icon(_last! ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: _last! ? Colors.greenAccent : Colors.redAccent, size: 40),
        ),
    ]);
  }
}

// ------------------------------------------------------------ metin kaynağı

/// Klavye ve hızlı okuma için örnek metin: Türkçe/İngilizce paragraflar,
/// diğer dillerde seyahat ifadelerinden derlenmiş metin.
String sampleText(String lang, int i) {
  const tr = [
    'Sabah erkenden kalkıp pencereyi açtım. Serin hava odaya doldu ve uzaktan martıların sesi geldi. Kahvemi alıp balkona çıktım; şehir yavaş yavaş uyanıyordu.',
    'Kütüphanede sessizce çalışan öğrenciler, sınav haftasının yaklaştığını biliyordu. Her biri kendi masasında notlarını gözden geçiriyor, arada bir pencereden dışarı bakıyordu.',
    'Bahçedeki domatesler bu yıl erken kızardı. Komşumuz her akşam hortumla sulamaya geliyor, bir yandan da çocuklara bitkilerin nasıl büyüdüğünü anlatıyordu.',
  ];
  const en = [
    'Early in the morning I opened the window. Cool air filled the room and the sound of gulls drifted in from far away. I took my coffee out to the balcony as the city slowly woke up.',
    'The students working quietly in the library knew that exam week was close. Each of them went over their notes at their own desk, now and then glancing out of the window.',
    'The tomatoes in the garden ripened early this year. Our neighbour came every evening to water them, telling the children how the plants grow as he went along.',
  ];
  if (lang == 'tr') return tr[i % tr.length];
  final li = kLangCodes.indexOf(lang);
  if (li <= 1) return en[i % en.length];
  final list = kPhrases.map((p) => p.text[li]).toList();
  final start = (i * 7) % list.length;
  return [for (var k = 0; k < 10; k++) list[(start + k) % list.length]].join(' ');
}

// ------------------------------------------------------------ klavye

class TypingTool extends StatefulWidget {
  final ToolContext t;
  const TypingTool(this.t, {super.key});

  @override
  State<TypingTool> createState() => _TypingToolState();
}

class _TypingToolState extends State<TypingTool> {
  final _input = TextEditingController();
  final _custom = TextEditingController();
  int _idx = 0;
  String _target = '';
  DateTime? _start;
  Duration _elapsed = Duration.zero;
  bool _done = false;
  double _bestWpm = 0;
  Timer? _tick;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _target = sampleText(t.lang, 0);
    t.store.readDouble('best').then((b) {
      if (mounted) setState(() => _bestWpm = b);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _input.dispose();
    _custom.dispose();
    super.dispose();
  }

  void _reset([String? text]) {
    _tick?.cancel();
    setState(() {
      if (text != null) _target = text;
      _input.clear();
      _start = null;
      _elapsed = Duration.zero;
      _done = false;
    });
  }

  void _changed(String v) {
    if (_done) return;
    if (_start == null && v.isNotEmpty) {
      _start = DateTime.now();
      _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted && _start != null && !_done) setState(() => _elapsed = DateTime.now().difference(_start!));
      });
    }
    if (v.length >= _target.length) {
      _tick?.cancel();
      _elapsed = DateTime.now().difference(_start ?? DateTime.now());
      _done = true;
      final s = typingStats(_target, v, _elapsed);
      if (s.accuracy >= 0.9 && s.wpm > _bestWpm) {
        _bestWpm = s.wpm;
        unawaited(t.store.write('best', s.wpm.toStringAsFixed(1)));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typed = _input.text;
    final s = typingStats(_target, typed, _elapsed);
    final accent = AppLook.of(context).accent;
    return ToolList(children: [
      AppPanel(
        child: RichText(
          text: TextSpan(style: const TextStyle(fontSize: 20, height: 1.5, color: Colors.white54), children: [
            for (var i = 0; i < _target.length; i++)
              TextSpan(
                text: _target[i],
                style: TextStyle(
                  color: i < typed.length ? (typed[i] == _target[i] ? Colors.white : Colors.redAccent) : null,
                  backgroundColor: i == typed.length ? accent.withValues(alpha: 0.4) : null,
                  decoration: i < typed.length && typed[i] != _target[i] ? TextDecoration.underline : null,
                ),
              ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _input,
          enabled: !_done,
          maxLines: 3,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: _changed,
          decoration: InputDecoration(hintText: L(t, 'type_here'), border: const OutlineInputBorder()),
        ),
      ),
      AppPanel(
        child: Column(children: [
          AppResult(label: L(t, 'wpm'), value: s.wpm.toStringAsFixed(0), lang: t.lang, big: _done),
          AppResult(label: L(t, 'accuracy_pct'), value: '${(s.accuracy * 100).toStringAsFixed(0)}%', lang: t.lang),
          AppResult(label: L(t, 'errors'), value: '${s.errors}', lang: t.lang),
          AppResult(label: L(t, 'best'), value: _bestWpm.toStringAsFixed(0), lang: t.lang),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(L(t, 'reset')),
            onPressed: () => _reset(),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(L(t, 'next_text')),
            onPressed: () => _reset(sampleText(t.lang, ++_idx)),
          ),
        ]),
      ),
      AppTextField(controller: _custom, label: L(t, 'custom_text'), maxLines: 3),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton(
          onPressed: () {
            final v = _custom.text.trim().replaceAll(RegExp(r'\s+'), ' ');
            if (v.isNotEmpty) _reset(v);
          },
          child: Text(L(t, 'use_text')),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------ hızlı okuma

class SpeedReadTool extends StatefulWidget {
  final ToolContext t;
  const SpeedReadTool(this.t, {super.key});

  @override
  State<SpeedReadTool> createState() => _SpeedReadToolState();
}

class _SpeedReadToolState extends State<SpeedReadTool> {
  final _text = TextEditingController();
  int _wpm = 300;
  int _size = 1;
  List<String> _chunks = [];
  int _i = 0;
  Timer? _timer;
  bool _playing = false;

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    _text.text = sampleText(t.lang, 0);
    t.store.readInt('wpm', 300).then((v) {
      if (mounted) setState(() => _wpm = v.clamp(100, 1000));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _play() {
    if (_chunks.isEmpty || _i >= _chunks.length) {
      _chunks = chunkWords(_text.text, _size);
      _i = 0;
    }
    if (_chunks.isEmpty) return;
    setState(() => _playing = true);
    _next();
  }

  void _next() {
    _timer?.cancel();
    if (!_playing || _i >= _chunks.length) {
      setState(() => _playing = false);
      return;
    }
    _timer = Timer(Duration(milliseconds: chunkMs(_chunks[_i], _wpm, _size)), () {
      if (!mounted) return;
      setState(() => _i++);
      _next();
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final word = _chunks.isEmpty ? '' : _chunks[math.min<int>(_i, _chunks.length - 1)];
    final s = AppLook.of(context);
    return ToolList(children: [
      AppPanel(
        child: SizedBox(
          height: 140,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(word.isEmpty ? '▶' : word, style: TextStyle(color: s.number, fontSize: 40, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
      if (_chunks.isNotEmpty) LinearProgressIndicator(value: _chunks.isEmpty ? 0 : math.min<int>(_i, _chunks.length) / _chunks.length),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: AppButton(label: _playing ? L(t, 'pause') : L(t, 'start'), onPressed: _playing ? _pause : _play)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            onPressed: () {
              _pause();
              setState(() {
                _i = 0;
                _chunks = chunkWords(_text.text, _size);
              });
            },
          ),
        ]),
      ),
      AppPanel(
        child: Column(children: [
          Text('${L(t, 'wpm')}: $_wpm'),
          Slider(
            value: _wpm.toDouble(),
            min: 100,
            max: 1000,
            divisions: 18,
            onChanged: (v) => setState(() => _wpm = v.round()),
            onChangeEnd: (v) => t.store.write('wpm', '${v.round()}'),
          ),
          Choice<int>(
            values: const [1, 2, 3],
            labels: [for (final n in [1, 2, 3]) Lf(t, 'n_words', {'n': n})],
            selected: _size,
            onChanged: (v) => setState(() {
              _size = v;
              _chunks = [];
              _i = 0;
            }),
          ),
        ]),
      ),
      AppTextField(
        controller: _text,
        label: L(t, 'paste_text'),
        maxLines: 6,
        onChanged: (_) {
          _chunks = [];
          _i = 0;
        },
      ),
      AppInfoCard(L(t, 'speed_note')),
    ]);
  }
}

// ------------------------------------------------------------ kodlama

class CodingTool extends StatefulWidget {
  final ToolContext t;
  const CodingTool(this.t, {super.key});

  @override
  State<CodingTool> createState() => _CodingToolState();
}

class _CodingToolState extends State<CodingTool> {
  int _level = 0;
  int _solved = 0;
  bool _editProc = false;
  List<String> _main = [];
  List<String> _proc = [];
  RobotRun? _run;
  int _step = 0;
  Timer? _anim;
  bool _extraUnlocked = false;
  static const _free = 5;

  ToolContext get t => widget.t;
  RobotLevel get lv => kRobotLevels[_level];

  @override
  void initState() {
    super.initState();
    () async {
      final s = await t.store.readInt('solved');
      final u = await t.unlockedToday('levels');
      if (!mounted) return;
      setState(() {
        _solved = s;
        _extraUnlocked = u;
        _level = math.min<int>(s, kRobotLevels.length - 1);
      });
    }();
  }

  @override
  void dispose() {
    _anim?.cancel();
    super.dispose();
  }

  void _add(String c) {
    setState(() {
      _run = null;
      if (_editProc) {
        if (_proc.length < lv.procMax) _proc.add(c);
      } else if (_main.length < lv.mainMax) {
        _main.add(c);
      }
    });
  }

  void _go() {
    final r = runRobot(lv, _main, _proc);
    _anim?.cancel();
    setState(() {
      _run = r;
      _step = 0;
    });
    _anim = Timer.periodic(const Duration(milliseconds: 280), (tm) async {
      if (!mounted) {
        tm.cancel();
        return;
      }
      if (_step >= r.path.length - 1) {
        tm.cancel();
        if (r.success && _level + 1 > _solved) {
          _solved = _level + 1;
          await t.store.write('solved', '$_solved');
        }
        if (mounted) setState(() {});
        return;
      }
      setState(() => _step++);
    });
  }

  void _open(int i) {
    _anim?.cancel();
    setState(() {
      _level = i;
      _main = [];
      _proc = [];
      _run = null;
      _editProc = false;
    });
  }

  Widget _slots(String label, List<String> prog, int max, bool active) {
    final accent = AppLook.of(context).accent;
    return GestureDetector(
      onTap: () => setState(() => _editProc = prog == _proc),
      child: AppPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: active ? accent : Colors.white70)),
          const SizedBox(height: 6),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var i = 0; i < max; i++)
              InkWell(
                onTap: i < prog.length
                    ? () => setState(() {
                          prog.removeAt(i);
                          _run = null;
                        })
                    : null,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: active ? accent : Colors.white24),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: i < prog.length ? Icon(_icon(prog[i]), size: 22) : null,
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  IconData _icon(String c) => switch (c) {
        'F' => Icons.arrow_upward_rounded,
        'L' => Icons.turn_left_rounded,
        'R' => Icons.turn_right_rounded,
        _ => Icons.functions_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final locked = _level >= _free && !_extraUnlocked;
    final r = _run;
    final pos = r == null ? null : r.path[math.min<int>(_step, r.path.length - 1)];
    final finished = r != null && _step >= r.path.length - 1;
    return ToolList(children: [
      SizedBox(
        height: 48,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          for (var i = 0; i < kRobotLevels.length; i++)
            Padding(
              padding: const EdgeInsets.all(4),
              child: ChoiceChip(
                label: Text('${i + 1}${i < _solved ? ' ✓' : ''}'),
                selected: i == _level,
                onSelected: i <= _solved ? (_) => _open(i) : null,
              ),
            ),
        ]),
      ),
      if (locked)
        UnlockCard(t: t, feature: 'levels', onUnlocked: () => setState(() => _extraUnlocked = true))
      else ...[
        AppPanel(
          child: AspectRatio(
            aspectRatio: lv.w / lv.h,
            child: CustomPaint(painter: _RobotPainter(lv, pos, AppLook.of(context).accent)),
          ),
        ),
        _slots(L(t, 'program'), _main, lv.mainMax, !_editProc),
        if (lv.procMax > 0) _slots(L(t, 'function_p'), _proc, lv.procMax, _editProc),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (final c in ['F', 'L', 'R', if (lv.procMax > 0) 'P'])
              IconButton.filledTonal(iconSize: 30, onPressed: () => _add(c), icon: Icon(_icon(c))),
          ]),
        ),
        AppButton(label: L(t, 'run'), icon: Icons.play_arrow_rounded, onPressed: _main.isEmpty ? null : _go),
        if (finished)
          AppInfoCard(r.success ? L(t, 'solved') : L(t, 'robot_${r.error}'),
              icon: r.success ? Icons.emoji_events_rounded : Icons.error_outline_rounded),
        if (finished && r.success && _level + 1 < kRobotLevels.length)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(onPressed: () => _open(_level + 1), child: Text(L(t, 'next_level'))),
          ),
        AppInfoCard(L(t, 'robot_help'), icon: Icons.lightbulb_outline_rounded),
      ],
    ]);
  }
}

class _RobotPainter extends CustomPainter {
  final RobotLevel lv;
  final (int, int, int)? pos;
  final Color accent;
  _RobotPainter(this.lv, this.pos, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / lv.w, ch = size.height / lv.h;
    for (var y = 0; y < lv.h; y++) {
      for (var x = 0; x < lv.w; x++) {
        final c = lv.at(x, y);
        final r = Rect.fromLTWH(x * cw + 1, y * ch + 1, cw - 2, ch - 2);
        final color = c == '#'
            ? Colors.black.withValues(alpha: 0.45)
            : (c == 'G' ? Colors.greenAccent.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.10));
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = color);
      }
    }
    final (sx, sy) = lv.start;
    final p = pos ?? (sx, sy, 0);
    final c = Offset((p.$1 + 0.5) * cw, (p.$2 + 0.5) * ch);
    final a = p.$3 * math.pi / 2;
    final rad = math.min<double>(cw, ch) * 0.34;
    final tri = Path()
      ..moveTo(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad)
      ..lineTo(c.dx + math.cos(a + 2.4) * rad, c.dy + math.sin(a + 2.4) * rad)
      ..lineTo(c.dx + math.cos(a - 2.4) * rad, c.dy + math.sin(a - 2.4) * rad)
      ..close();
    canvas.drawPath(tri, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_RobotPainter old) => old.pos != pos || old.lv != lv;
}
