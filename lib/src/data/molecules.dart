/// Küçük moleküllerin 3B koordinatları (Å), standart bağ uzunluğu ve
/// açılarından özgün olarak hesaplanmıştır (yaklaşık geometri).
// 33 dil: proto/apps/egitim/content/mkcontent.py ile üretildi; elle düzenlemeyin.
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
  const Molecule(['Su', 'Water', 'Wasser', 'Agua', 'Eau', 'الماء', 'آب', 'מים', 'پانی', 'Вода', 'Вода', 'Woda', 'Voda', 'Apă', 'Víz', 'Νερό', 'Acqua', 'Água', 'Water', 'Vatten', 'Vand', 'Vann', 'Vesi', '水', '물', '水', 'पानी', 'পানি', 'Air', 'Air', 'น้ำ', 'Nước', 'Tubig'], 'H₂O', [Atom('O', 0, 0, 0), Atom('H', 0.757, 0.586, 0), Atom('H', -0.757, 0.586, 0)]),
  const Molecule(['Karbondioksit', 'Carbon dioxide', 'Kohlenstoffdioxid', 'Dióxido de carbono', 'Dioxyde de carbone', 'ثاني أكسيد الكربون', 'دی‌اکسید کربن', 'פחמן דו-חמצני', 'کاربن ڈائی آکسائیڈ', 'Углекислый газ', 'Вуглекислий газ', 'Dwutlenek węgla', 'Oxid uhličitý', 'Dioxid de carbon', 'Szén-dioxid', 'Διοξείδιο του άνθρακα', 'Anidride carbonica', 'Dióxido de carbono', 'Koolstofdioxide', 'Koldioxid', 'Kuldioxid', 'Karbondioksid', 'Hiilidioksidi', '二酸化炭素', '이산화 탄소', '二氧化碳', 'कार्बन डाइऑक्साइड', 'কার্বন ডাইঅক্সাইড', 'Karbon dioksida', 'Karbon dioksida', 'คาร์บอนไดออกไซด์', 'Carbon dioxide', 'Carbon dioxide'], 'CO₂', [Atom('C', 0, 0, 0), Atom('O', 1.16, 0, 0), Atom('O', -1.16, 0, 0)]),
  Molecule(const ['Metan', 'Methane', 'Methan', 'Metano', 'Méthane', 'الميثان', 'متان', 'מתאן', 'میتھین', 'Метан', 'Метан', 'Metan', 'Methan', 'Metan', 'Metán', 'Μεθάνιο', 'Metano', 'Metano', 'Methaan', 'Metan', 'Metan', 'Metan', 'Metaani', 'メタン', '메테인', '甲烷', 'मीथेन', 'মিথেন', 'Metana', 'Metana', 'มีเทน', 'Methane', 'Methane'], 'CH₄', _tetra('C', 'H', 1.09)),
  const Molecule(['Amonyak', 'Ammonia', 'Ammoniak', 'Amoníaco', 'Ammoniac', 'الأمونيا', 'آمونیاک', 'אמוניה', 'امونیا', 'Аммиак', 'Аміак', 'Amoniak', 'Amoniak', 'Amoniac', 'Ammónia', 'Αμμωνία', 'Ammoniaca', 'Amônia', 'Ammoniak', 'Ammoniak', 'Ammoniak', 'Ammoniakk', 'Ammoniakki', 'アンモニア', '암모니아', '氨', 'अमोनिया', 'অ্যামোনিয়া', 'Amonia', 'Ammonia', 'แอมโมเนีย', 'Ammonia', 'Ammonia'], 'NH₃',
      [Atom('N', 0, 0, 0.1), Atom('H', 0.94, 0, -0.28), Atom('H', -0.47, 0.814, -0.28), Atom('H', -0.47, -0.814, -0.28)]),
  const Molecule(['Oksijen', 'Oxygen', 'Sauerstoff', 'Oxígeno', 'Dioxygène', 'الأكسجين', 'اکسیژن', 'חמצן', 'آکسیجن', 'Кислород', 'Кисень', 'Tlen', 'Kyslík', 'Oxigen', 'Oxigén', 'Οξυγόνο', 'Ossigeno', 'Oxigênio', 'Zuurstof', 'Syre', 'Ilt', 'Oksygen', 'Happi', '酸素', '산소', '氧气', 'ऑक्सीजन', 'অক্সিজেন', 'Oksigen', 'Oksigen', 'ออกซิเจน', 'Oxygen', 'Oxygen'], 'O₂', [Atom('O', 0.6, 0, 0), Atom('O', -0.6, 0, 0)]),
  const Molecule(['Azot', 'Nitrogen', 'Stickstoff', 'Nitrógeno', 'Diazote', 'النيتروجين', 'نیتروژن', 'חנקן', 'نائٹروجن', 'Азот', 'Азот', 'Azot', 'Dusík', 'Azot', 'Nitrogén', 'Άζωτο', 'Azoto', 'Nitrogênio', 'Stikstof', 'Kväve', 'Kvælstof', 'Nitrogen', 'Typpi', '窒素', '질소', '氮气', 'नाइट्रोजन', 'নাইট্রোজেন', 'Nitrogen', 'Nitrogen', 'ไนโตรเจน', 'Nitrogen', 'Nitrogen'], 'N₂', [Atom('N', 0.55, 0, 0), Atom('N', -0.55, 0, 0)]),
  const Molecule(['Hidrojen', 'Hydrogen', 'Wasserstoff', 'Hidrógeno', 'Dihydrogène', 'الهيدروجين', 'هیدروژن', 'מימן', 'ہائیڈروجن', 'Водород', 'Водень', 'Wodór', 'Vodík', 'Hidrogen', 'Hidrogén', 'Υδρογόνο', 'Idrogeno', 'Hidrogênio', 'Waterstof', 'Väte', 'Brint', 'Hydrogen', 'Vety', '水素', '수소', '氢气', 'हाइड्रोजन', 'হাইড্রোজেন', 'Hidrogen', 'Hidrogen', 'ไฮโดรเจน', 'Hydrogen', 'Hydrogen'], 'H₂', [Atom('H', 0.37, 0, 0), Atom('H', -0.37, 0, 0)]),
  const Molecule(['Hidrojen klorür', 'Hydrogen chloride', 'Chlorwasserstoff', 'Cloruro de hidrógeno', 'Chlorure d\'hydrogène', 'كلوريد الهيدروجين', 'هیدروژن کلرید', 'מימן כלורי', 'ہائیڈروجن کلورائیڈ', 'Хлороводород', 'Хлороводень', 'Chlorowodór', 'Chlorovodík', 'Acid clorhidric (gaz)', 'Hidrogén-klorid', 'Υδροχλώριο', 'Acido cloridrico (gas)', 'Cloreto de hidrogênio', 'Waterstofchloride', 'Väteklorid', 'Hydrogenchlorid', 'Hydrogenklorid', 'Vetykloridi', '塩化水素', '염화 수소', '氯化氢', 'हाइड्रोजन क्लोराइड', 'হাইড্রোজেন ক্লোরাইড', 'Hidrogen klorida', 'Hidrogen klorida', 'ไฮโดรเจนคลอไรด์', 'Hydrogen chloride', 'Hydrogen chloride'], 'HCl', [Atom('H', -0.64, 0, 0), Atom('Cl', 0.64, 0, 0)]),
  const Molecule(['Karbon monoksit', 'Carbon monoxide', 'Kohlenstoffmonoxid', 'Monóxido de carbono', 'Monoxyde de carbone', 'أول أكسيد الكربون', 'مونوکسید کربن', 'פחמן חד-חמצני', 'کاربن مونو آکسائیڈ', 'Угарный газ', 'Чадний газ', 'Tlenek węgla', 'Oxid uhelnatý', 'Monoxid de carbon', 'Szén-monoxid', 'Μονοξείδιο του άνθρακα', 'Monossido di carbonio', 'Monóxido de carbono', 'Koolstofmonoxide', 'Kolmonoxid', 'Kulilte', 'Karbonmonoksid', 'Hiilimonoksidi', '一酸化炭素', '일산화 탄소', '一氧化碳', 'कार्बन मोनोऑक्साइड', 'কার্বন মনোক্সাইড', 'Karbon monoksida', 'Karbon monoksida', 'คาร์บอนมอนอกไซด์', 'Carbon monoxide', 'Carbon monoxide'], 'CO', [Atom('C', -0.56, 0, 0), Atom('O', 0.56, 0, 0)]),
  const Molecule(['Hidrojen sülfür', 'Hydrogen sulfide', 'Schwefelwasserstoff', 'Sulfuro de hidrógeno', 'Sulfure d\'hydrogène', 'كبريتيد الهيدروجين', 'هیدروژن سولفید', 'מימן גופרתי', 'ہائیڈروجن سلفائیڈ', 'Сероводород', 'Сірководень', 'Siarkowodór', 'Sulfan', 'Hidrogen sulfurat', 'Kén-hidrogén', 'Υδρόθειο', 'Acido solfidrico', 'Sulfeto de hidrogênio', 'Waterstofsulfide', 'Vätesulfid', 'Hydrogensulfid', 'Hydrogensulfid', 'Rikkivety', '硫化水素', '황화 수소', '硫化氢', 'हाइड्रोजन सल्फाइड', 'হাইড্রোজেন সালফাইড', 'Hidrogen sulfida', 'Hidrogen sulfida', 'ไฮโดรเจนซัลไฟด์', 'Hydrogen sulfide', 'Hydrogen sulfide'], 'H₂S', [Atom('S', 0, 0, 0), Atom('H', 0.96, -0.93, 0), Atom('H', -0.96, -0.93, 0)]),
  const Molecule(['Kükürt dioksit', 'Sulfur dioxide', 'Schwefeldioxid', 'Dióxido de azufre', 'Dioxyde de soufre', 'ثاني أكسيد الكبريت', 'دی‌اکسید گوگرد', 'גופרית דו-חמצנית', 'سلفر ڈائی آکسائیڈ', 'Диоксид серы', 'Діоксид сірки', 'Dwutlenek siarki', 'Oxid siřičitý', 'Dioxid de sulf', 'Kén-dioxid', 'Διοξείδιο του θείου', 'Anidride solforosa', 'Dióxido de enxofre', 'Zwaveldioxide', 'Svaveldioxid', 'Svovldioxid', 'Svoveldioksid', 'Rikkidioksidi', '二酸化硫黄', '이산화 황', '二氧化硫', 'सल्फर डाइऑक्साइड', 'সালফার ডাইঅক্সাইড', 'Sulfur dioksida', 'Sulfur dioksida', 'ซัลเฟอร์ไดออกไซด์', 'Sulfur dioxide', 'Sulfur dioxide'], 'SO₂', [Atom('S', 0, 0, 0), Atom('O', 1.235, -0.72, 0), Atom('O', -1.235, -0.72, 0)]),
  const Molecule(['Ozon', 'Ozone', 'Ozon', 'Ozono', 'Ozone', 'الأوزون', 'ازن', 'אוזון', 'اوزون', 'Озон', 'Озон', 'Ozon', 'Ozon', 'Ozon', 'Ózon', 'Όζον', 'Ozono', 'Ozônio', 'Ozon', 'Ozon', 'Ozon', 'Ozon', 'Otsoni', 'オゾン', '오존', '臭氧', 'ओज़ोन', 'ওজোন', 'Ozon', 'Ozon', 'โอโซน', 'Ozone', 'Ozone'], 'O₃', [Atom('O', 0, 0, 0), Atom('O', 1.09, -0.66, 0), Atom('O', -1.09, -0.66, 0)]),
  const Molecule(['Hidrojen siyanür', 'Hydrogen cyanide', 'Blausäure', 'Cianuro de hidrógeno', 'Cyanure d\'hydrogène', 'سيانيد الهيدروجين', 'هیدروژن سیانید', 'מימן ציאניד', 'ہائیڈروجن سائنائیڈ', 'Циановодород', 'Ціановодень', 'Cyjanowodór', 'Kyanovodík', 'Acid cianhidric', 'Hidrogén-cianid', 'Υδροκυάνιο', 'Acido cianidrico', 'Cianeto de hidrogênio', 'Waterstofcyanide', 'Vätecyanid', 'Hydrogencyanid', 'Hydrogencyanid', 'Syaanivety', 'シアン化水素', '사이안화 수소', '氰化氢', 'हाइड्रोजन सायनाइड', 'হাইড্রোজেন সায়ানাইড', 'Hidrogen sianida', 'Hidrogen sianida', 'ไฮโดรเจนไซยาไนด์', 'Hydrogen cyanide', 'Hydrogen cyanide'], 'HCN', [Atom('H', -1.66, 0, 0), Atom('C', -0.6, 0, 0), Atom('N', 0.56, 0, 0)]),
  const Molecule(['Formaldehit', 'Formaldehyde', 'Formaldehyd', 'Formaldehído', 'Formaldéhyde', 'الفورمالديهايد', 'فرمالدهید', 'פורמלדהיד', 'فارملڈی ہائیڈ', 'Формальдегид', 'Формальдегід', 'Formaldehyd', 'Formaldehyd', 'Formaldehidă', 'Formaldehid', 'Φορμαλδεΰδη', 'Formaldeide', 'Formaldeído', 'Formaldehyde', 'Formaldehyd', 'Formaldehyd', 'Formaldehyd', 'Formaldehydi', 'ホルムアルデヒド', '폼알데하이드', '甲醛', 'फॉर्मेल्डिहाइड', 'ফরমালডিহাইড', 'Formaldehida', 'Formaldehid', 'ฟอร์มาลดีไฮด์', 'Formaldehyde', 'Formaldehyde'], 'CH₂O', [Atom('C', 0, 0, 0), Atom('O', 1.21, 0, 0), Atom('H', -0.6, 0.94, 0), Atom('H', -0.6, -0.94, 0)]),
  const Molecule(['Etan', 'Ethane', 'Ethan', 'Etano', 'Éthane', 'الإيثان', 'اتان', 'אתאן', 'ایتھین', 'Этан', 'Етан', 'Etan', 'Ethan', 'Etan', 'Etán', 'Αιθάνιο', 'Etano', 'Etano', 'Ethaan', 'Etan', 'Ethan', 'Etan', 'Etaani', 'エタン', '에테인', '乙烷', 'एथेन', 'ইথেন', 'Etana', 'Etana', 'อีเทน', 'Ethane', 'Ethane'], 'C₂H₆', [
    Atom('C', 0.765, 0, 0), Atom('C', -0.765, 0, 0),
    Atom('H', 1.16, 1.02, 0), Atom('H', 1.16, -0.51, 0.88), Atom('H', 1.16, -0.51, -0.88),
    Atom('H', -1.16, -1.02, 0), Atom('H', -1.16, 0.51, 0.88), Atom('H', -1.16, 0.51, -0.88),
  ]),
  const Molecule(['Eten (etilen)', 'Ethene (ethylene)', 'Ethen (Ethylen)', 'Eteno (etileno)', 'Éthène (éthylène)', 'الإيثين (الإيثيلين)', 'اتن (اتیلن)', 'אתן (אתילן)', 'ایتھیلین', 'Этен (этилен)', 'Етен (етилен)', 'Eten (etylen)', 'Ethen (ethylen)', 'Etenă (etilenă)', 'Etén (etilén)', 'Αιθένιο (αιθυλένιο)', 'Etene (etilene)', 'Eteno (etileno)', 'Etheen (ethyleen)', 'Eten (etylen)', 'Ethen (ethylen)', 'Eten (etylen)', 'Eteeni (etyleeni)', 'エテン（エチレン）', '에텐(에틸렌)', '乙烯', 'एथीन (एथिलीन)', 'ইথিন (ইথিলিন)', 'Etena (etilena)', 'Etena (etilena)', 'เอทีน (เอทิลีน)', 'Ethene (ethylene)', 'Ethene (ethylene)'], 'C₂H₄', [
    Atom('C', 0.667, 0, 0), Atom('C', -0.667, 0, 0),
    Atom('H', 1.23, 0.92, 0), Atom('H', 1.23, -0.92, 0), Atom('H', -1.23, 0.92, 0), Atom('H', -1.23, -0.92, 0),
  ]),
  const Molecule(['Etin (asetilen)', 'Ethyne (acetylene)', 'Ethin (Acetylen)', 'Etino (acetileno)', 'Éthyne (acétylène)', 'الإيثاين (الأسيتيلين)', 'اتین (استیلن)', 'אתין (אצטילן)', 'ایسیٹیلین', 'Этин (ацетилен)', 'Етин (ацетилен)', 'Etyn (acetylen)', 'Ethyn (acetylen)', 'Etină (acetilenă)', 'Etin (acetilén)', 'Αιθίνιο (ακετυλένιο)', 'Etino (acetilene)', 'Etino (acetileno)', 'Ethyn (acetyleen)', 'Etyn (acetylen)', 'Ethyn (acetylen)', 'Etyn (acetylen)', 'Etyyni (asetyleeni)', 'エチン（アセチレン）', '에타인(아세틸렌)', '乙炔', 'एथाइन (एसिटिलीन)', 'ইথাইন (অ্যাসিটিলিন)', 'Etuna (asetilena)', 'Etuna (asetilena)', 'เอไทน์ (อะเซทิลีน)', 'Ethyne (acetylene)', 'Ethyne (acetylene)'], 'C₂H₂',
      [Atom('C', 0.6, 0, 0), Atom('C', -0.6, 0, 0), Atom('H', 1.66, 0, 0), Atom('H', -1.66, 0, 0)]),
  const Molecule(['Metanol', 'Methanol', 'Methanol', 'Metanol', 'Méthanol', 'الميثانول', 'متانول', 'מתנול', 'میتھانول', 'Метанол', 'Метанол', 'Metanol', 'Methanol', 'Metanol', 'Metanol', 'Μεθανόλη', 'Metanolo', 'Metanol', 'Methanol', 'Metanol', 'Methanol', 'Metanol', 'Metanoli', 'メタノール', '메탄올', '甲醇', 'मेथनॉल', 'মিথানল', 'Metanol', 'Metanol', 'เมทานอล', 'Methanol', 'Methanol'], 'CH₃OH', [
    Atom('C', 0, 0, 0), Atom('O', 1.43, 0, 0), Atom('H', 1.75, 0.9, 0),
    Atom('H', -0.36, 1.03, 0), Atom('H', -0.36, -0.51, 0.89), Atom('H', -0.36, -0.51, -0.89),
  ]),
  const Molecule(['Etanol', 'Ethanol', 'Ethanol', 'Etanol', 'Éthanol', 'الإيثانول', 'اتانول', 'אתנול', 'ایتھانول', 'Этанол', 'Етанол', 'Etanol', 'Ethanol', 'Etanol', 'Etanol', 'Αιθανόλη', 'Etanolo', 'Etanol', 'Ethanol', 'Etanol', 'Ethanol', 'Etanol', 'Etanoli', 'エタノール', '에탄올', '乙醇', 'एथनॉल', 'ইথানল', 'Etanol', 'Etanol', 'เอทานอล', 'Ethanol', 'Ethanol'], 'C₂H₅OH', [
    Atom('C', 0, 0, 0), Atom('C', 1.52, 0, 0), Atom('O', 2.0, 1.33, 0), Atom('H', 2.95, 1.3, 0),
    Atom('H', -0.39, 1.02, 0), Atom('H', -0.39, -0.51, 0.89), Atom('H', -0.39, -0.51, -0.89),
    Atom('H', 1.9, -0.51, 0.89), Atom('H', 1.9, -0.51, -0.89),
  ]),
  const Molecule(['Hidrojen peroksit', 'Hydrogen peroxide', 'Wasserstoffperoxid', 'Peróxido de hidrógeno', 'Peroxyde d\'hydrogène', 'بيروكسيد الهيدروجين', 'آب اکسیژنه', 'מי חמצן', 'ہائیڈروجن پیرو آکسائیڈ', 'Пероксид водорода', 'Пероксид водню', 'Nadtlenek wodoru', 'Peroxid vodíku', 'Apă oxigenată', 'Hidrogén-peroxid', 'Υπεροξείδιο του υδρογόνου', 'Perossido di idrogeno', 'Peróxido de hidrogênio', 'Waterstofperoxide', 'Väteperoxid', 'Brintoverilte', 'Hydrogenperoksid', 'Vetyperoksidi', '過酸化水素', '과산화 수소', '过氧化氢', 'हाइड्रोजन पेरोक्साइड', 'হাইড্রোজেন পারক্সাইড', 'Hidrogen peroksida', 'Hidrogen peroksida', 'ไฮโดรเจนเปอร์ออกไซด์', 'Hydrogen peroxide', 'Hydrogen peroxide'], 'H₂O₂',
      [Atom('O', 0.73, 0, 0), Atom('O', -0.73, 0, 0), Atom('H', 0.95, 0.9, 0.3), Atom('H', -0.95, -0.2, 0.9)]),
  Molecule(const ['Karbon tetraklorür', 'Carbon tetrachloride', 'Tetrachlormethan', 'Tetracloruro de carbono', 'Tétrachlorure de carbone', 'رباعي كلوريد الكربون', 'کربن تتراکلرید', 'פחמן טטרה-כלורי', 'کاربن ٹیٹرا کلورائیڈ', 'Тетрахлорметан', 'Тетрахлорметан', 'Tetrachlorometan', 'Tetrachlormethan', 'Tetraclorură de carbon', 'Szén-tetraklorid', 'Τετραχλωράνθρακας', 'Tetracloruro di carbonio', 'Tetracloreto de carbono', 'Tetrachloormethaan', 'Koltetraklorid', 'Tetrachlormethan', 'Karbontetraklorid', 'Hiilitetrakloridi', '四塩化炭素', '사염화 탄소', '四氯化碳', 'कार्बन टेट्राक्लोराइड', 'কার্বন টেট্রাক্লোরাইড', 'Karbon tetraklorida', 'Karbon tetraklorida', 'คาร์บอนเตตระคลอไรด์', 'Carbon tetrachloride', 'Carbon tetrachloride'], 'CCl₄', _tetra('C', 'Cl', 1.77)),
  Molecule(const ['Benzen', 'Benzene', 'Benzol', 'Benceno', 'Benzène', 'البنزين العطري', 'بنزن', 'בנזן', 'بینزین', 'Бензол', 'Бензен', 'Benzen', 'Benzen', 'Benzen', 'Benzol', 'Βενζόλιο', 'Benzene', 'Benzeno', 'Benzeen', 'Bensen', 'Benzen', 'Benzen', 'Bentseeni', 'ベンゼン', '벤젠', '苯', 'बेंज़ीन', 'বেনজিন', 'Benzena', 'Benzena', 'เบนซีน', 'Benzene', 'Benzene'], 'C₆H₆', _benzene()),
  Molecule(const ['Sodyum klorür (kristal)', 'Sodium chloride (crystal)', 'Natriumchlorid (Kristall)', 'Cloruro de sodio (cristal)', 'Chlorure de sodium (cristal)', 'كلوريد الصوديوم (بلورة)', 'سدیم کلرید (بلور)', 'נתרן כלורי (גביש)', 'سوڈیم کلورائیڈ (قلم)', 'Хлорид натрия (кристалл)', 'Хлорид натрію (кристал)', 'Chlorek sodu (kryształ)', 'Chlorid sodný (krystal)', 'Clorură de sodiu (cristal)', 'Nátrium-klorid (kristály)', 'Χλωριούχο νάτριο (κρύσταλλος)', 'Cloruro di sodio (cristallo)', 'Cloreto de sódio (cristal)', 'Natriumchloride (kristal)', 'Natriumklorid (kristall)', 'Natriumchlorid (krystal)', 'Natriumklorid (krystall)', 'Natriumkloridi (kide)', '塩化ナトリウム（結晶）', '염화 나트륨(결정)', '氯化钠（晶体）', 'सोडियम क्लोराइड (क्रिस्टल)', 'সোডিয়াম ক্লোরাইড (কেলাস)', 'Natrium klorida (kristal)', 'Natrium klorida (hablur)', 'โซเดียมคลอไรด์ (ผลึก)', 'Natri chloride (tinh thể)', 'Sodium chloride (kristal)'], 'NaCl', _nacl()),
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
