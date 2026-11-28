/// Rehberler: ilk yardım (acil numara bandıyla), düğüm rehberi ve çamaşır
/// bakım sembolleri (özgün çizim).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common.dart';
import '../data/guides.dart';
import '../fold.dart';

// ------------------------------------------------------------ ilk yardım

class FirstAidTool extends StatefulWidget {
  final ToolContext t;
  const FirstAidTool(this.t, {super.key});

  @override
  State<FirstAidTool> createState() => _FirstAidToolState();
}

class _FirstAidToolState extends State<FirstAidTool> {
  String _number = '112';
  String _q = '';

  ToolContext get t => widget.t;

  @override
  void initState() {
    super.initState();
    t.store.read('number').then((v) {
      if (v != null && mounted) setState(() => _number = v);
    });
  }

  Future<void> _call() async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: _number));
    } catch (_) {}
  }

  Future<void> _editNumber() async {
    final c = TextEditingController(text: _number);
    final v = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(L(t, 'emergency_number')),
        content: TextField(controller: c, keyboardType: TextInputType.phone, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(L(t, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(L(t, 'save'))),
        ],
      ),
    );
    c.dispose();
    if (v == null || !RegExp(r'^[0-9+]{2,6}$').hasMatch(v)) return;
    setState(() => _number = v);
    await t.store.write('number', v);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.folded;
    final list = kFirstAid.where((g) => q.isEmpty || C(t, g.title).folded.contains(q)).toList();
    return ToolList(children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFB71C1C), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.emergency_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(Lf(t, 'call_banner', {'n': _number}),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFB71C1C)),
                onPressed: t.isWeb ? null : _call,
                icon: const Icon(Icons.call_rounded),
                label: Text('${L(t, 'call_emergency')} · $_number', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            IconButton(
              tooltip: L(t, 'emergency_number'),
              onPressed: _editNumber,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: t.tx('search')),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      for (final g in list)
        AppPanel(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: Icon(g.urgent ? Icons.priority_high_rounded : Icons.healing_rounded,
                color: g.urgent ? Colors.redAccent : Colors.white70),
            title: Text(C(t, g.title), style: const TextStyle(fontWeight: FontWeight.w800)),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (var i = 0; i < g.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(C(t, g.steps[i]), style: const TextStyle(fontSize: 15, height: 1.35))),
                  ]),
                ),
            ],
          ),
        ),
      AppInfoCard(L(t, 'firstaid_note'), icon: Icons.medical_information_rounded),
      AppInfoCard(L(t, 'firstaid_course'), icon: Icons.school_rounded),
    ]);
  }
}

// ------------------------------------------------------------ düğümler

class KnotTool extends StatelessWidget {
  final ToolContext t;
  const KnotTool(this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    final levels = Ls(t, 'levels');
    return ToolList(children: [
      for (final k in kKnots)
        AppPanel(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: SizedBox(width: 44, height: 44, child: CustomPaint(painter: _KnotIcon(kKnots.indexOf(k)))),
            title: Text(C(t, k.name), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${levels[(k.level - 1).clamp(0, levels.length - 1)]} · ${C(t, k.use)}',
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              Align(alignment: AlignmentDirectional.centerStart, child: Text(C(t, k.use), style: const TextStyle(color: Colors.white70))),
              const SizedBox(height: 6),
              for (var i = 0; i < k.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(C(t, k.steps[i]), style: const TextStyle(fontSize: 15, height: 1.35))),
                  ]),
                ),
            ],
          ),
        ),
      AppInfoCard(L(t, 'knot_safety'), icon: Icons.warning_amber_rounded),
    ]);
  }
}

/// Basit, özgün ip kıvrımı simgesi (her düğüme farklı tur sayısı).
class _KnotIcon extends CustomPainter {
  final int seed;
  _KnotIcon(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFCC80)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final turns = 1 + seed % 3;
    final path = Path()..moveTo(2, size.height * 0.75);
    final c = size.center(Offset.zero);
    for (var i = 0; i <= 60; i++) {
      final a = i / 60 * turns * 2 * math.pi;
      final r = size.width * 0.28;
      path.lineTo(c.dx + r * math.cos(a) * (0.6 + 0.4 * i / 60), c.dy + r * math.sin(a));
    }
    path.lineTo(size.width - 2, size.height * 0.25);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_KnotIcon old) => old.seed != seed;
}

// ------------------------------------------------------------ çamaşır

class LaundryTool extends StatefulWidget {
  final ToolContext t;
  const LaundryTool(this.t, {super.key});

  @override
  State<LaundryTool> createState() => _LaundryToolState();
}

