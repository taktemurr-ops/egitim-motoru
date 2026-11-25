/// Formül kitabı: başlık, gösterim, değişkenler ve hesap (özgün seçki).
library;

import 'dart:math' as math;

class FVar {
  final String sym;
  final List<String> name;
  final String unit;
  const FVar(this.sym, this.name, this.unit);
}

class Formula {
  final int cat;
  final List<String> title;
  final String expr;
  final List<FVar> vars;
  final FVar result;
  final double Function(List<double> v) calc;
  const Formula(this.cat, this.title, this.expr, this.vars, this.result, this.calc);
}

/// Kategoriler: 0 geometri, 1 cebir, 2 fizik, 3 kimya.
final List<Formula> kFormulas = [
  Formula(0, ['Dairenin alanı', 'Area of a circle'], 'A = π·r²', const [FVar('r', ['Yarıçap', 'Radius'], '')],
      const FVar('A', ['Alan', 'Area'], ''), (v) => math.pi * v[0] * v[0]),
  Formula(0, ['Dairenin çevresi', 'Circumference'], 'C = 2·π·r', const [FVar('r', ['Yarıçap', 'Radius'], '')],
      const FVar('C', ['Çevre', 'Circumference'], ''), (v) => 2 * math.pi * v[0]),
  Formula(0, ['Üçgenin alanı', 'Area of a triangle'], 'A = a·h / 2',
      const [FVar('a', ['Taban', 'Base'], ''), FVar('h', ['Yükseklik', 'Height'], '')], const FVar('A', ['Alan', 'Area'], ''),
      (v) => v[0] * v[1] / 2),
  Formula(0, ['Dikdörtgenin alanı', 'Area of a rectangle'], 'A = a·b',
      const [FVar('a', ['Kenar a', 'Side a'], ''), FVar('b', ['Kenar b', 'Side b'], '')], const FVar('A', ['Alan', 'Area'], ''),
      (v) => v[0] * v[1]),
  Formula(0, ['Yamuğun alanı', 'Area of a trapezoid'], 'A = (a + c)·h / 2',
      const [FVar('a', ['Alt taban', 'Base a'], ''), FVar('c', ['Üst taban', 'Base c'], ''), FVar('h', ['Yükseklik', 'Height'], '')],
      const FVar('A', ['Alan', 'Area'], ''), (v) => (v[0] + v[1]) * v[2] / 2),
  Formula(0, ['Pisagor bağıntısı', 'Pythagorean theorem'], 'c = √(a² + b²)',
      const [FVar('a', ['Dik kenar a', 'Leg a'], ''), FVar('b', ['Dik kenar b', 'Leg b'], '')],
      const FVar('c', ['Hipotenüs', 'Hypotenuse'], ''), (v) => math.sqrt(v[0] * v[0] + v[1] * v[1])),
  Formula(0, ['Kürenin hacmi', 'Volume of a sphere'], 'V = 4/3·π·r³', const [FVar('r', ['Yarıçap', 'Radius'], '')],
      const FVar('V', ['Hacim', 'Volume'], ''), (v) => 4 / 3 * math.pi * math.pow(v[0], 3)),
  Formula(0, ['Kürenin yüzey alanı', 'Surface area of a sphere'], 'A = 4·π·r²', const [FVar('r', ['Yarıçap', 'Radius'], '')],
      const FVar('A', ['Alan', 'Area'], ''), (v) => 4 * math.pi * v[0] * v[0]),
  Formula(0, ['Silindirin hacmi', 'Volume of a cylinder'], 'V = π·r²·h',
      const [FVar('r', ['Yarıçap', 'Radius'], ''), FVar('h', ['Yükseklik', 'Height'], '')], const FVar('V', ['Hacim', 'Volume'], ''),
      (v) => math.pi * v[0] * v[0] * v[1]),
  Formula(0, ['Koninin hacmi', 'Volume of a cone'], 'V = π·r²·h / 3',
      const [FVar('r', ['Yarıçap', 'Radius'], ''), FVar('h', ['Yükseklik', 'Height'], '')], const FVar('V', ['Hacim', 'Volume'], ''),
      (v) => math.pi * v[0] * v[0] * v[1] / 3),
  Formula(1, ['İki nokta arası uzaklık', 'Distance between two points'], 'd = √((x₂−x₁)² + (y₂−y₁)²)',
      const [FVar('x₁', ['x₁', 'x₁'], ''), FVar('y₁', ['y₁', 'y₁'], ''), FVar('x₂', ['x₂', 'x₂'], ''), FVar('y₂', ['y₂', 'y₂'], '')],
      const FVar('d', ['Uzaklık', 'Distance'], ''), (v) => math.sqrt(math.pow(v[2] - v[0], 2) + math.pow(v[3] - v[1], 2))),
  Formula(1, ['Doğrunun eğimi', 'Slope of a line'], 'm = (y₂−y₁) / (x₂−x₁)',
      const [FVar('x₁', ['x₁', 'x₁'], ''), FVar('y₁', ['y₁', 'y₁'], ''), FVar('x₂', ['x₂', 'x₂'], ''), FVar('y₂', ['y₂', 'y₂'], '')],
      const FVar('m', ['Eğim', 'Slope'], ''), (v) => (v[3] - v[1]) / (v[2] - v[0])),
  Formula(1, ['Aritmetik dizi toplamı', 'Arithmetic series sum'], 'Sₙ = n·(a₁ + aₙ) / 2',
      const [FVar('n', ['Terim sayısı', 'Number of terms'], ''), FVar('a₁', ['İlk terim', 'First term'], ''), FVar('aₙ', ['Son terim', 'Last term'], '')],
      const FVar('Sₙ', ['Toplam', 'Sum'], ''), (v) => v[0] * (v[1] + v[2]) / 2),
  Formula(1, ['Geometrik dizi toplamı', 'Geometric series sum'], 'Sₙ = a₁·(1 − rⁿ) / (1 − r)',
      const [FVar('a₁', ['İlk terim', 'First term'], ''), FVar('r', ['Ortak çarpan', 'Common ratio'], ''), FVar('n', ['Terim sayısı', 'Number of terms'], '')],
      const FVar('Sₙ', ['Toplam', 'Sum'], ''), (v) => v[1] == 1 ? v[0] * v[2] : v[0] * (1 - math.pow(v[1], v[2])) / (1 - v[1])),
  Formula(1, ['Yüzde değişim', 'Percentage change'], 'Δ% = (yeni − eski) / eski · 100',
      const [FVar('eski', ['Eski değer', 'Old value'], ''), FVar('yeni', ['Yeni değer', 'New value'], '')],
      const FVar('Δ%', ['Değişim', 'Change'], '%'), (v) => (v[1] - v[0]) / v[0] * 100),
  Formula(2, ['Hız', 'Speed'], 'v = x / t', const [FVar('x', ['Yol', 'Distance'], 'm'), FVar('t', ['Zaman', 'Time'], 's')],
      const FVar('v', ['Hız', 'Speed'], 'm/s'), (v) => v[0] / v[1]),
  Formula(2, ['Newton\'un 2. yasası', 'Newton\'s second law'], 'F = m·a',
      const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('a', ['İvme', 'Acceleration'], 'm/s²')], const FVar('F', ['Kuvvet', 'Force'], 'N'),
      (v) => v[0] * v[1]),
  Formula(2, ['Ağırlık', 'Weight'], 'G = m·g', const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('g', ['Yerçekimi ivmesi (9,81)', 'Gravity (9.81)'], 'm/s²')],
      const FVar('G', ['Ağırlık', 'Weight'], 'N'), (v) => v[0] * v[1]),
  Formula(2, ['Kinetik enerji', 'Kinetic energy'], 'Eₖ = ½·m·v²',
      const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('v', ['Hız', 'Speed'], 'm/s')], const FVar('Eₖ', ['Enerji', 'Energy'], 'J'),
      (v) => 0.5 * v[0] * v[1] * v[1]),
  Formula(2, ['Potansiyel enerji', 'Potential energy'], 'Eₚ = m·g·h',
      const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('g', ['Yerçekimi ivmesi (9,81)', 'Gravity (9.81)'], 'm/s²'), FVar('h', ['Yükseklik', 'Height'], 'm')],
      const FVar('Eₚ', ['Enerji', 'Energy'], 'J'), (v) => v[0] * v[1] * v[2]),
  Formula(2, ['İş', 'Work'], 'W = F·x', const [FVar('F', ['Kuvvet', 'Force'], 'N'), FVar('x', ['Yol', 'Distance'], 'm')],
      const FVar('W', ['İş', 'Work'], 'J'), (v) => v[0] * v[1]),
  Formula(2, ['Güç', 'Power'], 'P = W / t', const [FVar('W', ['İş', 'Work'], 'J'), FVar('t', ['Zaman', 'Time'], 's')],
      const FVar('P', ['Güç', 'Power'], 'W'), (v) => v[0] / v[1]),
  Formula(2, ['Momentum', 'Momentum'], 'p = m·v', const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('v', ['Hız', 'Speed'], 'm/s')],
      const FVar('p', ['Momentum', 'Momentum'], 'kg·m/s'), (v) => v[0] * v[1]),
  Formula(2, ['Basınç', 'Pressure'], 'P = F / A', const [FVar('F', ['Kuvvet', 'Force'], 'N'), FVar('A', ['Yüzey', 'Area'], 'm²')],
      const FVar('P', ['Basınç', 'Pressure'], 'Pa'), (v) => v[0] / v[1]),
  Formula(2, ['Özkütle', 'Density'], 'ρ = m / V', const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('V', ['Hacim', 'Volume'], 'm³')],
      const FVar('ρ', ['Özkütle', 'Density'], 'kg/m³'), (v) => v[0] / v[1]),
  Formula(2, ['Ohm yasası', 'Ohm\'s law'], 'V = I·R', const [FVar('I', ['Akım', 'Current'], 'A'), FVar('R', ['Direnç', 'Resistance'], 'Ω')],
      const FVar('V', ['Gerilim', 'Voltage'], 'V'), (v) => v[0] * v[1]),
  Formula(2, ['Elektriksel güç', 'Electric power'], 'P = V·I', const [FVar('V', ['Gerilim', 'Voltage'], 'V'), FVar('I', ['Akım', 'Current'], 'A')],
      const FVar('P', ['Güç', 'Power'], 'W'), (v) => v[0] * v[1]),
  Formula(2, ['Dalga hızı', 'Wave speed'], 'v = f·λ', const [FVar('f', ['Frekans', 'Frequency'], 'Hz'), FVar('λ', ['Dalga boyu', 'Wavelength'], 'm')],
      const FVar('v', ['Hız', 'Speed'], 'm/s'), (v) => v[0] * v[1]),
  Formula(2, ['Basit sarkacın periyodu', 'Pendulum period'], 'T = 2π·√(L / g)',
      const [FVar('L', ['Uzunluk', 'Length'], 'm'), FVar('g', ['Yerçekimi ivmesi (9,81)', 'Gravity (9.81)'], 'm/s²')],
      const FVar('T', ['Periyot', 'Period'], 's'), (v) => 2 * math.pi * math.sqrt(v[0] / v[1])),
  Formula(2, ['Isı', 'Heat'], 'Q = m·c·ΔT',
      const [FVar('m', ['Kütle', 'Mass'], 'kg'), FVar('c', ['Öz ısı (su: 4186)', 'Specific heat (water: 4186)'], 'J/kg·K'), FVar('ΔT', ['Sıcaklık farkı', 'Temperature change'], 'K')],
      const FVar('Q', ['Isı', 'Heat'], 'J'), (v) => v[0] * v[1] * v[2]),
  Formula(3, ['İdeal gaz yasası', 'Ideal gas law'], 'P = n·R·T / V',
      const [FVar('n', ['Mol sayısı', 'Amount'], 'mol'), FVar('T', ['Sıcaklık', 'Temperature'], 'K'), FVar('V', ['Hacim', 'Volume'], 'L')],
      const FVar('P', ['Basınç', 'Pressure'], 'atm'), (v) => v[0] * 0.082057 * v[1] / v[2]),
  Formula(3, ['Mol sayısı', 'Amount of substance'], 'n = m / M',
      const [FVar('m', ['Kütle', 'Mass'], 'g'), FVar('M', ['Mol kütlesi', 'Molar mass'], 'g/mol')], const FVar('n', ['Mol', 'Moles'], 'mol'),
      (v) => v[0] / v[1]),
  Formula(3, ['Molarite', 'Molarity'], 'M = n / V',
      const [FVar('n', ['Mol sayısı', 'Amount'], 'mol'), FVar('V', ['Çözelti hacmi', 'Solution volume'], 'L')],
      const FVar('M', ['Derişim', 'Concentration'], 'mol/L'), (v) => v[0] / v[1]),
  Formula(3, ['Seyreltme', 'Dilution'], 'M₂ = M₁·V₁ / V₂',
      const [FVar('M₁', ['İlk derişim', 'Initial concentration'], 'mol/L'), FVar('V₁', ['İlk hacim', 'Initial volume'], 'L'), FVar('V₂', ['Son hacim', 'Final volume'], 'L')],
      const FVar('M₂', ['Son derişim', 'Final concentration'], 'mol/L'), (v) => v[0] * v[1] / v[2]),
  Formula(3, ['pH', 'pH'], 'pH = −log₁₀[H⁺]', const [FVar('[H⁺]', ['H⁺ derişimi', 'H⁺ concentration'], 'mol/L')],
      const FVar('pH', ['pH', 'pH'], ''), (v) => -math.log(v[0]) / math.ln10),
];
