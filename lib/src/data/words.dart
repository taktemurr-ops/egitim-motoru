/// Türkçe–İngilizce temel sözcük listesi (özgün seçki, ~450 sözcük).
/// Biçim: türkçe=english; anlamlar virgülle. Çevrimdışı sözlük ve kelime
/// ezberi bu listeyi kullanır; kullanıcı kendi sözcüklerini ekleyebilir.
library;

const String kWordData = '''
ev=house,home;kapı=door;pencere=window;oda=room;mutfak=kitchen;banyo=bathroom;yatak=bed;masa=table;sandalye=chair;dolap=cupboard,wardrobe
duvar=wall;çatı=roof;bahçe=garden;anahtar=key;lamba=lamp;ayna=mirror;halı=carpet,rug;perde=curtain;merdiven=stairs;koltuk=armchair,sofa
su=water;ekmek=bread;süt=milk;peynir=cheese;yumurta=egg;et=meat;tavuk=chicken;balık=fish;pirinç=rice;makarna=pasta
elma=apple;muz=banana;portakal=orange;üzüm=grape;çilek=strawberry;limon=lemon;domates=tomato;patates=potato;soğan=onion;sarımsak=garlic
şeker=sugar;tuz=salt;biber=pepper;yağ=oil;bal=honey;çay=tea;kahve=coffee;meyve suyu=juice;çorba=soup;salata=salad
kahvaltı=breakfast;öğle yemeği=lunch;akşam yemeği=dinner;tatlı=dessert;bardak=glass;tabak=plate;çatal=fork;kaşık=spoon;bıçak=knife;fincan=cup
anne=mother;baba=father;kardeş=sibling;kız kardeş=sister;erkek kardeş=brother;dede=grandfather;nine=grandmother;çocuk=child;arkadaş=friend;komşu=neighbour
adam=man;kadın=woman;insan=person,human;aile=family;amca=uncle;teyze=aunt;kuzen=cousin;eş=spouse;oğul=son;kız=daughter,girl
baş=head;göz=eye;kulak=ear;burun=nose;ağız=mouth;diş=tooth;el=hand;kol=arm;bacak=leg;ayak=foot
kalp=heart;saç=hair;yüz=face;parmak=finger;sırt=back;karın=belly;boyun=neck;omuz=shoulder;diz=knee;dil=tongue,language
okul=school;öğretmen=teacher;öğrenci=student;kitap=book;defter=notebook;kalem=pen,pencil;ders=lesson;sınav=exam;sınıf=classroom,class;ödev=homework
soru=question;cevap=answer;sayfa=page;kelime=word;cümle=sentence;harf=letter;sayı=number;tarih=history,date;matematik=mathematics;bilim=science
iş=work,job;ofis=office;toplantı=meeting;para=money;fiyat=price;mağaza=shop;pazar=market,Sunday;banka=bank;hastane=hospital;eczane=pharmacy
doktor=doctor;hemşire=nurse;ilaç=medicine;hasta=ill,patient;ağrı=pain;polis=police;itfaiye=fire brigade;yardım=help;tehlike=danger;acil=urgent,emergency
şehir=city;köy=village;ülke=country;sokak=street;cadde=avenue;yol=road,way;köprü=bridge;park=park;meydan=square;bina=building
araba=car;otobüs=bus;tren=train;uçak=aeroplane;gemi=ship;bisiklet=bicycle;taksi=taxi;istasyon=station;havalimanı=airport;bilet=ticket
otel=hotel;oda servisi=room service;bavul=suitcase;pasaport=passport;harita=map;rehber=guide;tatil=holiday;deniz=sea;plaj=beach;dağ=mountain
gün=day;gece=night;sabah=morning;akşam=evening;hafta=week;ay=month,moon;yıl=year;saat=hour,clock;dakika=minute;saniye=second
bugün=today;yarın=tomorrow;dün=yesterday;şimdi=now;sonra=later,after;önce=before;her zaman=always;bazen=sometimes;asla=never;erken=early
pazartesi=Monday;salı=Tuesday;çarşamba=Wednesday;perşembe=Thursday;cuma=Friday;cumartesi=Saturday;ilkbahar=spring;yaz=summer;sonbahar=autumn;kış=winter
güneş=sun;yıldız=star;gökyüzü=sky;bulut=cloud;yağmur=rain;kar=snow;rüzgâr=wind;hava=weather,air;sıcak=hot;soğuk=cold
ağaç=tree;çiçek=flower;orman=forest;nehir=river;göl=lake;taş=stone;toprak=soil,earth;ateş=fire;hayvan=animal;kuş=bird
kedi=cat;köpek=dog;at=horse;inek=cow;koyun=sheep;tavşan=rabbit;arı=bee;kelebek=butterfly;aslan=lion;ayı=bear
kırmızı=red;mavi=blue;yeşil=green;sarı=yellow;siyah=black;beyaz=white;mor=purple;turuncu=orange (colour);pembe=pink;gri=grey
büyük=big;küçük=small;uzun=long,tall;kısa=short;yeni=new;eski=old;iyi=good;kötü=bad;güzel=beautiful,nice;çirkin=ugly
hızlı=fast;yavaş=slow;kolay=easy;zor=difficult;ucuz=cheap;pahalı=expensive;açık=open;kapalı=closed;dolu=full;boş=empty
mutlu=happy;üzgün=sad;yorgun=tired;aç=hungry;susuz=thirsty;hasta=sick;sağlıklı=healthy;zengin=rich;fakir=poor;genç=young
temiz=clean;kirli=dirty;ağır=heavy;hafif=light;yüksek=high;alçak=low;derin=deep;geniş=wide;dar=narrow;sessiz=quiet
gelmek=to come;gitmek=to go;yapmak=to do,to make;etmek=to do;olmak=to be,to become;görmek=to see;bakmak=to look;duymak=to hear;dinlemek=to listen;konuşmak=to speak
söylemek=to say;sormak=to ask;cevap vermek=to answer;bilmek=to know;düşünmek=to think;anlamak=to understand;öğrenmek=to learn;öğretmek=to teach;okumak=to read;yazmak=to write
yemek=to eat,food;içmek=to drink;uyumak=to sleep;uyanmak=to wake up;oturmak=to sit;kalkmak=to get up;yürümek=to walk;koşmak=to run;yüzmek=to swim;oynamak=to play
almak=to take,to buy;vermek=to give;satmak=to sell;ödemek=to pay;açmak=to open;kapatmak=to close;başlamak=to begin;bitirmek=to finish;beklemek=to wait;aramak=to search,to call
sevmek=to love,to like;istemek=to want;ihtiyaç duymak=to need;yardım etmek=to help;çalışmak=to work,to study;dinlenmek=to rest;yaşamak=to live;ölmek=to die;doğmak=to be born;büyümek=to grow
bulmak=to find;kaybetmek=to lose;kazanmak=to win,to earn;getirmek=to bring;götürmek=to take away;koymak=to put;tutmak=to hold;atmak=to throw;çekmek=to pull;itmek=to push
gülmek=to laugh;ağlamak=to cry;gülümsemek=to smile;korkmak=to be afraid;hatırlamak=to remember;unutmak=to forget;denemek=to try;değiştirmek=to change;seçmek=to choose;karar vermek=to decide
pişirmek=to cook;yıkamak=to wash;temizlemek=to clean;giymek=to wear;çıkarmak=to take off;taşımak=to carry;sürmek=to drive;binmek=to get on;inmek=to get off;dönmek=to turn,to return
evet=yes;hayır=no;lütfen=please;teşekkürler=thanks;merhaba=hello;hoşça kal=goodbye;özür dilerim=I'm sorry;tamam=okay;belki=maybe;elbette=of course
ve=and;veya=or;ama=but;çünkü=because;eğer=if;ile=with;için=for;gibi=like,as;kadar=as much as,until;daha=more
çok=very,a lot;az=little,few;hiç=none,never;hep=always;biraz=a little;her=every;bazı=some;hepsi=all;başka=other;aynı=same
burada=here;orada=there;nerede=where;ne=what;kim=who;neden=why;nasıl=how;ne zaman=when;hangi=which;kaç=how many
bir=one;iki=two;üç=three;dört=four;beş=five;altı=six;yedi=seven;sekiz=eight;dokuz=nine;on=ten
yirmi=twenty;otuz=thirty;kırk=forty;elli=fifty;altmış=sixty;yetmiş=seventy;seksen=eighty;doksan=ninety;yüz=hundred;bin=thousand
sol=left;sağ=right;düz=straight;ön=front;arka=back;üst=top;alt=bottom;iç=inside;dış=outside;orta=middle
gömlek=shirt;pantolon=trousers;elbise=dress;ceket=jacket;ayakkabı=shoes;çorap=socks;şapka=hat;çanta=bag;gözlük=glasses;saat (kol)=watch
telefon=phone;bilgisayar=computer;ekran=screen;internet=internet;mesaj=message;e-posta=e-mail;fotoğraf=photo;müzik=music;film=film,movie;oyun=game
spor=sport;futbol=football;top=ball;takım=team;maç=match;koşu=running;yüzme=swimming;sağlık=health;uyku=sleep;rüya=dream
sevgi=love;mutluluk=happiness;korku=fear;umut=hope;barış=peace;savaş=war;özgürlük=freedom;gerçek=truth,real;hayat=life;dünya=world
''';

/// (Türkçe, İngilizce) çiftleri.
final List<(String, String)> kWords = [
  for (final line in kWordData.trim().split('\n'))
    for (final pair in line.split(';'))
      if (pair.contains('=')) (pair.substring(0, pair.indexOf('=')).trim(), pair.substring(pair.indexOf('=') + 1).trim()),
];
