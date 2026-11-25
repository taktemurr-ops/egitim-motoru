/// Parlak yıldızlar (J2000): ad | sağ açıklık (saat) | sapma (derece) |
/// kadir. Konumlar, kamu malı Yale Parlak Yıldız Kataloğu ve Hipparcos
/// değerlerinden yuvarlanmıştır. Takımyıldız çizgileri özgün seçkidir.
library;

const String kStarData = '''
Sirius|6.752|-16.716|-1.46
Canopus|6.399|-52.696|-0.74
Arcturus|14.261|19.182|-0.05
Rigil Kentaurus|14.660|-60.834|-0.27
Vega|18.616|38.784|0.03
Capella|5.278|45.998|0.08
Rigel|5.242|-8.202|0.13
Procyon|7.655|5.225|0.34
Achernar|1.629|-57.237|0.46
Betelgeuse|5.919|7.407|0.50
Hadar|14.064|-60.373|0.61
Altair|19.846|8.868|0.77
Acrux|12.443|-63.099|0.77
Aldebaran|4.599|16.509|0.85
Antares|16.490|-26.432|0.96
Spica|13.420|-11.161|0.97
Pollux|7.755|28.026|1.14
Fomalhaut|22.961|-29.622|1.16
Deneb|20.690|45.280|1.25
Mimosa|12.795|-59.689|1.25
Regulus|10.140|11.967|1.35
Adhara|6.977|-28.972|1.50
Castor|7.577|31.888|1.58
Shaula|17.560|-37.104|1.62
Gacrux|12.519|-57.113|1.63
Bellatrix|5.419|6.350|1.64
Elnath|5.438|28.608|1.65
Miaplacidus|9.220|-69.717|1.67
Alnilam|5.604|-1.202|1.69
Alnair|22.137|-46.961|1.73
Alnitak|5.679|-1.943|1.77
Alioth|12.900|55.960|1.77
Dubhe|11.062|61.751|1.79
Mirfak|3.405|49.861|1.79
Wezen|7.140|-26.393|1.83
Kaus Australis|18.403|-34.385|1.85
Alkaid|13.792|49.313|1.86
Sargas|17.622|-42.998|1.87
Menkalinan|5.992|44.948|1.90
Atria|16.811|-69.028|1.91
Alhena|6.629|16.399|1.93
Peacock|20.427|-56.735|1.94
Polaris|2.530|89.264|1.98
Mirzam|6.378|-17.956|1.98
Alphard|9.460|-8.659|1.98
Hamal|2.120|23.462|2.00
Algieba|10.333|19.842|2.01
Diphda|0.727|-17.987|2.04
Nunki|18.921|-26.297|2.05
Mirach|1.162|35.621|2.05
Alpheratz|0.140|29.091|2.06
Saiph|5.796|-9.670|2.06
Kochab|14.845|74.156|2.08
Rasalhague|17.582|12.560|2.08
Almach|2.065|42.330|2.10
Algol|3.136|40.956|2.12
Denebola|11.818|14.572|2.14
Mizar|13.399|54.925|2.23
Mintaka|5.533|-0.299|2.23
Sadr|20.370|40.257|2.23
Schedar|0.675|56.537|2.24
Eltanin|17.943|51.489|2.24
Caph|0.153|59.150|2.28
Dschubba|16.006|-22.622|2.29
Merak|11.031|56.382|2.37
Scheat|23.063|28.083|2.42
Phecda|11.897|53.695|2.44
Navi|0.945|60.717|2.47
Gienah|20.770|33.970|2.48
Markab|23.079|15.205|2.49
Menkar|3.038|4.090|2.54
Ruchbah|1.430|60.235|2.68
Algenib|0.220|15.184|2.83
Alcyone|3.791|24.105|2.87
Fawaris|19.750|45.131|2.87
Albireo|19.512|27.960|3.08
Megrez|12.257|57.033|3.31
Segin|1.907|63.670|3.37
''';

/// Takımyıldız çizgileri (yıldız adları çiftler halinde).
const List<(String, List<String>)> kConstellations = [
  ('Ursa Major', ['Dubhe', 'Merak', 'Merak', 'Phecda', 'Phecda', 'Megrez', 'Megrez', 'Dubhe', 'Megrez', 'Alioth', 'Alioth', 'Mizar', 'Mizar', 'Alkaid']),
  ('Orion', ['Betelgeuse', 'Bellatrix', 'Bellatrix', 'Mintaka', 'Mintaka', 'Alnilam', 'Alnilam', 'Alnitak', 'Alnitak', 'Saiph', 'Mintaka', 'Rigel', 'Betelgeuse', 'Alnitak']),
  ('Cassiopeia', ['Caph', 'Schedar', 'Schedar', 'Navi', 'Navi', 'Ruchbah', 'Ruchbah', 'Segin']),
  ('Cygnus', ['Deneb', 'Sadr', 'Sadr', 'Albireo', 'Gienah', 'Sadr', 'Sadr', 'Fawaris']),
  ('Pegasus', ['Alpheratz', 'Scheat', 'Scheat', 'Markab', 'Markab', 'Algenib', 'Algenib', 'Alpheratz']),
  ('Crux', ['Acrux', 'Gacrux', 'Mimosa', 'Gacrux']),
  ('Gemini', ['Castor', 'Pollux']),
  ('Summer Triangle', ['Vega', 'Deneb', 'Deneb', 'Altair', 'Altair', 'Vega']),
];

class Star {
  final String name;
  final double ra, dec, mag;
  const Star(this.name, this.ra, this.dec, this.mag);
}

final List<Star> kStars = [
  for (final line in kStarData.trim().split('\n'))
    () {
      final p = line.split('|');
      return Star(p[0], double.parse(p[1]), double.parse(p[2]), double.parse(p[3]));
    }(),
];
