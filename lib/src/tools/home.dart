/// Kayıt motorunu kullanan ev, plan ve takip uygulamalarının alan tanımları
/// ve hazır listeleri (özgün metin; diğer dillerde İngilizce gösterilir).
library;

import 'package:flutter/material.dart';
import 'package:studio_core/apps/apps.dart';

import '../common.dart';
import 'records.dart';

const _name = FieldSpec('name', 'name', FType.text, optional: false);
const _note = FieldSpec('note', 'note', FType.text);
const _every = FieldSpec('every', 'every_days', FType.days);
const _last = FieldSpec('last', 'last_done', FType.date);

RecordTemplate _tp(String tr, String en, [Map<String, Object?> v = const {}]) => RecordTemplate([tr, en], v);

// ------------------------------------------------------------ bitki sulama

final RecordSpec plantSpec = RecordSpec(
  fields: const [_name, _every, _last, FieldSpec('place', 'location_in_home', FType.text), _note],
  due: DueMode.interval,
  dateField: 'last',
  daysField: 'every',
  canMarkDone: true,
  notify: true,
  sort: SortMode.due,
  templates: [
    _tp('Kaktüs / sukulent', 'Cactus / succulent', {'every': 14}),
    _tp('Paşa kılıcı', 'Snake plant', {'every': 14}),
    _tp('Salon sarmaşığı (Pothos)', 'Pothos', {'every': 7}),
    _tp('Barış çiçeği', 'Peace lily', {'every': 5}),
    _tp('Orkide', 'Orchid', {'every': 7}),
    _tp('Fesleğen (saksı)', 'Basil (pot)', {'every': 2}),
    _tp('Monstera', 'Monstera', {'every': 7}),
    _tp('Ficus', 'Ficus', {'every': 7}),
  ],
);

// ------------------------------------------------------------ ev envanteri

const RecordSpec inventorySpec = RecordSpec(
  fields: [
    _name,
    FieldSpec('room', 'room', FType.text),
    FieldSpec('qty', 'quantity', FType.number),
    FieldSpec('value', 'value_money', FType.number),
    FieldSpec('bought', 'purchase_date', FType.date),
    FieldSpec('serial', 'serial_no', FType.text),
    _note,
  ],
  sumField: 'value',
  groupField: 'room',
  sort: SortMode.group,
);

// ------------------------------------------------------------ doğum günü

const RecordSpec birthdaySpec = RecordSpec(
  fields: [_name, FieldSpec('date', 'birth', FType.date, optional: false), FieldSpec('gift', 'gift_idea', FType.text), _note],
  due: DueMode.yearly,
  dateField: 'date',
  notify: true,
  sort: SortMode.due,
);

// ------------------------------------------------------------ seyahat listesi

final RecordSpec travelChecklistSpec = RecordSpec(
  fields: const [
    _name,
    FieldSpec('done', 'packed', FType.check),
    FieldSpec('group', 'group', FType.choice, choices: ['g_docs', 'g_clothes', 'g_tech', 'g_health', 'g_other']),
  ],
  checkField: 'done',
  groupField: 'group',
  sort: SortMode.group,
  templates: [
    _tp('Kimlik / pasaport', 'ID / passport', {'group': 'g_docs'}),
    _tp('Biletler ve rezervasyonlar', 'Tickets and bookings', {'group': 'g_docs'}),
    _tp('Seyahat sigortası belgesi', 'Travel insurance papers', {'group': 'g_docs'}),
    _tp('Nakit ve kartlar', 'Cash and cards', {'group': 'g_docs'}),
    _tp('Ehliyet', "Driver's licence", {'group': 'g_docs'}),
    _tp('İç çamaşırı ve çorap', 'Underwear and socks', {'group': 'g_clothes'}),
    _tp('Tişörtler', 'T-shirts', {'group': 'g_clothes'}),
    _tp('Pantolon / etek', 'Trousers / skirts', {'group': 'g_clothes'}),
    _tp('Ceket / yağmurluk', 'Jacket / raincoat', {'group': 'g_clothes'}),
    _tp('Pijama', 'Pyjamas', {'group': 'g_clothes'}),
    _tp('Rahat ayakkabı', 'Comfortable shoes', {'group': 'g_clothes'}),
    _tp('Mayo', 'Swimwear', {'group': 'g_clothes'}),
    _tp('Telefon şarj aleti', 'Phone charger', {'group': 'g_tech'}),
    _tp('Taşınabilir şarj cihazı', 'Power bank', {'group': 'g_tech'}),
    _tp('Priz adaptörü', 'Plug adapter', {'group': 'g_tech'}),
    _tp('Kulaklık', 'Headphones', {'group': 'g_tech'}),
    _tp('Düzenli kullanılan ilaçlar', 'Regular medicines', {'group': 'g_health'}),
    _tp('Diş fırçası ve macun', 'Toothbrush and toothpaste', {'group': 'g_health'}),
    _tp('Güneş kremi', 'Sunscreen', {'group': 'g_health'}),
    _tp('Küçük ilk yardım çantası', 'Small first-aid kit', {'group': 'g_health'}),
    _tp('Güneş gözlüğü', 'Sunglasses', {'group': 'g_other'}),
    _tp('Su şişesi', 'Water bottle', {'group': 'g_other'}),
    _tp('Ev anahtarları', 'House keys', {'group': 'g_other'}),
  ],
);

