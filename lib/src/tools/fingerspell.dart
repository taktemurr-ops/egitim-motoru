/// İşaret dili temelleri: YALNIZCA ASL (American Sign Language) parmak
/// alfabesi. Tam işaret dili öğretmez; bunu ekranda açıkça yazar. El
/// şekilleri özgün, şematik çizimlerdir (sağ el, avuç izleyiciye dönük).
/// Türk İşaret Dili (TİD) parmak alfabesi sağır topluluğunun gözden
/// geçirmesinden sonra eklenecektir.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import '../ek4_core.dart';

class FingerspellTool extends StatefulWidget {
  final ToolContext t;
  const FingerspellTool(this.t, {super.key});

  @override
  State<FingerspellTool> createState() => _FingerspellState();
}

class _FingerspellState extends State<FingerspellTool> {
  ToolContext get t => widget.t;
  final math.Random _rnd = math.Random();
  int _mode = 0; // 0 alfabe, 1 tanı, 2 göster, 3 oku
  int _sel = 0;

  // tanı
  int? _qLetter;
  List<int> _qOpts = const [];
  int? _picked;
  int _score = 0, _asked = 0;

  // göster / oku
  final TextEditingController _text = TextEditingController(text: 'HELLO');
  final TextEditingController _guess = TextEditingController();
  List<String> _seq = const [];
  int _at = -1;
  Timer? _timer;
  double _speed = 1; // harf/sn
  String? _word;
  bool? _guessOk;
  final List<String> _words = fingerspellWords();

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _guess.dispose();
    super.dispose();
  }

  void _play(List<String> seq) {
    _timer?.cancel();
    if (seq.isEmpty) return;
    setState(() {
      _seq = seq;
      _at = 0;
    });
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed).round()), (tm) {
      if (!mounted) return;
      setState(() {
        if (_at >= _seq.length - 1) {
          tm.cancel();
        } else {
          _at++;
        }
      });
    });
  }

  void _newQuestion() => setState(() {
        _qLetter = _rnd.nextInt(kAslAlphabet.length);
        final opts = <int>{_qLetter!};
        while (opts.length < 4) {
          opts.add(_rnd.nextInt(kAslAlphabet.length));
        }
        _qOpts = opts.toList()..shuffle(_rnd);
        _picked = null;
      });

  void _newWord() {
    final w = _words.isEmpty ? 'hello' : _words[_rnd.nextInt(_words.length)];
    setState(() {
      _word = w;
      _guessOk = null;
      _guess.clear();
    });
    _play(spellable(w));
  }

  Widget _hand(HandShape h, double width) => SizedBox(
        width: width,
        height: width * 1.2,
        child: CustomPaint(painter: HandPainter(h, AppLook.of(context).accent)),
      );

  Widget _big(HandShape h, {bool showLetter = true}) => AppPanel(
        child: Column(children: [
          _hand(h, 180),
          if (showLetter) Text(h.letter, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
          if (showLetter && h.motion != null) Text(L(t, 'fs_motion'), style: const TextStyle(color: Colors.white70)),
        ]),
      );

  Widget _alphabet() => Column(children: [
        _big(kAslAlphabet[_sel]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
            for (var i = 0; i < kAslAlphabet.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _sel = i),
                child: Container(
                  width: 58,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: i == _sel ? AppLook.of(context).accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    _hand(kAslAlphabet[i], 44),
                    Text(kAslAlphabet[i].letter, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
          ]),
        ),
      ]);

  Widget _practice() {
    final q = _qLetter;
    if (q == null) return AppButton(label: L(t, 'start'), icon: Icons.play_arrow_rounded, onPressed: _newQuestion);
    return Column(children: [
      AppHeading(L(t, 'fs_which'), icon: Icons.help_outline_rounded),
      _big(kAslAlphabet[q], showLetter: _picked != null),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          for (final o in _qOpts)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: _picked == null
                      ? Colors.white.withValues(alpha: 0.06)
                      : o == q
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
                              if (o == q) _score++;
                            }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(kAslAlphabet[o].letter, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
      Text('${L(t, 'score')}: $_score / $_asked', style: const TextStyle(fontSize: 16)),
      if (_picked != null) AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: _newQuestion),
    ]);
  }

  Widget _sequence({bool hideLetters = false}) {
    if (_at < 0 || _at >= _seq.length) return const SizedBox.shrink();
    final c = _seq[_at];
    final h = handFor(c);
    return Column(children: [
      if (h != null) _big(h, showLetter: !hideLetters) else const SizedBox(height: 240),
      if (!hideLetters)
        Wrap(alignment: WrapAlignment.center, children: [
          for (var i = 0; i < _seq.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(_seq[i] == ' ' ? '·' : _seq[i],
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: i == _at ? FontWeight.w900 : FontWeight.w400,
                      color: i == _at ? AppLook.of(context).accent : Colors.white70)),
            ),
        ]),
    ]);
  }

  Widget _speedRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text(L(t, 'speed')),
          Expanded(
            child: Slider(value: _speed, min: 0.5, max: 2.5, divisions: 8, label: _speed.toStringAsFixed(1), onChanged: (v) => setState(() => _speed = v)),
          ),
        ]),
      );

  Widget _spell() => Column(children: [
        AppTextField(controller: _text, label: L(t, 'fs_type_text')),
        _speedRow(),
        AppButton(label: L(t, 'fs_play'), icon: Icons.play_arrow_rounded, onPressed: () => _play(spellable(_text.text))),
        _sequence(),
        if (_seq.length > 1) AppInfoCard(L(t, 'fs_double'), icon: Icons.swap_horiz_rounded),
      ]);

  Widget _read() {
    final w = _word;
    return Column(children: [
      _speedRow(),
      if (w == null)
        AppButton(label: L(t, 'start'), icon: Icons.play_arrow_rounded, onPressed: _newWord)
      else ...[
        AppHeading(L(t, 'fs_guess'), icon: Icons.visibility_rounded),
        _sequence(hideLetters: _guessOk == null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: AppButton(label: L(t, 'again'), icon: Icons.replay_rounded, onPressed: () => _play(spellable(w)))),
            const SizedBox(width: 8),
            Expanded(child: AppButton(label: L(t, 'next'), icon: Icons.arrow_forward_rounded, onPressed: _newWord)),
          ]),
        ),
        AppTextField(controller: _guess, label: L(t, 'type_here')),
        AppButton(
          label: L(t, 'check'),
          icon: Icons.check_rounded,
          onPressed: () {
            final ok = _guess.text.trim().toLowerCase() == w;
            setState(() => _guessOk = ok);
            if (!ok) {
              _timer?.cancel();
              setState(() {
                _seq = spellable(w);
                _at = 0;
              });
            }
          },
        ),
        if (_guessOk != null)
          AppInfoCard('${L(t, _guessOk! ? 'correct' : 'wrong')}: ${w.toUpperCase()}',
              icon: _guessOk! ? Icons.check_circle_rounded : Icons.cancel_rounded),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ToolList(children: [
      AppInfoCard(L(t, 'fs_not_language'), icon: Icons.sign_language_rounded),
      Choice<int>(
        values: const [0, 1, 2, 3],
        labels: [for (final x in Ls(t, 'fs_modes')) x.trim()],
        selected: _mode,
        onChanged: (m) {
          _timer?.cancel();
          setState(() {
            _mode = m;
            _at = -1;
            _seq = const [];
          });
        },
      ),
      if (_mode == 0) _alphabet(),
      if (_mode == 1) _practice(),
      if (_mode == 2) _spell(),
      if (_mode == 3) _read(),
      AppInfoCard(L(t, 'fs_attrib'), icon: Icons.info_outline_rounded),
      AppInfoCard(L(t, 'fs_tid'), icon: Icons.groups_rounded),
    ]);
  }
}

