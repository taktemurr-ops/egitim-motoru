/// Rehber içerikleri: ilk yardım, düğümler, çamaşır sembolleri.
///
/// İlk yardım metinleri Kızılay / Uluslararası Kızılhaç ve Kızılay
/// Federasyonu (IFRC) ve Avrupa Resüsitasyon Konseyi'nin kamuya açık
/// yetişkin ilk yardım ilkeleriyle uyumlu olacak şekilde ÖZGÜN olarak
/// yazılmıştır; tıbbi teşhis ya da tedavi içermez. Bebek ve gebelikle ilgili
/// içerik kapsam dışıdır. Yayın öncesinde uzman (ilk yardım eğitmeni)
/// gözden geçirmesi önerilir.
library;

class GuideTopic {
  final List<String> title;
  final List<List<String>> steps;
  final bool urgent;
  const GuideTopic(this.title, this.steps, {this.urgent = false});
}

const List<GuideTopic> kFirstAid = [
  GuideTopic(['Önce güvenlik ve kontrol', 'Safety first and check'], [
    ['Ortamın sizin ve yaralı için güvenli olduğundan emin olun.', 'Make sure the scene is safe for you and the casualty.'],
    ['Kişiye seslenin ve omzuna hafifçe dokunun; yanıt veriyor mu bakın.', 'Speak to the person and tap their shoulder to see if they respond.'],
    ["Yanıt yoksa yüksek sesle yardım isteyin ve 112'yi arayın ya da birinin aramasını sağlayın.", 'If there is no response, shout for help and call the emergency number, or ask someone to.'],
    ['Başı hafifçe geriye eğip çeneyi kaldırın; en fazla 10 saniye normal nefes alıp almadığına bakın.', 'Tilt the head back, lift the chin and check for normal breathing for up to 10 seconds.'],
  ], urgent: true),
  GuideTopic(['Bilinçsiz ama nefes alıyor', 'Unresponsive but breathing'], [
    ['Kişiyi yan yatırın: üstteki bacak dizden bükülü, baş hafif geriye eğik (derlenme pozisyonu).', 'Roll them onto their side: top leg bent at the knee, head tilted slightly back (recovery position).'],
    ['Ağız aşağı baksın; kusmuk ya da sıvı dışarı akabilsin.', 'Keep the mouth pointing down so vomit or fluid can drain.'],
    ["112'yi arayın ve yardım gelene kadar nefesini sürekli kontrol edin.", 'Call the emergency number and keep checking their breathing until help arrives.'],
    ['Omurga yaralanmasından şüpheleniyorsanız gerekmedikçe hareket ettirmeyin.', 'If you suspect a spinal injury, do not move them unless you must.'],
  ], urgent: true),
  GuideTopic(['Nefes almıyor: kalp masajı (yetişkin)', 'Not breathing: CPR (adult)'], [
    ["112'yi arayın; varsa birinden otomatik eksternal defibrilatör (OED) getirmesini isteyin.", 'Call the emergency number and ask someone to bring an automated external defibrillator (AED) if there is one.'],
    ['Ellerinizi üst üste göğsün ortasına koyun; kollarınız düz olsun.', 'Place your hands one on top of the other in the centre of the chest, arms straight.'],
    ['Dakikada 100–120 hızla, yaklaşık 5–6 cm derinliğe bastırın; her basıdan sonra göğsün tam kalkmasına izin verin.', 'Push hard and fast — 100 to 120 times a minute, about 5–6 cm deep — letting the chest rise fully after each push.'],
    ['Eğitim aldıysanız 30 basıdan sonra 2 kurtarıcı nefes verin; almadıysanız kesintisiz bası yapın.', 'If you are trained, give 2 rescue breaths after every 30 compressions; if not, keep doing compressions only.'],
    ['OED gelince açın ve sesli talimatları izleyin. Yardım gelene ya da kişi normal nefes alana kadar sürdürün.', 'When the AED arrives, switch it on and follow its voice prompts. Continue until help takes over or the person breathes normally.'],
  ], urgent: true),
  GuideTopic(['Boğulma / soluk yolu tıkanması (yetişkin)', 'Choking (adult)'], [
    ['Öksürebiliyorsa öksürmeye devam etmesini söyleyin.', 'If they can cough, encourage them to keep coughing.'],
    ['Öksüremiyor ya da konuşamıyorsa öne eğin ve kürek kemikleri arasına avuç içiyle 5 kez sert vurun.', 'If they cannot cough or speak, lean them forward and give up to 5 firm back blows between the shoulder blades.'],
    ['Açılmazsa arkasına geçin, yumruğunuzu göbeğin hemen üstüne koyup 5 kez içe ve yukarı doğru çekin.', 'If that fails, stand behind them, place a fist just above the navel and give up to 5 sharp inward-and-upward thrusts.'],
    ["Tıkanıklık açılana kadar 5 sırt vuruşu ve 5 karın basısını sırayla sürdürün; 112'yi arayın.", 'Keep alternating 5 back blows and 5 thrusts until it clears, and call the emergency number.'],
    ['Bilinci kaybolursa kalp masajına başlayın.', 'If they become unresponsive, start CPR.'],
  ], urgent: true),
  GuideTopic(['Ciddi kanama', 'Severe bleeding'], [
    ['Varsa eldiven giyin; yaraya temiz bir bezle doğrudan ve sıkıca bastırın.', 'Wear gloves if you have them and press firmly and directly on the wound with a clean cloth.'],
    ['Bezi kaldırmayın; kan geçerse üstüne yenisini koyup bastırmayı sürdürün.', 'Do not lift the pad; if blood soaks through, add another on top and keep pressing.'],
    ["112'yi arayın; kişiyi uzandırın ve sıcak tutun.", 'Call the emergency number, help them lie down and keep them warm.'],
    ['Yaraya saplanmış bir cismi çıkarmayın; çevresine baskı uygulayın.', 'Do not remove an embedded object; press around it instead.'],
  ], urgent: true),
  GuideTopic(['Yanık', 'Burns'], [
    ['Yanığı en az 20 dakika serin (buzlu değil) akan suyun altında tutun.', 'Cool the burn under cool (not icy) running water for at least 20 minutes.'],
    ['Yapışmamışsa takı ve giysileri çıkarın.', 'Remove jewellery and clothing unless it is stuck to the burn.'],
    ['Soğuttuktan sonra streç film ya da temiz, tüy bırakmayan bir bezle gevşekçe örtün.', 'After cooling, cover it loosely with cling film or a clean, non-fluffy cloth.'],
    ['Krem, yağ ya da diş macunu sürmeyin; su kabarcıklarını patlatmayın.', 'Do not put creams, oils or toothpaste on it, and do not burst blisters.'],
    ["Büyük ya da derin yanıklarda, yüz ve ellerdeki yanıklarda 112'yi arayın.", 'Call the emergency number for large or deep burns, or burns on the face or hands.'],
  ]),
  GuideTopic(['Kırık ve burkulma', 'Fractures and sprains'], [
    ['Yaralı bölgeyi bulduğunuz pozisyonda destekleyin; düzeltmeye çalışmayın.', 'Support the injured part in the position you found it; do not try to straighten it.'],
    ['Şişliği azaltmak için beze sarılı soğuk bir şeyi 20 dakikaya kadar uygulayın.', 'Hold something cold, wrapped in a cloth, on it for up to 20 minutes to reduce swelling.'],
    ['Açık yara varsa temiz bir örtüyle kapatın.', 'Cover any open wound with a clean dressing.'],
    ["Belirgin şekil bozukluğunda, açık kırıkta ya da baş, boyun, sırt yaralanmasında 112'yi arayın.", 'Call the emergency number for an obvious deformity, an open fracture, or a head, neck or back injury.'],
  ]),
  GuideTopic(['Şok', 'Shock'], [
    ['Belirtiler: soluk, soğuk, nemli cilt; hızlı nefes; halsizlik; bilinç bulanıklığı.', 'Signs: pale, cold, clammy skin; fast breathing; weakness; confusion.'],
    ["112'yi arayın; görünür bir kanama varsa durdurun.", 'Call the emergency number and stop any visible bleeding.'],
    ['Kişiyi uzandırın, üstünü örtüp sıcak tutun ve sakinleştirin.', 'Help them lie down, cover them to keep them warm and reassure them.'],
    ['Yiyecek ya da içecek vermeyin.', 'Do not give them anything to eat or drink.'],
  ], urgent: true),
  GuideTopic(['Kalp krizi belirtileri', 'Heart attack warning signs'], [
    ['Göğüste baskı, sıkışma ya da kola, çeneye, sırta yayılan ağrı; nefes darlığı, terleme, bulantı olabilir.', 'Chest pressure or tightness, or pain spreading to the arm, jaw or back; there may be breathlessness, sweating or nausea.'],
    ["Hemen 112'yi arayın.", 'Call the emergency number straight away.'],
    ['Rahat bir oturuş pozisyonunda dinlenmesine yardım edin; sıkan giysileri gevşetin.', 'Help them rest in a comfortable sitting position and loosen tight clothing.'],
    ['Bilinci kaybolur ve nefes almazsa kalp masajına başlayın.', 'If they become unresponsive and are not breathing, start CPR.'],
  ], urgent: true),
  GuideTopic(['İnme (felç) belirtileri', 'Stroke signs: FAST'], [
    ['Yüz: Gülümsediğinde yüzünün bir tarafı düşüyor mu?', 'Face: does one side of the face droop when they smile?'],
    ['Kol: İki kolunu kaldırınca biri aşağı düşüyor mu?', 'Arms: can they raise both arms and keep them up?'],
    ['Konuşma: Konuşması peltek ya da anlaşılmaz mı?', 'Speech: is their speech slurred or confused?'],
    ["Zaman: Bunlardan biri varsa hemen 112'yi arayın ve belirtilerin başladığı saati not edin.", 'Time: if you see any of these, call the emergency number now and note when the symptoms started.'],
  ], urgent: true),
  GuideTopic(['Ciddi alerjik tepki', 'Severe allergic reaction'], [
    ['Belirtiler: nefes almada zorluk, dudak ya da dil şişmesi, yaygın kızarıklık, baş dönmesi.', 'Signs: difficulty breathing, swollen lips or tongue, a widespread rash, dizziness.'],
    ["Hemen 112'yi arayın.", 'Call the emergency number immediately.'],
    ['Kişiye reçete edilmiş bir adrenalin oto-enjektörü varsa kullanmasına yardım edin.', 'If the person has their own prescribed adrenaline auto-injector, help them use it.'],
    ['Nefes almakta zorlanıyorsa oturtun; bayılacak gibiyse uzandırın.', 'Sit them up if breathing is hard; lay them down if they feel faint.'],
  ], urgent: true),
  GuideTopic(['Zehirlenme', 'Poisoning'], [
    ['Ne, ne kadar ve ne zaman alındığını öğrenmeye çalışın; ambalajı saklayın.', 'Try to find out what was taken, how much and when; keep the packaging.'],
    ["112'yi ya da Ulusal Zehir Danışma Merkezi'ni (114) arayıp talimatlara uyun.", 'Call the emergency number or your local poison information line and follow their advice.'],
    ['Size söylenmedikçe kusturmayın ve bir şey içirmeyin.', 'Do not make them vomit or give them anything to drink unless you are told to.'],
    ['Bilinci kaybolursa yan yatırın; nefes almıyorsa kalp masajına başlayın.', 'If they become unresponsive, use the recovery position; if they are not breathing, start CPR.'],
  ]),
  GuideTopic(['Sıcak çarpması', 'Heatstroke'], [
    ['Belirtiler: çok yüksek vücut ısısı, sıcak cilt, bilinç bulanıklığı, baş ağrısı.', 'Signs: very high body temperature, hot skin, confusion, headache.'],
    ["112'yi arayın; kişiyi serin ve gölge bir yere alın.", 'Call the emergency number and move them somewhere cool and shaded.'],
    ['Fazla giysileri çıkarın, cildi serin suyla ıslatıp yelpazeleyin.', 'Remove excess clothing, wet the skin with cool water and fan them.'],
    ['Bilinci tam yerindeyse küçük yudumlarla su verin.', 'If they are fully alert, give small sips of water.'],
  ]),
  GuideTopic(['Soğuğa bağlı vücut ısısı düşmesi', 'Hypothermia'], [
    ['Kişiyi sıcak ve kuru bir yere alın; ıslak giysileri çıkarın.', 'Move them somewhere warm and dry and remove wet clothing.'],
    ['Battaniyeyle sarın, başını da örtün ve yavaş yavaş ısıtın.', 'Wrap them in blankets, cover the head, and warm them gradually.'],
    ['Bilinci yerindeyse ılık (sıcak değil) içecek verin; alkol vermeyin.', 'If alert, give warm (not hot) drinks; no alcohol.'],
    ["Kol ve bacaklarını ovmayın; belirtiler ağırsa 112'yi arayın.", 'Do not rub their arms or legs; call the emergency number if symptoms are severe.'],
  ]),
  GuideTopic(['Nöbet (sara)', 'Seizure'], [
    ['Çevredeki sert ve tehlikeli eşyaları uzaklaştırın; başının altına yumuşak bir şey koyun.', 'Move hard or dangerous objects away and cushion their head.'],
    ['Kişiyi tutmaya çalışmayın, ağzına hiçbir şey koymayın.', 'Do not hold them down or put anything in their mouth.'],
    ["Süreyi tutun; 5 dakikadan uzun sürerse ya da ilk nöbetiyse 112'yi arayın.", 'Time it; call the emergency number if it lasts more than 5 minutes or if it is their first seizure.'],
    ['Kasılmalar bitince yan yatırın ve yanında kalın.', 'When the jerking stops, put them in the recovery position and stay with them.'],
  ]),
  GuideTopic(['Burun kanaması', 'Nosebleed'], [
    ['Oturtun ve başını hafifçe öne eğin (geriye değil).', 'Sit them down and lean the head slightly forward (not back).'],
    ['Burnun yumuşak kısmını 10–15 dakika bırakmadan sıkın; ağızdan nefes alsın.', 'Pinch the soft part of the nose for 10–15 minutes without letting go; breathe through the mouth.'],
    ['30 dakikadan uzun sürerse ya da başa darbe sonrası olduysa tıbbi yardım alın.', 'Get medical help if it lasts more than 30 minutes or follows a blow to the head.'],
  ]),
];