class _LaundryToolState extends State<LaundryTool> {
  int _cat = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final cats = Ls(t, 'laundry_cats');
    final accent = AppLook.of(context).accent;
    return ToolList(children: [
      Choice<int>(
        values: List.generate(cats.length, (i) => i),
        labels: cats,
        selected: _cat,
        onChanged: (v) => setState(() => _cat = v),
      ),
      for (final s in kCareSymbols[_cat])
        AppPanel(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            SizedBox(width: 64, height: 56, child: CustomPaint(painter: CarePainter(s, accent))),
            const SizedBox(width: 14),
            Expanded(child: Text(C(t, s.meaning), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
        ),
      AppInfoCard(L(t, 'laundry_note')),
    ]);
  }
}

/// Bakım sembolünü çizer (özgün çizim; etiketin yerine geçmez).
class CarePainter extends CustomPainter {
  final CareSymbol s;
  final Color color;
  CarePainter(this.s, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white;
    void text(String v, Offset c, double fs) {
      final tp = TextPainter(
        text: TextSpan(text: v, style: TextStyle(color: Colors.white, fontSize: fs, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    void dots(int n, Offset c) {
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(c + Offset((i - (n - 1) / 2) * 8, 0), 2.6, fill);
      }
    }

    final box = Rect.fromLTWH(w * 0.12, h * 0.1, w * 0.76, h * 0.62);
    switch (s.kind) {
      case 'wash':
      case 'hand':
        final path = Path()
          ..moveTo(box.left, box.top + 6)
          ..lineTo(box.left + 6, box.bottom)
          ..lineTo(box.right - 6, box.bottom)
          ..lineTo(box.right, box.top + 6);
        canvas.drawPath(path, p);
        // su dalgası
        final wave = Path()..moveTo(box.left + 2, box.top + 10);
        for (var i = 0; i < 4; i++) {
          final x = box.left + 2 + (box.width - 4) * (i + 1) / 4;
          wave.quadraticBezierTo(x - (box.width - 4) / 8, box.top + (i.isEven ? 4 : 16), x, box.top + 10);
        }
        canvas.drawPath(wave, p);
        if (s.label.isNotEmpty) text(s.label, Offset(box.center.dx, box.bottom - 12), 14);
        if (s.kind == 'hand') {
          canvas.drawLine(Offset(box.center.dx - 8, box.bottom - 6), Offset(box.center.dx + 2, box.top + 14), p);
          canvas.drawCircle(Offset(box.center.dx + 4, box.top + 12), 4, p);
        }
      case 'bleach':
        final tri = Path()
          ..moveTo(w / 2, box.top)
          ..lineTo(box.right, box.bottom)
          ..lineTo(box.left, box.bottom)
          ..close();
        canvas.drawPath(tri, p);
        if (s.bars == 2) {
          canvas.drawLine(Offset(w / 2 - 6, box.bottom - 4), Offset(w / 2 + 4, box.top + 16), p);
          canvas.drawLine(Offset(w / 2 + 4, box.bottom - 4), Offset(w / 2 + 14, box.top + 22), p);
        }
      case 'dry':
      case 'tumble':
        final sq = Rect.fromCenter(center: box.center, width: box.height + 4, height: box.height + 4);
        canvas.drawRect(sq, p);
        if (s.kind == 'tumble') {
          canvas.drawCircle(sq.center, sq.width * 0.36, p);
          dots(s.dots, sq.center);
        }
        switch (s.mark) {
          case 'line':
            canvas.drawArc(Rect.fromLTWH(sq.left + 4, sq.top - 6, sq.width - 8, 18), 0.2, math.pi - 0.4, false, p);
          case 'drip':
            for (var i = -1; i <= 1; i++) {
              canvas.drawLine(Offset(sq.center.dx + i * 8, sq.top + 6), Offset(sq.center.dx + i * 8, sq.bottom - 6), p);
            }
          case 'flat':
            canvas.drawLine(Offset(sq.left + 6, sq.center.dy), Offset(sq.right - 6, sq.center.dy), p);
          case 'shade':
            canvas.drawLine(Offset(sq.left, sq.top + 10), Offset(sq.left + 10, sq.top), p);
            canvas.drawLine(Offset(sq.left, sq.top + 18), Offset(sq.left + 18, sq.top), p);
        }
      case 'iron':
        final path = Path()
          ..moveTo(box.left, box.bottom)
          ..lineTo(box.right, box.bottom)
          ..lineTo(box.right - 4, box.top + 8)
          ..lineTo(box.left + 14, box.top + 8)
          ..quadraticBezierTo(box.left + 2, box.top + 14, box.left, box.bottom)
          ..moveTo(box.right - 6, box.top + 8)
          ..lineTo(box.right - 2, box.top);
        canvas.drawPath(path, p);
        dots(s.dots, Offset(box.center.dx + 4, box.center.dy + 8));
      case 'pro':
        canvas.drawCircle(box.center, box.height / 2 + 2, p);
        if (s.label.isNotEmpty) text(s.label, box.center, 20);
    }
    // hassas program çizgileri
    for (var i = 0; i < (s.kind == 'wash' ? s.bars : 0); i++) {
      final y = box.bottom + 7 + i * 6;
      canvas.drawLine(Offset(box.left + 4, y), Offset(box.right - 4, y), p);
    }
    if (s.cross) {
      final cp = Paint()
        ..color = color
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(box.left - 2, box.top - 4), Offset(box.right + 2, box.bottom + 4), cp);
      canvas.drawLine(Offset(box.right + 2, box.top - 4), Offset(box.left - 2, box.bottom + 4), cp);
    }
  }

  @override
  bool shouldRepaint(CarePainter old) => old.s != s || old.color != color;
}