/// Şematik el çizimi (birim kutu: genişlik 1, yükseklik 1,2).
class HandPainter extends CustomPainter {
  final HandShape h;
  final Color accent;
  HandPainter(this.h, this.accent);

  static const Color _skin = Color(0xFFF1D7C2);
  static const Color _shade = Color(0xFFD9B79E);
  static const Color _line = Color(0xFF6D5446);
  static const List<double> _x = [0.33, 0.45, 0.57, 0.69];
  static const List<double> _len = [0.40, 0.45, 0.41, 0.32];
  static const List<double> _spread = [-0.24, -0.07, 0.10, 0.28];
  static const double _top = 0.70, _w = 0.105;
  static const Offset _thumbBase = Offset(0.29, 0.98);

  Offset get _touch => h.fingers == 'tttt'
      ? const Offset(0.44, 0.47)
      : h.fingers.startsWith('t')
          ? const Offset(0.29, 0.55)
          : const Offset(0.50, 0.60);

  void _capsule(Canvas c, Offset a, Offset b, double w, {Color fill = _skin}) {
    final p = Paint()
      ..color = _line
      ..strokeWidth = w + 0.014
      ..strokeCap = StrokeCap.round;
    c.drawLine(a, b, p);
    c.drawLine(a, b, p
      ..color = fill
      ..strokeWidth = w);
  }

  void _curve(Canvas c, Offset a, Offset ctrl, Offset b, double w) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
    c.drawPath(
        path,
        Paint()
          ..color = _line
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 0.014
          ..strokeCap = StrokeCap.round);
    c.drawPath(
        path,
        Paint()
          ..color = _skin
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
  }