// ------------------------------------------------------------ hediye listesi

const RecordSpec giftSpec = RecordSpec(
  fields: [
    FieldSpec('person', 'person', FType.text, optional: false),
    FieldSpec('name', 'gift_idea', FType.text),
    FieldSpec('budget', 'budget', FType.number),
    FieldSpec('occasion', 'occasion', FType.text),
    FieldSpec('date', 'date', FType.date),
    FieldSpec('done', 'bought', FType.check),
  ],
  titleField: 'person',
  checkField: 'done',
  sumField: 'budget',
  groupField: 'person',
  sort: SortMode.group,
);

// ------------------------------------------------------------ ev bakım planı

final RecordSpec homeCareSpec = RecordSpec(
  fields: const [_name, _every, _last, _note],
  due: DueMode.interval,
  dateField: 'last',
  daysField: 'every',
  canMarkDone: true,
  notify: true,
  sort: SortMode.due,
  templates: [
    _tp('Duman dedektörünü test et', 'Test smoke detector', {'every': 30}),
    _tp('Klima filtresini temizle', 'Clean air-conditioner filter', {'every': 90}),
    _tp('Kombi / kazan bakımı', 'Boiler service', {'every': 365}),
    _tp('Çamaşır makinesi temizliği', 'Clean washing machine', {'every': 30}),
    _tp('Bulaşık makinesi filtresi', 'Dishwasher filter', {'every': 30}),
    _tp('Su arıtma filtresi', 'Water filter cartridge', {'every': 180}),
    _tp('Buzdolabı arkasının tozu', 'Dust fridge coils', {'every': 180}),
    _tp('Yağmur olukları', 'Clear gutters', {'every': 180}),
    _tp('Yangın tüpü kontrolü', 'Check fire extinguisher', {'every': 365}),
    _tp('Gider tıkanıklığı önleme', 'Flush drains', {'every': 60}),
  ],
);

// ------------------------------------------------------------ araç bakım

final RecordSpec carSpec = RecordSpec(
  fields: const [
    _name,
    FieldSpec('last', 'last_done', FType.date),
    FieldSpec('km', 'odometer_km', FType.number),
    FieldSpec('next_km', 'next_km', FType.number),
    _every,
    FieldSpec('cost', 'cost', FType.number),
    _note,
  ],
  due: DueMode.interval,
  dateField: 'last',
  daysField: 'every',
  canMarkDone: true,
  sumField: 'cost',
  sort: SortMode.due,
  templates: [
    _tp('Motor yağı ve filtre', 'Engine oil and filter', {'every': 365}),
    _tp('Hava filtresi', 'Air filter', {'every': 365}),
    _tp('Polen filtresi', 'Cabin filter', {'every': 365}),
    _tp('Fren kontrolü', 'Brake check', {'every': 365}),
    _tp('Lastik rotasyonu ve basınç', 'Tyre rotation and pressure', {'every': 180}),
    _tp('Kış / yaz lastiği değişimi', 'Seasonal tyre change', {'every': 182}),
    _tp('Araç muayenesi', 'Vehicle inspection', {'every': 730}),
    _tp('Trafik sigortası yenileme', 'Insurance renewal', {'every': 365}),
    _tp('Akü kontrolü', 'Battery check', {'every': 365}),
    _tp('Silecek lastikleri', 'Wiper blades', {'every': 365}),
  ],
);

