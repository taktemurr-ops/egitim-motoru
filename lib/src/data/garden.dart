/// Sebze ve otlar: sıra üzeri ve sıra arası mesafe (cm), açık alana ekim /
/// dikim ayları (kuzey yarımküre ılıman iklim), hasada gün ve iyi / kötü
/// komşular. Genel bahçecilik bilgisinden özgün seçki; bölgeye göre değişir.
library;

class Crop {
  final String id;
  final List<String> name;
  final int inRow, betweenRows;
  final List<int> months;
  final int days;
  final List<String> good, bad;
  const Crop(this.id, this.name, this.inRow, this.betweenRows, this.months, this.days, this.good, this.bad);
}

const List<Crop> kCrops = [
  Crop('tomato', ['Domates', 'Tomato'], 50, 80, [4, 5], 75, ['basil', 'carrot', 'onion', 'parsley', 'lettuce'], ['potato', 'corn']),
  Crop('pepper', ['Biber', 'Pepper'], 40, 60, [5], 70, ['basil', 'onion', 'carrot'], ['bean']),
  Crop('eggplant', ['Patlıcan', 'Aubergine'], 50, 70, [5], 80, ['bean', 'pepper'], ['potato']),
  Crop('cucumber', ['Salatalık', 'Cucumber'], 40, 100, [5, 6], 60, ['bean', 'pea', 'lettuce', 'corn'], ['potato']),
  Crop('zucchini', ['Kabak', 'Courgette'], 80, 100, [5, 6], 55, ['bean', 'corn', 'pea'], ['potato']),
  Crop('lettuce', ['Marul', 'Lettuce'], 25, 30, [3, 4, 5, 8, 9], 50, ['carrot', 'radish', 'strawberry', 'cucumber'], []),
  Crop('spinach', ['Ispanak', 'Spinach'], 10, 30, [3, 4, 9], 45, ['strawberry', 'pea', 'radish'], []),
  Crop('carrot', ['Havuç', 'Carrot'], 5, 25, [3, 4, 5, 6, 7], 75, ['onion', 'lettuce', 'tomato', 'pea'], []),
  Crop('radish', ['Turp', 'Radish'], 4, 15, [3, 4, 5, 8, 9], 30, ['lettuce', 'pea', 'carrot', 'spinach'], []),
  Crop('onion', ['Soğan', 'Onion'], 10, 25, [3, 4, 9], 100, ['carrot', 'tomato', 'lettuce', 'beet'], ['bean', 'pea']),
  Crop('garlic', ['Sarımsak', 'Garlic'], 12, 25, [10, 11], 240, ['tomato', 'carrot', 'beet'], ['bean', 'pea']),
  Crop('potato', ['Patates', 'Potato'], 30, 70, [3, 4], 100, ['bean', 'corn', 'cabbage'], ['tomato', 'cucumber', 'zucchini']),
  Crop('bean', ['Fasulye', 'Bean'], 10, 45, [5, 6], 60, ['corn', 'carrot', 'cucumber', 'potato'], ['onion', 'garlic']),
  Crop('pea', ['Bezelye', 'Pea'], 5, 45, [2, 3, 4], 65, ['carrot', 'radish', 'cucumber', 'corn'], ['onion', 'garlic']),
  Crop('corn', ['Mısır', 'Sweetcorn'], 30, 75, [5, 6], 85, ['bean', 'pea', 'cucumber', 'zucchini'], ['tomato']),
  Crop('cabbage', ['Lahana', 'Cabbage'], 45, 60, [4, 7], 90, ['onion', 'potato', 'beet'], ['strawberry']),
  Crop('beet', ['Pancar', 'Beetroot'], 10, 30, [4, 5, 6, 7], 60, ['onion', 'lettuce', 'cabbage'], []),
  Crop('parsley', ['Maydanoz', 'Parsley'], 15, 30, [3, 4, 5], 75, ['tomato', 'carrot'], []),
  Crop('basil', ['Fesleğen', 'Basil'], 25, 30, [5, 6], 60, ['tomato', 'pepper'], []),
  Crop('strawberry', ['Çilek', 'Strawberry'], 30, 60, [3, 4, 8, 9], 90, ['lettuce', 'spinach', 'bean'], ['cabbage']),
];

Crop cropById(String id) => kCrops.firstWhere((c) => c.id == id);

/// Bir yatağa (cm) sığan bitki sayısı.
int plantsFit(Crop c, double widthCm, double lengthCm) {
  if (widthCm <= 0 || lengthCm <= 0) return 0;
  final rows = (widthCm / c.betweenRows).floor() + 1;
  final per = (lengthCm / c.inRow).floor() + 1;
  return (widthCm < c.betweenRows ? 1 : rows) * (lengthCm < c.inRow ? 1 : per);
}
