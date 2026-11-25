/// Küçük moleküllerin 3B koordinatları (Å), standart bağ uzunluğu ve
/// açılarından özgün olarak hesaplanmıştır (yaklaşık geometri).
library;

import 'dart:math' as math;

class Atom {
  final String el;
  final double x, y, z;
  const Atom(this.el, this.x, this.y, this.z);
}

class Molecule {
  final List<String> name;
  final String formula;
  final List<Atom> atoms;
  const Molecule(this.name, this.formula, this.atoms);
}

List<Atom> _tetra(String center, String sub, double r) {
  final a = r / math.sqrt(3);
  return [
    Atom(center, 0, 0, 0),
    Atom(sub, a, a, a),
    Atom(sub, a, -a, -a),
    Atom(sub, -a, a, -a),
    Atom(sub, -a, -a, a),
  ];
}

List<Atom> _benzene() {
  final out = <Atom>[];
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3;
    out.add(Atom('C', 1.39 * math.cos(a), 1.39 * math.sin(a), 0));
    out.add(Atom('H', 2.48 * math.cos(a), 2.48 * math.sin(a), 0));
  }
  return out;
}

List<Atom> _nacl() {
  final out = <Atom>[];
  for (var x = 0; x < 3; x++) {
    for (var y = 0; y < 3; y++) {
      for (var z = 0; z < 3; z++) {
        out.add(Atom((x + y + z).isEven ? 'Na' : 'Cl', (x - 1) * 2.82, (y - 1) * 2.82, (z - 1) * 2.82));
      }
    }
  }
  return out;
}