// ------------------------------------------------------------ düğün planlayıcı

final RecordSpec weddingSpec = RecordSpec(
  fields: const [
    _name,
    FieldSpec('group', 'group', FType.choice, choices: ['g_task', 'g_budget', 'g_guest']),
    FieldSpec('cost', 'cost', FType.number),
    FieldSpec('date', 'date', FType.date),
    FieldSpec('done', 'done', FType.check),
    _note,
  ],
  checkField: 'done',
  sumField: 'cost',
  groupField: 'group',
  sort: SortMode.group,
  templates: [
    _tp('Tarih ve bütçeyi belirle', 'Set the date and budget', {'group': 'g_task'}),
    _tp('Mekânı ayırt', 'Book the venue', {'group': 'g_task'}),
    _tp('Nikâh / tören başvurusu', 'Ceremony / registry booking', {'group': 'g_task'}),
    _tp('Davetli listesini çıkar', 'Draft the guest list', {'group': 'g_task'}),
    _tp('Davetiyeleri gönder', 'Send invitations', {'group': 'g_task'}),
    _tp('Fotoğrafçı', 'Photographer', {'group': 'g_budget'}),
    _tp('Gelinlik / takım elbise', 'Dress / suit', {'group': 'g_budget'}),
    _tp('Yüzükler', 'Rings', {'group': 'g_budget'}),
    _tp('Müzik', 'Music', {'group': 'g_budget'}),
    _tp('Yemek / ikram', 'Catering', {'group': 'g_budget'}),
    _tp('Çiçek ve süsleme', 'Flowers and decoration', {'group': 'g_budget'}),
    _tp('Pasta', 'Cake', {'group': 'g_budget'}),
    _tp('Ulaşım', 'Transport', {'group': 'g_budget'}),
    _tp('Balayı', 'Honeymoon', {'group': 'g_budget'}),
  ],
);

// ------------------------------------------------------------ temizlik çizelgesi

final RecordSpec choresSpec = RecordSpec(
  fields: const [_name, FieldSpec('person', 'person', FType.text), _every, _last],
  due: DueMode.interval,
  dateField: 'last',
  daysField: 'every',
  canMarkDone: true,
  notify: true,
  sort: SortMode.due,
  templates: [
    _tp('Bulaşık', 'Dishes', {'every': 1}),
    _tp('Çöpü çıkar', 'Take out the rubbish', {'every': 2}),
    _tp('Mutfak tezgâhı', 'Kitchen counters', {'every': 2}),
    _tp('Süpürge', 'Vacuum', {'every': 7}),
    _tp('Banyo', 'Bathroom', {'every': 7}),
    _tp('Yerleri sil', 'Mop floors', {'every': 7}),
    _tp('Toz al', 'Dust', {'every': 7}),
    _tp('Çarşafları değiştir', 'Change bed sheets', {'every': 7}),
    _tp('Çamaşır', 'Laundry', {'every': 4}),
    _tp('Buzdolabını temizle', 'Clean the fridge', {'every': 30}),
    _tp('Camlar', 'Windows', {'every': 30}),
    _tp('Fırın', 'Oven', {'every': 30}),
  ],
);

// ------------------------------------------------------------ kiler

const RecordSpec pantrySpec = RecordSpec(
  fields: [
    _name,
    FieldSpec('expiry', 'expiry', FType.date, optional: false),
    FieldSpec('qty', 'quantity', FType.number),
    FieldSpec('place', 'location_in_home', FType.text),
  ],
  due: DueMode.expiry,
  dateField: 'expiry',
  sort: SortMode.due,
);

// ------------------------------------------------------------ evcil hayvan

