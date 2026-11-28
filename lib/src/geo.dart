/// Konum ve saat dilimi: gömülü şehirler, yaz saati kuralları, isteğe bağlı
/// GPS ve şehir seçici. Konum yalnızca kullanıcı "Konumumu kullan" derse
/// istenir; şehir seçmek her zaman mümkündür.
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:studio_core/apps/apps.dart';

import 'common.dart';
import 'data/cities.dart';
import 'fold.dart';

class City {
  final String name;
  final double lat, lng;

  /// Standart UTC farkı (saat).
  final double std;

  /// Yaz saati kuralı: N, E, U, A, G.
  final String rule;
  const City(this.name, this.lat, this.lng, this.std, this.rule);

  /// [utc] anındaki UTC farkı (saat).
  double offsetAt(DateTime utc) => std + (dstActive(rule, utc.toUtc(), std) ? 1 : 0);
}

final List<City> kCities = [
  for (final line in kCityData.trim().split('\n'))
    () {
      final p = line.split('|');
      return City(p[0], double.parse(p[1]), double.parse(p[2]), double.parse(p[3]), p[4]);
    }(),
];

City cityByName(String name) => kCities.firstWhere((c) => c.name == name, orElse: () => kCities.firstWhere((c) => c.name == 'İstanbul'));

DateTime _nthSunday(int y, int m, int n) {
  var d = DateTime.utc(y, m, 1);
  while (d.weekday != DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  return d.add(Duration(days: 7 * (n - 1)));
}

DateTime _lastWeekday(int y, int m, int weekday) {
  var d = DateTime.utc(y, m + 1, 1).subtract(const Duration(days: 1));
  while (d.weekday != weekday) {
    d = d.subtract(const Duration(days: 1));
  }
  return d;
}

/// Yaz saati yürürlükte mi? Kurallar yürürlükteki yasalara göre sadeleştirilmiştir.
bool dstActive(String rule, DateTime utc, double std) {
  final y = utc.year;
  switch (rule) {
    case 'E': // Mart'ın son pazarı 01:00 UTC → Ekim'in son pazarı 01:00 UTC
      final a = _lastWeekday(y, 3, DateTime.sunday).add(const Duration(hours: 1));
      final b = _lastWeekday(y, 10, DateTime.sunday).add(const Duration(hours: 1));
      return !utc.isBefore(a) && utc.isBefore(b);
    case 'U': // Mart'ın 2. pazarı 02:00 yerel → Kasım'ın 1. pazarı 02:00 yerel
      final a = _nthSunday(y, 3, 2).add(Duration(minutes: ((2 - std) * 60).round()));
      final b = _nthSunday(y, 11, 1).add(Duration(minutes: ((1 - std) * 60).round()));
      return !utc.isBefore(a) && utc.isBefore(b);
    case 'A': // Ekim'in 1. pazarı → Nisan'ın 1. pazarı (güney yarımküre)
      final end = _nthSunday(y, 4, 1).add(Duration(minutes: ((2 - std) * 60).round()));
      final start = _nthSunday(y, 10, 1).add(Duration(minutes: ((2 - std) * 60).round()));
      return utc.isBefore(end) || !utc.isBefore(start);
    case 'G': // Nisan'ın son cuması → Ekim'in son perşembesi (gün sonu)
      final a = _lastWeekday(y, 4, DateTime.friday).subtract(Duration(minutes: (std * 60).round()));
      final b = _lastWeekday(y, 10, DateTime.thursday).add(Duration(minutes: ((24 - std) * 60).round()));
      return !utc.isBefore(a) && utc.isBefore(b);
    default:
      return false;
  }
}

/// Konum izni: önce açıklama, sonra sistem isteği.
Future<bool> locationReady(BuildContext context, ToolContext t) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      if (!context.mounted) return false;
      if (!await rationaleOnce(context, t, 'location', Icons.location_on_rounded)) return false;
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  } catch (_) {
    return false;
  }
}

/// Tek seferlik konum (yoksa null).
Future<Position?> currentPosition(BuildContext context, ToolContext t) async {
  if (!await locationReady(context, t)) return null;
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 20)),
    );
  } catch (_) {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}

/// Seçili yer: bir şehir ya da cihaz konumu (cihazın saat dilimiyle).
class Place {
  final String name;
  final double lat, lng;
  final City? city;
  const Place(this.name, this.lat, this.lng, this.city);

  /// [day] günündeki UTC farkı (saat).
  double offsetOn(DateTime day) {
    final noon = DateTime(day.year, day.month, day.day, 12);
    final c = city;
    if (c != null) return c.offsetAt(DateTime.utc(day.year, day.month, day.day, 12));
    return noon.timeZoneOffset.inMinutes / 60;
  }

  Map<String, Object?> toMap() => {'name': name, 'lat': lat, 'lng': lng, 'city': city?.name};

  static Place fromMap(Map<String, Object?> m) {
    final cn = m['city'] as String?;
    if (cn != null) {
      final c = cityByName(cn);
      return Place(c.name, c.lat, c.lng, c);
    }
    return Place(m['name'] as String? ?? 'GPS', (m['lat'] as num?)?.toDouble() ?? 41.01, (m['lng'] as num?)?.toDouble() ?? 28.98, null);
  }

  static Place ofCity(City c) => Place(c.name, c.lat, c.lng, c);
}

Future<Place> loadPlace(ToolContext t) async {
  final m = await t.store.readMap('place');
  if (m.isEmpty) return Place.ofCity(cityByName(t.lang == 'tr' ? 'İstanbul' : 'Makkah'));
  return Place.fromMap(m);
}

Future<void> savePlace(ToolContext t, Place p) => t.store.writeMap('place', p.toMap());

/// Yer seçme satırı: şehir listesi ya da "Konumumu kullan".
class PlaceRow extends StatelessWidget {
  final ToolContext t;
  final Place place;
  final ValueChanged<Place> onChanged;
  const PlaceRow({super.key, required this.t, required this.place, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(children: [
        const Icon(Icons.place_rounded, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Text('${place.lat.toStringAsFixed(2)}°, ${place.lng.toStringAsFixed(2)}°',
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
        IconButton(
          tooltip: L(t, 'city'),
          icon: const Icon(Icons.location_city_rounded),
          onPressed: () async {
            final c = await pickCity(context, t);
            if (c != null) onChanged(Place.ofCity(c));
          },
        ),
        IconButton(
          tooltip: L(t, 'use_location'),
          icon: const Icon(Icons.my_location_rounded),
          onPressed: () async {
            final p = await currentPosition(context, t);
            if (!context.mounted) return;
            if (p == null) {
              ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(SnackBar(content: Text(t.tx(t.isWeb ? 'web_unavailable' : 'not_available'))));
              return;
            }
            onChanged(Place(L(t, 'my_location'), p.latitude, p.longitude, null));
          },
        ),
      ]),
    );
  }
}

/// Aranabilir şehir listesi.
Future<City?> pickCity(BuildContext context, ToolContext t) {
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    builder: (c) => _CitySheet(t),
  );
}

class _CitySheet extends StatefulWidget {
  final ToolContext t;
  const _CitySheet(this.t);

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.folded;
    final list = kCities.where((c) => q.isEmpty || c.name.folded.contains(q)).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: widget.t.tx('search')),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(list[i].name),
                subtitle: Text('UTC${list[i].std >= 0 ? '+' : ''}${formatNumber(list[i].std)}'),
                onTap: () => Navigator.pop(context, list[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
