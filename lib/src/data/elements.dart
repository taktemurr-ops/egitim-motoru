/// 118 element: simge | İngilizce ad | Türkçe ad | standart atom kütlesi
/// (IUPAC, yuvarlanmış; kararsız elementlerde en kararlı izotopun kütle
/// numarası köşeli parantezle). Kamu bilgisi.
library;

import 'element_names.dart';

const String kElementData = '''
H|Hydrogen|Hidrojen|1.008
He|Helium|Helyum|4.0026
Li|Lithium|Lityum|6.94
Be|Beryllium|Berilyum|9.0122
B|Boron|Bor|10.81
C|Carbon|Karbon|12.011
N|Nitrogen|Azot|14.007
O|Oxygen|Oksijen|15.999
F|Fluorine|Flor|18.998
Ne|Neon|Neon|20.180
Na|Sodium|Sodyum|22.990
Mg|Magnesium|Magnezyum|24.305
Al|Aluminium|Alüminyum|26.982
Si|Silicon|Silisyum|28.085
P|Phosphorus|Fosfor|30.974
S|Sulfur|Kükürt|32.06
Cl|Chlorine|Klor|35.45
Ar|Argon|Argon|39.95
K|Potassium|Potasyum|39.098
Ca|Calcium|Kalsiyum|40.078
Sc|Scandium|Skandiyum|44.956
Ti|Titanium|Titanyum|47.867
V|Vanadium|Vanadyum|50.942
Cr|Chromium|Krom|51.996
Mn|Manganese|Mangan|54.938
Fe|Iron|Demir|55.845
Co|Cobalt|Kobalt|58.933
Ni|Nickel|Nikel|58.693
Cu|Copper|Bakır|63.546
Zn|Zinc|Çinko|65.38
Ga|Gallium|Galyum|69.723
Ge|Germanium|Germanyum|72.630
As|Arsenic|Arsenik|74.922
Se|Selenium|Selenyum|78.971
Br|Bromine|Brom|79.904
Kr|Krypton|Kripton|83.798
Rb|Rubidium|Rubidyum|85.468
Sr|Strontium|Stronsiyum|87.62
Y|Yttrium|İtriyum|88.906
Zr|Zirconium|Zirkonyum|91.224
Nb|Niobium|Niyobyum|92.906
Mo|Molybdenum|Molibden|95.95
Tc|Technetium|Teknesyum|[98]
Ru|Ruthenium|Rutenyum|101.07
Rh|Rhodium|Rodyum|102.91
Pd|Palladium|Paladyum|106.42
Ag|Silver|Gümüş|107.87
Cd|Cadmium|Kadmiyum|112.41
In|Indium|İndiyum|114.82
Sn|Tin|Kalay|118.71
Sb|Antimony|Antimon|121.76
Te|Tellurium|Tellür|127.60
I|Iodine|İyot|126.90
Xe|Xenon|Ksenon|131.29
Cs|Caesium|Sezyum|132.91
Ba|Barium|Baryum|137.33
La|Lanthanum|Lantan|138.91
Ce|Cerium|Seryum|140.12
Pr|Praseodymium|Praseodim|140.91
Nd|Neodymium|Neodim|144.24
Pm|Promethium|Prometyum|[145]
Sm|Samarium|Samaryum|150.36
Eu|Europium|Evropiyum|151.96
Gd|Gadolinium|Gadolinyum|157.25
Tb|Terbium|Terbiyum|158.93
Dy|Dysprosium|Disprozyum|162.50
Ho|Holmium|Holmiyum|164.93
Er|Erbium|Erbiyum|167.26
Tm|Thulium|Tulyum|168.93
Yb|Ytterbium|İterbiyum|173.05
Lu|Lutetium|Lutesyum|174.97
Hf|Hafnium|Hafniyum|178.49
Ta|Tantalum|Tantal|180.95
W|Tungsten|Tungsten|183.84
Re|Rhenium|Renyum|186.21
Os|Osmium|Osmiyum|190.23
Ir|Iridium|İridyum|192.22
Pt|Platinum|Platin|195.08
Au|Gold|Altın|196.97
Hg|Mercury|Cıva|200.59
Tl|Thallium|Talyum|204.38
Pb|Lead|Kurşun|207.2
Bi|Bismuth|Bizmut|208.98
Po|Polonium|Polonyum|[209]
At|Astatine|Astatin|[210]
Rn|Radon|Radon|[222]
Fr|Francium|Fransiyum|[223]
Ra|Radium|Radyum|[226]
Ac|Actinium|Aktinyum|[227]
Th|Thorium|Toryum|232.04
Pa|Protactinium|Protaktinyum|231.04
U|Uranium|Uranyum|238.03
Np|Neptunium|Neptünyum|[237]
Pu|Plutonium|Plütonyum|[244]
Am|Americium|Amerikyum|[243]
Cm|Curium|Küriyum|[247]
Bk|Berkelium|Berkelyum|[247]
Cf|Californium|Kaliforniyum|[251]
Es|Einsteinium|Aynştaynyum|[252]
Fm|Fermium|Fermiyum|[257]
Md|Mendelevium|Mendelevyum|[258]
No|Nobelium|Nobelyum|[259]
Lr|Lawrencium|Lavrensiyum|[262]
Rf|Rutherfordium|Rutherfordiyum|[267]
Db|Dubnium|Dubniyum|[268]
Sg|Seaborgium|Seaborgiyum|[269]
Bh|Bohrium|Bohriyum|[270]
Hs|Hassium|Hassiyum|[269]
Mt|Meitnerium|Meitneriyum|[278]
Ds|Darmstadtium|Darmstadtiyum|[281]
Rg|Roentgenium|Röntgenyum|[282]
Cn|Copernicium|Kopernikyum|[285]
Nh|Nihonium|Nihonyum|[286]
Fl|Flerovium|Flerovyum|[289]
Mc|Moscovium|Moskovyum|[290]
Lv|Livermorium|Livermoryum|[293]
Ts|Tennessine|Tenesin|[294]
Og|Oganesson|Oganesson|[294]
''';

class ChemElement {
  final int z;
  final String symbol;
  final List<String> name;
  final String mass;
  const ChemElement(this.z, this.symbol, this.name, this.mass);
}

final List<ChemElement> kElements = [
  for (final (i, line) in kElementData.trim().split('\n').indexed)
    () {
      final p = line.split('|');
      return ChemElement(i + 1, p[0], kElementNames[i], p[3]);
    }(),
];