final RecordSpec petSpec = RecordSpec(
  fields: const [
    FieldSpec('name', 'care_item', FType.text, optional: false),
    FieldSpec('pet', 'pet_name', FType.text),
    _last,
    _every,
    FieldSpec('vet', 'vet_note', FType.text),
  ],
  due: DueMode.interval,
  dateField: 'last',
  daysField: 'every',
  canMarkDone: true,
  sort: SortMode.due,
  templates: [
    _tp('Kuduz aşısı', 'Rabies vaccine', {'every': 365}),
    _tp('Karma aşı', 'Combination vaccine', {'every': 365}),
    _tp('İç parazit', 'Deworming', {'every': 90}),
    _tp('Dış parazit', 'Flea and tick treatment', {'every': 30}),
    _tp('Veteriner kontrolü', 'Vet check-up', {'every': 365}),
    _tp('Tırnak kesimi', 'Nail trim', {'every': 30}),
    _tp('Banyo / tımar', 'Bath / grooming', {'every': 30}),
    _tp('Kum kabı değişimi', 'Change litter', {'every': 7}),
  ],
);

List<Widget> petHeader(ToolContext t) => [AppInfoCard(L(t, 'vet_disclaimer'), icon: Icons.pets_rounded)];

// ------------------------------------------------------------ konu takibi

const RecordSpec topicSpec = RecordSpec(
  fields: [
    FieldSpec('name', 'topic', FType.text, optional: false),
    FieldSpec('subject', 'subject', FType.text),
    FieldSpec('status', 'status', FType.choice, choices: ['st_todo', 'st_doing', 'st_done']),
    FieldSpec('solved', 'questions_solved', FType.number),
    _note,
  ],
  statusField: 'status',
  statusDone: 'st_done',
  sumField: 'solved',
  groupField: 'subject',
  sort: SortMode.group,
);

// ------------------------------------------------------------ seyahat günlüğü

const RecordSpec journalSpec = RecordSpec(
  fields: [
    FieldSpec('name', 'place', FType.text, optional: false),
    FieldSpec('date', 'date', FType.date, optional: false),
    FieldSpec('spent', 'cost', FType.number),
    FieldSpec('text', 'note', FType.multiline),
  ],
  dateField: 'date',
  sumField: 'spent',
  sort: SortMode.dateDesc,
);

// ------------------------------------------------------------ deprem çantası

final RecordSpec quakeSpec = RecordSpec(
  fields: const [
    _name,
    FieldSpec('done', 'ready', FType.check),
    FieldSpec('expiry', 'expiry', FType.date),
  ],
  checkField: 'done',
  due: DueMode.expiry,
  dateField: 'expiry',
  planFields: const ['meet_near', 'meet_far', 'contact_out', 'plan_notes'],
  templates: [
    _tp('Su (kişi başı günde ~2 litre, 3 gün)', 'Water (about 2 litres per person per day, 3 days)'),
    _tp('Kolay açılan konserve ve kuru yiyecek', 'Easy-open tins and dry food'),
    _tp('İlk yardım çantası', 'First-aid kit'),
    _tp('Düzenli kullanılan ilaçlar ve reçete kopyası', 'Regular medicines and prescription copies'),
    _tp('El feneri ve yedek pil', 'Torch and spare batteries'),
    _tp('Pilli ya da kurmalı radyo', 'Battery or wind-up radio'),
    _tp('Düdük', 'Whistle'),
    _tp('Toz maskesi', 'Dust masks'),
    _tp('İş eldiveni', 'Work gloves'),
    _tp('Battaniye ya da uyku tulumu', 'Blanket or sleeping bag'),
    _tp('Mevsime uygun yedek kıyafet', 'Spare clothes for the season'),
    _tp('Taşınabilir şarj cihazı', 'Power bank'),
    _tp('Kimlik ve önemli belgelerin kopyaları (su geçirmez poşette)', 'Copies of IDs and key documents (waterproof bag)'),
    _tp('Bir miktar nakit', 'Some cash'),
    _tp('Hijyen malzemeleri ve ıslak mendil', 'Hygiene items and wet wipes'),
    _tp('Çok amaçlı çakı', 'Multi-tool'),
    _tp('Yedek gözlük', 'Spare glasses'),
    _tp('Aile iletişim listesi (kâğıt)', 'Family contact list (on paper)'),
  ],
);

List<Widget> quakeHeader(ToolContext t) => [AppInfoCard(L(t, 'quake_note'), icon: Icons.health_and_safety_rounded)];