final List<Molecule> kMolecules = [
  const Molecule(['Su', 'Water'], 'H₂O', [Atom('O', 0, 0, 0), Atom('H', 0.757, 0.586, 0), Atom('H', -0.757, 0.586, 0)]),
  const Molecule(['Karbondioksit', 'Carbon dioxide'], 'CO₂', [Atom('C', 0, 0, 0), Atom('O', 1.16, 0, 0), Atom('O', -1.16, 0, 0)]),
  Molecule(const ['Metan', 'Methane'], 'CH₄', _tetra('C', 'H', 1.09)),
  const Molecule(['Amonyak', 'Ammonia'], 'NH₃',
      [Atom('N', 0, 0, 0.1), Atom('H', 0.94, 0, -0.28), Atom('H', -0.47, 0.814, -0.28), Atom('H', -0.47, -0.814, -0.28)]),
  const Molecule(['Oksijen', 'Oxygen'], 'O₂', [Atom('O', 0.6, 0, 0), Atom('O', -0.6, 0, 0)]),
  const Molecule(['Azot', 'Nitrogen'], 'N₂', [Atom('N', 0.55, 0, 0), Atom('N', -0.55, 0, 0)]),
  const Molecule(['Hidrojen', 'Hydrogen'], 'H₂', [Atom('H', 0.37, 0, 0), Atom('H', -0.37, 0, 0)]),
  const Molecule(['Hidrojen klorür', 'Hydrogen chloride'], 'HCl', [Atom('H', -0.64, 0, 0), Atom('Cl', 0.64, 0, 0)]),
  const Molecule(['Karbon monoksit', 'Carbon monoxide'], 'CO', [Atom('C', -0.56, 0, 0), Atom('O', 0.56, 0, 0)]),
  const Molecule(['Hidrojen sülfür', 'Hydrogen sulfide'], 'H₂S', [Atom('S', 0, 0, 0), Atom('H', 0.96, -0.93, 0), Atom('H', -0.96, -0.93, 0)]),
  const Molecule(['Kükürt dioksit', 'Sulfur dioxide'], 'SO₂', [Atom('S', 0, 0, 0), Atom('O', 1.235, -0.72, 0), Atom('O', -1.235, -0.72, 0)]),
  const Molecule(['Ozon', 'Ozone'], 'O₃', [Atom('O', 0, 0, 0), Atom('O', 1.09, -0.66, 0), Atom('O', -1.09, -0.66, 0)]),
  const Molecule(['Hidrojen siyanür', 'Hydrogen cyanide'], 'HCN', [Atom('H', -1.66, 0, 0), Atom('C', -0.6, 0, 0), Atom('N', 0.56, 0, 0)]),
  const Molecule(['Formaldehit', 'Formaldehyde'], 'CH₂O', [Atom('C', 0, 0, 0), Atom('O', 1.21, 0, 0), Atom('H', -0.6, 0.94, 0), Atom('H', -0.6, -0.94, 0)]),
  const Molecule(['Etan', 'Ethane'], 'C₂H₆', [
    Atom('C', 0.765, 0, 0), Atom('C', -0.765, 0, 0),
    Atom('H', 1.16, 1.02, 0), Atom('H', 1.16, -0.51, 0.88), Atom('H', 1.16, -0.51, -0.88),
    Atom('H', -1.16, -1.02, 0), Atom('H', -1.16, 0.51, 0.88), Atom('H', -1.16, 0.51, -0.88),
  ]),
  const Molecule(['Eten (etilen)', 'Ethene (ethylene)'], 'C₂H₄', [
    Atom('C', 0.667, 0, 0), Atom('C', -0.667, 0, 0),
    Atom('H', 1.23, 0.92, 0), Atom('H', 1.23, -0.92, 0), Atom('H', -1.23, 0.92, 0), Atom('H', -1.23, -0.92, 0),
  ]),
  const Molecule(['Etin (asetilen)', 'Ethyne (acetylene)'], 'C₂H₂',
      [Atom('C', 0.6, 0, 0), Atom('C', -0.6, 0, 0), Atom('H', 1.66, 0, 0), Atom('H', -1.66, 0, 0)]),
  const Molecule(['Metanol', 'Methanol'], 'CH₃OH', [
    Atom('C', 0, 0, 0), Atom('O', 1.43, 0, 0), Atom('H', 1.75, 0.9, 0),
    Atom('H', -0.36, 1.03, 0), Atom('H', -0.36, -0.51, 0.89), Atom('H', -0.36, -0.51, -0.89),
  ]),
  const Molecule(['Etanol', 'Ethanol'], 'C₂H₅OH', [
    Atom('C', 0, 0, 0), Atom('C', 1.52, 0, 0), Atom('O', 2.0, 1.33, 0), Atom('H', 2.95, 1.3, 0),
    Atom('H', -0.39, 1.02, 0), Atom('H', -0.39, -0.51, 0.89), Atom('H', -0.39, -0.51, -0.89),
    Atom('H', 1.9, -0.51, 0.89), Atom('H', 1.9, -0.51, -0.89),
  ]),
  const Molecule(['Hidrojen peroksit', 'Hydrogen peroxide'], 'H₂O₂',
      [Atom('O', 0.73, 0, 0), Atom('O', -0.73, 0, 0), Atom('H', 0.95, 0.9, 0.3), Atom('H', -0.95, -0.2, 0.9)]),
  Molecule(const ['Karbon tetraklorür', 'Carbon tetrachloride'], 'CCl₄', _tetra('C', 'Cl', 1.77)),
  Molecule(const ['Benzen', 'Benzene'], 'C₆H₆', _benzene()),
  Molecule(const ['Sodyum klorür (kristal)', 'Sodium chloride (crystal)'], 'NaCl', _nacl()),
];

/// Kovalent yarıçaplar (Å) — bağ bulmak için.
const Map<String, double> kCovalent = {'H': 0.31, 'C': 0.76, 'N': 0.71, 'O': 0.66, 'S': 1.05, 'Cl': 1.02, 'Na': 1.66};

/// CPK renkleri (yaygın gelenek).
const Map<String, int> kCpk = {
  'H': 0xFFFFFFFF, 'C': 0xFF505050, 'N': 0xFF3050F8, 'O': 0xFFFF0D0D, 'S': 0xFFFFFF30, 'Cl': 0xFF1FF01F, 'Na': 0xFFAB5CF2,
};

/// Atomlar arasındaki bağlar (uzaklık < yarıçaplar toplamı × 1,25).
List<(int, int)> bondsOf(Molecule m) {
  final out = <(int, int)>[];
  for (var i = 0; i < m.atoms.length; i++) {
    for (var j = i + 1; j < m.atoms.length; j++) {
      final a = m.atoms[i], b = m.atoms[j];
      final d = math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2) + math.pow(a.z - b.z, 2));
      final r = (kCovalent[a.el] ?? 0.8) + (kCovalent[b.el] ?? 0.8);
      final ionic = a.el == 'Na' || b.el == 'Na';
      if (ionic ? (d < 2.9 && a.el != b.el) : d < r * 1.25) out.add((i, j));
    }
  }
  return out;
}