  void _finger(Canvas c, int i, String st) {
    final base = Offset(_x[i], _top + 0.02);
    final l = _len[i];
    switch (st) {
      case 'u':
        _capsule(c, base, Offset(_x[i], _top - l), _w);
      case 's':
        final a = _spread[i];
        _capsule(c, base, base + Offset(math.sin(a) * l, -math.cos(a) * l), _w);
      case 'x':
        // Orta parmak işaret parmağının üstünden çaprazlanır.
        _capsule(c, base, base + Offset(-0.10, -l), _w);
      case 'h':
        final knuckle = Offset(_x[i], _top - l * 0.5);
        _capsule(c, base, knuckle, _w);
        _capsule(c, knuckle, knuckle + const Offset(0, 0.10), _w * 0.9, fill: _shade);
      case 'v':
        _curve(c, base, Offset(_x[i] + 0.02, _top - l * 0.9), Offset(_x[i] - 0.13, _top - l * 0.55), _w);
      case 't':
        _curve(c, base, Offset(_x[i], _top - l * 0.9), _touch, _w);
      default: // c: avuca kıvrık, önden boğumlar görünür
        _capsule(c, Offset(_x[i], _top - 0.03), Offset(_x[i], _top + 0.12), _w, fill: _shade);
    }
  }

  Offset? _thumbTipBehind() => switch (h.thumb) {
        'between' => const Offset(0.39, 0.66),
        'under2' => const Offset(0.51, 0.80),
        'under3' => const Offset(0.63, 0.80),
        _ => null,
      };

  void _thumb(Canvas c) {
    const b = _thumbBase;
    const w = 0.115;
    switch (h.thumb) {
      case 'side':
        _capsule(c, b, const Offset(0.24, 0.66), w);
      case 'across':
        _capsule(c, b, const Offset(0.60, 0.86), w);
      case 'under4':
        _capsule(c, b, const Offset(0.66, 0.90), w);
      case 'out':
        _capsule(c, b, const Offset(0.05, 0.70), w);
      case 'parallel':
        _capsule(c, b, const Offset(0.22, 0.56), w);
      case 'touch':
        _curve(c, b, const Offset(0.16, 0.70), _touch, w);
      case 'curve':
        _curve(c, b, const Offset(0.08, 0.86), const Offset(0.18, 0.68), w);
      case 'up_between':
        _capsule(c, b, const Offset(0.40, 0.55), w);
      default:
        final tip = _thumbTipBehind();
        if (tip != null) _capsule(c, b, tip, w);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    // Yön: yana / aşağı.
    canvas.translate(s / 2, size.height / 2);
    canvas.rotate(h.orient == 1 ? math.pi / 2 : (h.orient == 2 ? math.pi : 0));
    if (h.orient == 1) canvas.scale(0.85);
    canvas.translate(-s / 2, -size.height / 2);
    canvas.scale(s);

    // Bilek ve avuç.
    final palm = RRect.fromRectAndRadius(const Rect.fromLTRB(0.25, 0.66, 0.76, 1.12), const Radius.circular(0.09));
    canvas.drawRRect(palm.inflate(0.007), Paint()..color = _line);
    canvas.drawRRect(palm, Paint()..color = _skin);

    final behind = _thumbTipBehind() != null;
    if (behind) _thumb(canvas);
    final f = h.fingers;
    // Çaprazda (R) önce orta parmak değil, işaret çizilir; orta üstte kalır.
    for (var i = 0; i < 4; i++) {
      _finger(canvas, i, f[i]);
    }
    if (behind) {
      // Başparmak ucu parmakların arasından görünür.
      final tip = _thumbTipBehind()!;
      canvas.drawCircle(tip, 0.05, Paint()..color = _line);
      canvas.drawCircle(tip, 0.043, Paint()..color = _skin);
    } else {
      _thumb(canvas);
    }

    // Hareket oku (J, Z).
    final m = h.motion;
    if (m != null) {
      final p = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.025
        ..strokeCap = StrokeCap.round;
      final path = Path();
      if (m == 'J') {
        path
          ..moveTo(0.80, 0.36)
          ..lineTo(0.80, 0.62)
          ..quadraticBezierTo(0.80, 0.78, 0.66, 0.78)
          ..quadraticBezierTo(0.56, 0.78, 0.56, 0.68);
      } else {
        path
          ..moveTo(0.20, 0.12)
          ..lineTo(0.52, 0.12)
          ..lineTo(0.20, 0.30)
          ..lineTo(0.52, 0.30);
      }
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HandPainter old) => old.h != h || old.accent != accent;
}
