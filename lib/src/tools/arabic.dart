/// Arap harfleriyle okuma ve yazma: 28 harf (+ Farsça/Urduca/Osmanlıca 4 ek
/// harf), konuma göre biçimler, harekeler, okuma alıştırması ve parmakla iz
/// sürme. Yalnızca alfabe ve okuma öğretilir; dinî yorum ya da metin yoktur.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../data/core_words.dart';
import '../data/phrases.dart' show kLangCodes;
import '../ek4_core.dart';
import '../speech.dart';

const TextStyle _ar = TextStyle(fontSize: 40, height: 1.4, color: Colors.white);

class ArabicLettersTool extends StatefulWidget {
  final ToolContext t;
  const ArabicLettersTool(this.t, {super.key});

  @override
  State<ArabicLettersTool> createState() => _ArabicState();
}

class _ArabicState extends State<ArabicLettersTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  int _mode = 0; // 0 harfler, 1 harekeler, 2 okuma, 3 yazma
  int _sel = 1;
  int _markLetter = 1;

  // okuma
  ({String prompt, String answer, List<String> options})? _q;
  String? _picked;
  int _score = 0, _asked = 0;

  int get _ui => math.max(0, kLangCodes.indexOf(t.lang));

  void _say(String text) => unawaited(Speaker.instance.speak(text, 'ar'));

  // ------------------------------------------------------------ harfler

  Widget _letterGrid(int selected, ValueChanged<int> onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < kArLetters.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: Container(
                  width: 52,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppLook.of(context).accent.withValues(alpha: 0.35) : Colors.white.withValues(alpha: kArLetters[i].extra ? 0.03 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: kArLetters[i].extra ? Border.all(color: Colors.white24) : null,
                  ),
                  child: Text(kArLetters[i].ch, style: _ar.copyWith(fontSize: 28)),
                ),
              ),
          ]),
        ),
      );

  Widget _letters() {
    final l = kArLetters[_sel];
    final pos = Ls(t, 'ar_pos');
    return Column(children: [
      AppPanel(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(l.ch, style: _ar.copyWith(fontSize: 72)),
            const SizedBox(width: 16),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(l.nativeName, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 20)),
                Text('${L(t, 'ar_sound')}: ${l.sound}', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: () => _say(l.nativeName)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            for (var p = 0; p < 4; p++)
              Expanded(
                child: Column(children: [
                  Text(arForm(l, p), textDirection: TextDirection.rtl, style: _ar),
                  Text(pos[p].trim(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
          ]),
          if (!l.joinsNext) Text(L(t, 'ar_nonjoin'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          if (l.extra) Text(L(t, 'ar_extra'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ]),
      ),
      _letterGrid(_sel, (i) => setState(() => _sel = i)),
    ]);
  }

  // ------------------------------------------------------------ harekeler

  String _markDesc(ArMark m) {
    final where = L(t, m.below ? 'ar_below' : 'ar_above');
    final what = switch (m.vowel) {
      '' => L(t, 'ar_no_vowel'),
      '+' => L(t, 'ar_double'),
      'an' || 'in' || 'un' => '${m.vowel} · ${L(t, 'ar_nunation')}',
      _ => m.vowel,
    };
    return '$what · $where';
  }

  Widget _marks() {
    final l = syllableLetters[_markLetter % syllableLetters.length];
    return Column(children: [
      for (final m in kArMarks)
        Card(
          child: ListTile(
            leading: SizedBox(width: 56, child: Center(child: Text('${l.ch}${m.mark}', textDirection: TextDirection.rtl, style: _ar.copyWith(fontSize: 34)))),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(_markDesc(m)),
            trailing: Text(syllableOf(l, m), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            onTap: () => _say('${l.ch}${m.mark}'),
          ),
        ),
      AppHeading(L(t, 'ar_letters')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < syllableLetters.length; i++)
              ChoiceChip(
                label: Text(syllableLetters[i].ch, style: const TextStyle(fontSize: 22)),
                selected: i == _markLetter,
                onSelected: (_) => setState(() => _markLetter = i),
              ),
          ]),
        ),
      ),
    ]);
  }

  // ------------------------------------------------------------ okuma

  void _newQuestion() {
    final kind = _rnd.nextInt(3);
    setState(() {
      _picked = null;
      if (kind == 0) {
        final l = kArLetters[_rnd.nextInt(kArLetters.length)];
        final opts = <String>{'${l.name} (${l.sound})'};
        while (opts.length < 4) {
          final o = kArLetters[_rnd.nextInt(kArLetters.length)];
          opts.add('${o.name} (${o.sound})');
        }
        _q = (prompt: arForm(l, _rnd.nextInt(4)), answer: '${l.name} (${l.sound})', options: opts.toList()..shuffle(_rnd));
      } else if (kind == 1) {
        final q = syllableQuestion(_rnd);
        _q = (prompt: q.text, answer: q.answer, options: q.options);
      } else {
        // Günlük kelime (harekesiz): anlamını seç.
        final words = kCoreWords.where((w) => w.cat != 'num' && !w.w[5].contains(' ')).toList();
        final w = words[_rnd.nextInt(words.length)];
        final opts = <String>{'${w.emoji} ${w.w[_ui]}'};
        while (opts.length < 4) {
          final o = words[_rnd.nextInt(words.length)];
          opts.add('${o.emoji} ${o.w[_ui]}');
        }
        _q = (prompt: w.w[5], answer: '${w.emoji} ${w.w[_ui]}', options: opts.toList()..shuffle(_rnd));
      }
    });
  }

  Widget _reading() {
    final q = _q;
    if (q == null) {
      return AppButton(label: L(t, 'start'), icon: Icons.play_arrow_rounded, onPressed: _newQuestion);
    }
    return Column(children: [
      AppPanel(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(q.prompt, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: _ar.copyWith(fontSize: 64))),
          IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: () => _say(q.prompt)),
        ]),
      ),
      for (final o in q.options)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: _picked == null
                ? Colors.white.withValues(alpha: 0.06)
                : o == q.answer
                    ? Colors.green.withValues(alpha: 0.35)
                    : (o == _picked ? Colors.red.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _picked != null
                  ? null
                  : () => setState(() {
                        _picked = o;
                        _asked++;
                        if (o == q.answer) _score++;
                      }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(o, style: const TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      Text('${L(t, 'score')}: $_score / $_asked', style: const TextStyle(fontSize: 16)),
      if (_picked != null) AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: _newQuestion),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      Choice<int>(
        values: const [0, 1, 2, 3],
        labels: [for (final x in Ls(t, 'ar_modes')) x.trim()],
        selected: _mode,
        onChanged: (m) => setState(() => _mode = m),
      ),
      if (_mode == 0) _letters(),
      if (_mode == 1) _marks(),
      if (_mode == 2) _reading(),
      if (_mode == 3) _TracePad(t: t),
      AppInfoCard(L(t, 'ar_note'), icon: Icons.info_outline_rounded),
    ]);
  }
}