/// Düğüm: ad, kullanım, adımlar, zorluk (1–3).
class Knot {
  final List<String> name;
  final List<String> use;
  final List<List<String>> steps;
  final int level;
  const Knot(this.name, this.use, this.steps, this.level);
}

const List<Knot> kKnots = [
  Knot(['Basit düğüm', 'Overhand knot'], ['İp ucunun kaçmasını önler; birçok düğümün temelidir.', 'Stops a rope end slipping; the base of many knots.'], [
    ['İpin ucuyla bir halka yapın.', 'Make a loop with the end of the rope.'],
    ['Ucu halkanın içinden geçirin.', 'Pass the end through the loop.'],
    ['İki taraftan çekerek sıkın.', 'Pull both sides to tighten.'],
  ], 1),
  Knot(['Sekiz düğümü', 'Figure-eight knot'], ['Ucun makaradan ya da delikten kaçmasını önleyen, kolay çözülen durdurucu.', 'A stopper knot that keeps a rope end from slipping through a hole, and unties easily.'], [
    ['Ucu ipin ana kısmının üstünden geçirip bir halka yapın.', 'Pass the end over the standing part to make a loop.'],
    ['Ucu ana kısmın arkasından dolaştırın.', 'Take the end around behind the standing part.'],
    ['Ucu önden ilk halkanın içinden geçirin; "8" şekli oluşur.', 'Bring the end through the first loop from the front; it forms an "8".'],
    ['Sıkın.', 'Pull tight.'],
  ], 1),
  Knot(['Camadan (dördül) düğüm', 'Reef (square) knot'], ['İki ucu bir paket ya da bandaj üzerinde bağlamak için. Yük taşımak için uygun değildir.', 'Ties two ends around a parcel or bandage. Not for carrying loads.'], [
    ['Sol ucu sağın üstünden geçirip bir kez dolayın.', 'Cross left over right and tuck under once.'],
    ['Şimdi sağ ucu solun üstünden geçirip bir kez dolayın.', 'Now cross right over left and tuck under once.'],
    ['İki ucu birlikte çekin; düğüm düz ve simetrik olmalı.', 'Pull both ends; the knot should lie flat and symmetrical.'],
  ], 1),
  Knot(['İzbarço', 'Bowline'], ['Kaymayan sabit bir halka; bir direğe ya da halkaya bağlamak için.', 'A fixed loop that does not slip; for tying around a post or ring.'], [
    ['Ana kısımda küçük bir halka yapın ("tavşan deliği").', 'Make a small loop in the standing part (the "rabbit hole").'],
    ['Ucu halkadan aşağıdan yukarı geçirin.', 'Bring the end up through the loop from underneath.'],
    ['Ucu ana kısmın arkasından dolaştırın.', 'Take the end around behind the standing part.'],
    ['Ucu aynı halkadan geri indirin ve sıkın.', 'Send the end back down through the same loop and tighten.'],
  ], 2),
  Knot(['Kazık bağı', 'Clove hitch'], ['İpi bir direğe hızla bağlamak için; ayarı kolaydır.', 'Quickly attaches a rope to a post; easy to adjust.'], [
    ['İpi direğin çevresinde bir tur dolayın.', 'Wrap the rope once around the post.'],
    ['Ucu ilk turun üstünden çapraz geçirerek ikinci turu atın.', 'Cross over the first turn and wrap a second time.'],
    ['Ucu ikinci turun altından geçirip sıkın.', 'Tuck the end under the second turn and pull tight.'],
  ], 1),
  Knot(['İki yarım bağ', 'Two half hitches'], ['İpi bir halkaya ya da direğe bağlamak için basit ve sağlam.', 'Simple, secure way to tie a rope to a ring or post.'], [
    ['Ucu direğin çevresinden geçirin.', 'Pass the end around the post.'],
    ['Ucu ana kısmın çevresinde dolayıp kendi altından geçirin (birinci yarım bağ).', 'Wrap it around the standing part and tuck it under itself (first half hitch).'],
    ['Aynısını aynı yönde bir kez daha yapın ve sıkın.', 'Repeat once more in the same direction and tighten.'],
  ], 1),
  Knot(['Volta ve iki yarım bağ', 'Round turn and two half hitches'], ['Gerilim altındaki bir ipi direğe güvenle bağlar; yük altında da çözülebilir.', 'Secures a rope under tension to a post; can be untied even under load.'], [
    ['İpi direğin çevresinde iki tam tur dolayın.', 'Take two full turns around the post.'],
    ['Ardından ana kısım üzerine iki yarım bağ atın.', 'Then tie two half hitches around the standing part.'],
    ['Sıkın.', 'Tighten.'],
  ], 2),
  Knot(['Iskota bağı', 'Sheet bend'], ['Farklı kalınlıktaki iki ipi birleştirmek için.', 'Joins two ropes of different thickness.'], [
    ['Kalın ipin ucunu bükerek bir kıvrım yapın.', 'Make a bight (U-shape) in the end of the thicker rope.'],
    ['İnce ipi kıvrımın içinden aşağıdan yukarı geçirin.', 'Pass the thinner rope up through the bight.'],
    ['İnce ipi kıvrımın arkasından dolaştırıp kendi altından geçirin.', 'Take it around behind the bight and tuck it under itself.'],
    ['İki ipi çekerek sıkın.', 'Pull both ropes to tighten.'],
  ], 2),
  Knot(['Gergi bağı', 'Taut-line hitch'], ['Çadır ipleri gibi gerginliği ayarlanabilen halka.', 'An adjustable loop for tent lines and guy ropes.'], [
    ['İpi kazığın çevresinden geçirin.', 'Pass the rope around the stake.'],
    ['Ucu ana kısmın çevresinde, halkanın içine doğru iki kez dolayın.', 'Wrap the end twice around the standing part, working inside the loop.'],
    ['Halkanın dışında bir kez daha dolayıp altından geçirin.', 'Make one more wrap outside the loop and tuck it under.'],
    ['Düğümü kaydırarak gerginliği ayarlayın.', 'Slide the knot to adjust the tension.'],
  ], 2),
  Knot(['Kütük bağı', 'Timber hitch'], ['Kütük ya da direk gibi uzun cisimleri sürüklemek için.', 'For dragging logs or poles.'], [
    ['İpi cismin çevresinden geçirin.', 'Pass the rope around the object.'],
    ['Ucu ana kısmın çevresinden dolayın.', 'Take the end around the standing part.'],
    ['Ucu kendi çevresinde üç-dört kez burun.', 'Twist the end around itself three or four times.'],
    ['Ana kısmı çekerek sıkın.', 'Pull the standing part to tighten.'],
  ], 1),
  Knot(['Çift balıkçı düğümü', 'Double fisherman\'s knot'], ['İki ipi kalıcı ve güvenle birleştirir.', 'Joins two ropes securely and permanently.'], [
    ['İki ipin uçlarını yan yana karşılıklı koyun.', 'Lay the two ends side by side, pointing in opposite directions.'],
    ['Birinci uçla, ikinci ipin çevresinde iki tur atıp turların içinden geçirin.', 'With the first end, make two turns around the other rope and pass it through the turns.'],
    ['Aynısını ikinci uçla ters yönde yapın.', 'Repeat with the second end in the opposite direction.'],
    ['Ana kısımları çekin; iki düğüm birbirine oturur.', 'Pull the standing parts so the two knots slide together.'],
  ], 3),
  Knot(['Kamyoncu bağı', 'Trucker\'s hitch'], ['Yükü sıkıca bağlamak için makara etkisi verir.', 'Gives a pulley effect to cinch a load down tight.'], [
    ['İpin ortasında sabit bir halka yapın.', 'Make a fixed loop in the middle of the rope.'],
    ['Serbest ucu bağlantı noktasından geçirip halkadan geri getirin.', 'Pass the free end around the anchor and back through the loop.'],
    ['Ucu çekerek yükü sıkıştırın.', 'Pull the end to cinch the load.'],
    ['İki yarım bağla sabitleyin.', 'Secure it with two half hitches.'],
  ], 3),
];

