/// Ortak yardımcılar (arac-motoru'ndan kopya + Eğitim ve Yaşam ekleri):
/// çeviri, liste düzeni, sensör bekleme, izin açıklaması, tarih ve kayıt.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import 'tx.dart';

/// Araç etiketi (33 dil).
String L(ToolContext t, String key) => t.t(kEgitimL[key] ?? [key]);

/// Yer tutuculu etiket: {n}, {a} … [p] ile dolar.
String Lf(ToolContext t, String key, Map<String, Object> p) {
  var s = L(t, key);
  p.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// İçerik metni ([tr, en] ya da 33 dil): diğer dillerde İngilizceye düşer.
String C(ToolContext t, List<String> l) => t.t(l);

/// Virgülle ayrılmış etiket listesi.
List<String> Ls(ToolContext t, String key) => L(t, key).split(',');

/// Aracın gövdesi: kaydırılabilir sütun.
class ToolList extends StatelessWidget {
  final List<Widget> children;
  const ToolList({super.key, required this.children});

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.only(top: 8, bottom: 32), children: children);
}

/// "Bu cihazda yok" bilgisi.
Widget notAvailable(ToolContext t) =>
    AppInfoCard(t.tx(kIsWeb ? 'web_unavailable' : 'not_available'), icon: Icons.sensors_off_rounded);

/// Büyük sayı göstergesi.
class BigReadout extends StatelessWidget {
  final String value;
  final String unit;
  final String? caption;
  const BigReadout(this.value, {super.key, this.unit = '', this.caption});

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    return AppPanel(
      child: Column(children: [
        if (caption != null) Text(caption!, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: TextStyle(color: s.number, fontSize: 64, fontWeight: FontWeight.w900)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Seçenek düğmeleri (SegmentedButton) için kısa yol.
class Choice<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  const Choice({super.key, required this.values, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < values.length; i++) ButtonSegment<T>(value: values[i], label: Text(labels[i])),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

/// Açılır liste.
class Pick<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final String Function(T) text;
  final T value;
  final ValueChanged<T> onChanged;
  const Pick({
    super.key,
    required this.label,
    required this.values,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: [for (final v in values) DropdownMenuItem<T>(value: v, child: Text(text(v), overflow: TextOverflow.ellipsis))],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

/// Düz metin alanı.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.onChanged,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        obscureText: obscure,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 17),
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Tarih seçme satırı.
class DateRow extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? first;
  final DateTime? last;
  const DateRow({super.key, required this.label, required this.value, required this.onChanged, this.first, this.last});

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_rounded),
      title: Text(label),
      subtitle: Text(loc.formatFullDate(value)),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: first ?? DateTime(1800),
          lastDate: last ?? DateTime(2300),
        );
        if (d != null) onChanged(d);
      },
    );
  }
}

// --------------------------------------------------------------- sensör

/// Bir sensör akışını dinler; [timeout] içinde veri gelmezse ya da hata
/// olursa [available] false olur.
class SensorWatch<T> {
  StreamSubscription<T>? _sub;
  Timer? _timer;
  bool? available;
  T? last;

  void start(Stream<T> Function() open, void Function(T) onData, VoidCallback onState,
      {Duration timeout = const Duration(seconds: 3)}) {
    try {
      _sub = open().listen((e) {
        last = e;
        if (available != true) {
          available = true;
          onState();
        }
        onData(e);
      }, onError: (Object _) {
        available = false;
        onState();
      }, cancelOnError: true);
    } catch (_) {
      available = false;
      onState();
      return;
    }
    _timer = Timer(timeout, () {
      if (available == null) {
        available = false;
        onState();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
  }
}

// --------------------------------------------------------------- izin

/// İzin açıklaması bir kez gösterildi mi?
Future<bool> rationaleOnce(BuildContext context, ToolContext t, String perm, IconData icon) async {
  if (await t.store.readBool('perm.$perm')) return true;
  if (!context.mounted) return false;
  final ok = await explainPermission(context, lang: t.lang, icon: icon, reason: L(t, 'perm_$perm'));
  if (ok) await t.store.writeBool('perm.$perm', true);
  return ok;
}


// --------------------------------------------------------------- tarih

/// Günün başlangıcı (yerel).
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [a]'dan [b]'ye takvim günü farkı (yaz saatinden etkilenmez).
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

String two(int v) => v.toString().padLeft(2, '0');

/// yyyy-mm-dd
String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';

/// 24 saat biçimi.
String hhmm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// Yerel kısa tarih (MaterialLocalizations).
String fmtDate(BuildContext context, DateTime d) => MaterialLocalizations.of(context).formatMediumDate(d);

/// Ay adı (yılsız).
String monthName(BuildContext context, int m) =>
    MaterialLocalizations.of(context).formatMonthYear(DateTime(2001, m)).replaceAll(RegExp(r'[0-9]'), '').trim();

/// Basit sayı biçimi.
String num1(double v, [int digits = 1]) => formatNumber(double.parse(v.toStringAsFixed(digits)), digits: digits);

/// "Bugün", "N gün kaldı", "N gün geçti".
String dueText(ToolContext t, int days) {
  if (days == 0) return L(t, 'today');
  if (days > 0) return Lf(t, 'in_days', {'n': days});
  return Lf(t, 'days_ago', {'n': -days});
}

// --------------------------------------------------------------- kayıt

/// Rastgele olmayan, kısa benzersiz kimlik.
String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

/// Silme onayı.
Future<bool> confirmDelete(BuildContext context, ToolContext t, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(L(t, 'delete')),
      content: Text(what),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(L(t, 'cancel'))),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(L(t, 'delete'))),
      ],
    ),
  );
  return ok ?? false;
}

/// Ödüllü reklamla (ya da Premium ile) bugün açılan ekstra.
class UnlockCard extends StatelessWidget {
  final ToolContext t;
  final String feature;
  final VoidCallback onUnlocked;
  const UnlockCard({super.key, required this.t, required this.feature, required this.onUnlocked});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(children: [
        Text(L(t, 'extra_locked'), style: const TextStyle(color: Colors.white70)),
        AppButton(
          label: t.tx('unlock_ad'),
          icon: Icons.ondemand_video_rounded,
          onPressed: () async {
            if (await t.unlockForToday(feature)) onUnlocked();
          },
        ),
      ]),
    );
  }
}