// ================================================================ iz sürme

class _TracePad extends StatefulWidget {
  final ToolContext t;
  const _TracePad({required this.t});

  @override
  State<_TracePad> createState() => _TracePadState();
}

class _TracePadState extends State<_TracePad> {
  static const double _size = 280;
  ToolContext get t => widget.t;
  int _letter = 1;
  int _pos = 0;
  final List<List<Offset>> _strokes = [];
  List<bool>? _mask;
  int _maskFor = -1;
  ({double coverage, double precision})? _score;

  String get _glyph => arForm(kArLetters[_letter], _pos);

  TextPainter _painter() => TextPainter(
        text: TextSpan(text: _glyph, style: _ar.copyWith(fontSize: _size * 0.55, height: 1.2)),
        textDirection: TextDirection.rtl,
      )..layout();

  Future<void> _buildMask() async {
    final key = _letter * 10 + _pos;
    if (_maskFor == key && _mask != null) return;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final tp = _painter();
    tp.paint(c, Offset((_size - tp.width) / 2, (_size - tp.height) / 2));
    final n = _size.toInt();
    final img = await rec.endRecording().toImage(n, n);
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    if (bd == null) return;
    final px = Uint8List.view(bd.buffer);
    _mask = List<bool>.generate(n * n, (i) => px[i * 4 + 3] > 96);
    _maskFor = key;
  }

  Future<void> _rate() async {
    await _buildMask();
    final m = _mask;
    if (m == null || !mounted) return;
    final pts = [for (final s in _strokes) for (final p in s) (p.dx, p.dy)];
    setState(() => _score = traceScore(m, _size.toInt(), _size.toInt(), pts));
  }

  void _clear() => setState(() {
        _strokes.clear();
        _score = null;
      });

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    final sc = _score;
    final stars = sc == null ? 0 : traceStars(sc.coverage, sc.precision);
    return Column(children: [
      AppInfoCard(L(t, 'ar_trace_hint'), icon: Icons.gesture_rounded),
      Choice<int>(
        values: const [0, 1, 2, 3],
        labels: [for (final x in Ls(t, 'ar_pos')) x.trim()],
        selected: _pos,
        onChanged: (p) => setState(() {
          _pos = p;
          _clear();
        }),
      ),
      Center(
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
          // Dikey/yatay sürükleme tanıyıcıları, kaydırılan listenin önünde kazanır.
          child: GestureDetector(
            onVerticalDragStart: (d) => setState(() => _strokes.add([d.localPosition])),
            onVerticalDragUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
            onVerticalDragEnd: (_) => unawaited(_rate()),
            onHorizontalDragStart: (d) => setState(() => _strokes.add([d.localPosition])),
            onHorizontalDragUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
            onHorizontalDragEnd: (_) => unawaited(_rate()),
            onTapDown: (d) => setState(() => _strokes.add([d.localPosition])),
            onTapUp: (_) => unawaited(_rate()),
            child: CustomPaint(size: const Size(_size, _size), painter: _TracePainter(_painter(), _strokes, s.accent)),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(sc == null ? '☆☆☆' : '${'★' * stars}${'☆' * (3 - stars)}  ${Lf(t, 'ar_trace_score', {'c': (sc.coverage * 100).round()})}',
          style: TextStyle(fontSize: 22, color: s.accent)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: AppButton(label: L(t, 'clear'), icon: Icons.refresh_rounded, onPressed: _clear)),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              label: L(t, 'next'),
              icon: Icons.arrow_forward_rounded,
              onPressed: () => setState(() {
                _letter = (_letter + 1) % kArLetters.length;
                _clear();
              }),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < kArLetters.length; i++)
              ChoiceChip(
                label: Text(kArLetters[i].ch, style: const TextStyle(fontSize: 22)),
                selected: i == _letter,
                onSelected: (_) => setState(() {
                  _letter = i;
                  _clear();
                }),
              ),
          ]),
        ),
      ),
    ]);
  }
}

class _TracePainter extends CustomPainter {
  final TextPainter glyph;
  final List<List<Offset>> strokes;
  final Color color;
  _TracePainter(this.glyph, this.strokes, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Silik harf (aynı yerleşim puanlamada da kullanılır).
    canvas.saveLayer(Offset.zero & size, Paint()..color = const Color(0x40FFFFFF));
    glyph.paint(canvas, Offset((size.width - glyph.width) / 2, (size.height - glyph.height) / 2));
    canvas.restore();
    final p = Paint()
      ..color = color
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 8, Paint()..color = color);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final o in s.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) => true;
}