/// Çamaşır bakım sembolü: çizim türü, parametreler ve anlamı.
/// tür: wash (leğen), hand, bleach, dry (kare), tumble, iron, pro (daire).
class CareSymbol {
  final String kind;
  final String label;
  final int dots;
  final int bars;
  final bool cross;
  final String mark;
  final List<String> meaning;
  const CareSymbol(this.kind, this.meaning, {this.label = '', this.dots = 0, this.bars = 0, this.cross = false, this.mark = ''});
}

const List<List<CareSymbol>> kCareSymbols = [
  [
    CareSymbol('wash', ['En fazla 30 °C, normal yıkama', 'Wash at max 30 °C, normal cycle'], label: '30'),
    CareSymbol('wash', ['En fazla 40 °C, normal yıkama', 'Wash at max 40 °C, normal cycle'], label: '40'),
    CareSymbol('wash', ['En fazla 60 °C, normal yıkama', 'Wash at max 60 °C, normal cycle'], label: '60'),
    CareSymbol('wash', ['En fazla 95 °C (kaynatılabilir)', 'Wash at max 95 °C (boil wash)'], label: '95'),
    CareSymbol('wash', ['40 °C, hassas program (sentetik)', '40 °C, gentle cycle (synthetics)'], label: '40', bars: 1),
    CareSymbol('wash', ['30 °C, çok hassas program (yün)', '30 °C, very gentle cycle (wool)'], label: '30', bars: 2),
    CareSymbol('hand', ['Elde yıkayın, en fazla 40 °C', 'Hand wash only, max 40 °C']),
    CareSymbol('wash', ['Yıkamayın', 'Do not wash'], cross: true),
  ],
  [
    CareSymbol('bleach', ['Her tür ağartıcı kullanılabilir', 'Any bleach allowed']),
    CareSymbol('bleach', ['Yalnızca klorsuz (oksijenli) ağartıcı', 'Non-chlorine (oxygen) bleach only'], bars: 2),
    CareSymbol('bleach', ['Ağartıcı kullanmayın', 'Do not bleach'], cross: true),
  ],
  [
    CareSymbol('tumble', ['Kurutma makinesi, normal ısı', 'Tumble dry, normal heat'], dots: 2),
    CareSymbol('tumble', ['Kurutma makinesi, düşük ısı', 'Tumble dry, low heat'], dots: 1),
    CareSymbol('tumble', ['Kurutma makinesine atmayın', 'Do not tumble dry'], cross: true),
    CareSymbol('dry', ['İpe asarak kurutun', 'Line dry'], mark: 'line'),
    CareSymbol('dry', ['Sıkmadan, damlatarak kurutun', 'Drip dry'], mark: 'drip'),
    CareSymbol('dry', ['Düz bir yüzeyde serip kurutun', 'Dry flat'], mark: 'flat'),
    CareSymbol('dry', ['Gölgede kurutun', 'Dry in the shade'], mark: 'shade'),
  ],
  [
    CareSymbol('iron', ['Düşük ısıda ütüleyin (en fazla 110 °C), buharsız', 'Iron on low (max 110 °C), no steam'], dots: 1),
    CareSymbol('iron', ['Orta ısıda ütüleyin (en fazla 150 °C)', 'Iron on medium (max 150 °C)'], dots: 2),
    CareSymbol('iron', ['Yüksek ısıda ütüleyin (en fazla 200 °C)', 'Iron on high (max 200 °C)'], dots: 3),
    CareSymbol('iron', ['Ütülemeyin', 'Do not iron'], cross: true),
  ],
  [
    CareSymbol('pro', ['Profesyonel kuru temizleme (tüm çözücüler)', 'Professional dry clean (any solvent)'], label: 'P'),
    CareSymbol('pro', ['Profesyonel kuru temizleme (hafif çözücü)', 'Professional dry clean (mild solvent)'], label: 'F'),
    CareSymbol('pro', ['Profesyonel ıslak temizleme', 'Professional wet clean'], label: 'W'),
    CareSymbol('pro', ['Kuru temizleme yapmayın', 'Do not dry clean'], cross: true),
  ],
];
