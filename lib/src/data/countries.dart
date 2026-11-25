/// Ülkeler: İngilizce ad | Türkçe ad | başkent | kıta | başkentin enlemi |
/// boylamı. Yuvarlanmış kamu bilgisi (BM üyesi 193 ülke + 2 gözlemci).
/// Sınırlar ve tartışmalı bölgeler hakkında görüş bildirmez.
library;

const String kCountryData = '''
Afghanistan|Afganistan|Kabul|AS|34.53|69.17
Albania|Arnavutluk|Tirana|EU|41.33|19.82
Algeria|Cezayir|Algiers|AF|36.75|3.06
Andorra|Andorra|Andorra la Vella|EU|42.51|1.52
Angola|Angola|Luanda|AF|-8.84|13.23
Antigua and Barbuda|Antigua ve Barbuda|Saint John's|NA|17.12|-61.85
Argentina|Arjantin|Buenos Aires|SA|-34.60|-58.38
Armenia|Ermenistan|Yerevan|AS|40.18|44.51
Australia|Avustralya|Canberra|OC|-35.28|149.13
Austria|Avusturya|Vienna|EU|48.21|16.37
Azerbaijan|Azerbaycan|Baku|AS|40.41|49.87
Bahamas|Bahamalar|Nassau|NA|25.05|-77.35
Bahrain|Bahreyn|Manama|AS|26.23|50.59
Bangladesh|Bangladeş|Dhaka|AS|23.81|90.41
Barbados|Barbados|Bridgetown|NA|13.10|-59.62
Belarus|Belarus|Minsk|EU|53.90|27.56
Belgium|Belçika|Brussels|EU|50.85|4.35
Belize|Belize|Belmopan|NA|17.25|-88.77
Benin|Benin|Porto-Novo|AF|6.50|2.60
Bhutan|Butan|Thimphu|AS|27.47|89.64
Bolivia|Bolivya|Sucre|SA|-19.03|-65.26
Bosnia and Herzegovina|Bosna-Hersek|Sarajevo|EU|43.86|18.41
Botswana|Botsvana|Gaborone|AF|-24.65|25.91
Brazil|Brezilya|Brasília|SA|-15.79|-47.88
Brunei|Brunei|Bandar Seri Begawan|AS|4.90|114.94
Bulgaria|Bulgaristan|Sofia|EU|42.70|23.32
Burkina Faso|Burkina Faso|Ouagadougou|AF|12.37|-1.53
Burundi|Burundi|Gitega|AF|-3.43|29.93
Cabo Verde|Yeşil Burun Adaları|Praia|AF|14.93|-23.51
Cambodia|Kamboçya|Phnom Penh|AS|11.56|104.92
Cameroon|Kamerun|Yaoundé|AF|3.85|11.50
Canada|Kanada|Ottawa|NA|45.42|-75.70
Central African Republic|Orta Afrika Cumhuriyeti|Bangui|AF|4.39|18.56
Chad|Çad|N'Djamena|AF|12.13|15.06
Chile|Şili|Santiago|SA|-33.45|-70.67
China|Çin|Beijing|AS|39.90|116.40
Colombia|Kolombiya|Bogotá|SA|4.71|-74.07
Comoros|Komorlar|Moroni|AF|-11.70|43.26
Congo|Kongo|Brazzaville|AF|-4.26|15.24
Costa Rica|Kosta Rika|San José|NA|9.93|-84.08
Côte d'Ivoire|Fildişi Sahili|Yamoussoukro|AF|6.83|-5.29
Croatia|Hırvatistan|Zagreb|EU|45.81|15.98
Cuba|Küba|Havana|NA|23.11|-82.37
Cyprus|Kıbrıs|Nicosia|EU|35.19|33.38
Czechia|Çekya|Prague|EU|50.08|14.44
DR Congo|Kongo Demokratik Cumhuriyeti|Kinshasa|AF|-4.32|15.31
Denmark|Danimarka|Copenhagen|EU|55.68|12.57
Djibouti|Cibuti|Djibouti|AF|11.59|43.15
Dominica|Dominika|Roseau|NA|15.30|-61.39
Dominican Republic|Dominik Cumhuriyeti|Santo Domingo|NA|18.49|-69.93
Ecuador|Ekvador|Quito|SA|-0.18|-78.47
Egypt|Mısır|Cairo|AF|30.04|31.24
El Salvador|El Salvador|San Salvador|NA|13.69|-89.22
Equatorial Guinea|Ekvator Ginesi|Malabo|AF|3.75|8.78
Eritrea|Eritre|Asmara|AF|15.32|38.93
Estonia|Estonya|Tallinn|EU|59.44|24.75
Eswatini|Esvatini|Mbabane|AF|-26.31|31.14
Ethiopia|Etiyopya|Addis Ababa|AF|9.03|38.74
Fiji|Fiji|Suva|OC|-18.14|178.44
Finland|Finlandiya|Helsinki|EU|60.17|24.94
France|Fransa|Paris|EU|48.86|2.35
Gabon|Gabon|Libreville|AF|0.42|9.47
Gambia|Gambiya|Banjul|AF|13.45|-16.58
Georgia|Gürcistan|Tbilisi|AS|41.72|44.79
Germany|Almanya|Berlin|EU|52.52|13.40
Ghana|Gana|Accra|AF|5.60|-0.19
Greece|Yunanistan|Athens|EU|37.98|23.73
Grenada|Grenada|Saint George's|NA|12.06|-61.75
Guatemala|Guatemala|Guatemala City|NA|14.63|-90.51
Guinea|Gine|Conakry|AF|9.64|-13.58
Guinea-Bissau|Gine-Bissau|Bissau|AF|11.86|-15.60
Guyana|Guyana|Georgetown|SA|6.80|-58.16
Haiti|Haiti|Port-au-Prince|NA|18.59|-72.31
Honduras|Honduras|Tegucigalpa|NA|14.07|-87.19
Hungary|Macaristan|Budapest|EU|47.50|19.04
Iceland|İzlanda|Reykjavík|EU|64.15|-21.94
India|Hindistan|New Delhi|AS|28.61|77.21
Indonesia|Endonezya|Jakarta|AS|-6.21|106.85
Iran|İran|Tehran|AS|35.69|51.39
Iraq|Irak|Baghdad|AS|33.31|44.36
Ireland|İrlanda|Dublin|EU|53.35|-6.26
Israel|İsrail|Jerusalem*|AS|31.77|35.21
Italy|İtalya|Rome|EU|41.90|12.50
Jamaica|Jamaika|Kingston|NA|18.02|-76.80
Japan|Japonya|Tokyo|AS|35.68|139.69
Jordan|Ürdün|Amman|AS|31.95|35.93
Kazakhstan|Kazakistan|Astana|AS|51.17|71.45
Kenya|Kenya|Nairobi|AF|-1.29|36.82
Kiribati|Kiribati|Tarawa|OC|1.33|172.98
Kuwait|Kuveyt|Kuwait City|AS|29.38|47.99
Kyrgyzstan|Kırgızistan|Bishkek|AS|42.87|74.59
Laos|Laos|Vientiane|AS|17.97|102.63
Latvia|Letonya|Riga|EU|56.95|24.11
Lebanon|Lübnan|Beirut|AS|33.89|35.50
Lesotho|Lesotho|Maseru|AF|-29.31|27.48
Liberia|Liberya|Monrovia|AF|6.30|-10.80
Libya|Libya|Tripoli|AF|32.89|13.19
Liechtenstein|Lihtenştayn|Vaduz|EU|47.14|9.52
Lithuania|Litvanya|Vilnius|EU|54.69|25.28
Luxembourg|Lüksemburg|Luxembourg|EU|49.61|6.13
Madagascar|Madagaskar|Antananarivo|AF|-18.88|47.51
Malawi|Malavi|Lilongwe|AF|-13.96|33.79
Malaysia|Malezya|Kuala Lumpur|AS|3.14|101.69
Maldives|Maldivler|Malé|AS|4.18|73.51
Mali|Mali|Bamako|AF|12.64|-8.00
Malta|Malta|Valletta|EU|35.90|14.51
Marshall Islands|Marshall Adaları|Majuro|OC|7.09|171.38
Mauritania|Moritanya|Nouakchott|AF|18.09|-15.98
Mauritius|Mauritius|Port Louis|AF|-20.16|57.50
Mexico|Meksika|Mexico City|NA|19.43|-99.13
Micronesia|Mikronezya|Palikir|OC|6.92|158.16
Moldova|Moldova|Chișinău|EU|47.01|28.86
Monaco|Monako|Monaco|EU|43.74|7.42
Mongolia|Moğolistan|Ulaanbaatar|AS|47.89|106.91
Montenegro|Karadağ|Podgorica|EU|42.44|19.26
Morocco|Fas|Rabat|AF|34.02|-6.84
Mozambique|Mozambik|Maputo|AF|-25.97|32.57
Myanmar|Myanmar|Naypyidaw|AS|19.76|96.08
Namibia|Namibya|Windhoek|AF|-22.56|17.08
Nauru|Nauru|Yaren|OC|-0.55|166.92
Nepal|Nepal|Kathmandu|AS|27.72|85.32
Netherlands|Hollanda|Amsterdam|EU|52.37|4.90
New Zealand|Yeni Zelanda|Wellington|OC|-41.29|174.78
Nicaragua|Nikaragua|Managua|NA|12.11|-86.24
Niger|Nijer|Niamey|AF|13.51|2.11
Nigeria|Nijerya|Abuja|AF|9.08|7.40
North Korea|Kuzey Kore|Pyongyang|AS|39.04|125.76
North Macedonia|Kuzey Makedonya|Skopje|EU|42.00|21.43
Norway|Norveç|Oslo|EU|59.91|10.75
Oman|Umman|Muscat|AS|23.59|58.41
Pakistan|Pakistan|Islamabad|AS|33.68|73.05
Palau|Palau|Ngerulmud|OC|7.50|134.62
Palestine|Filistin|Ramallah*|AS|31.90|35.20
Panama|Panama|Panama City|NA|8.98|-79.52
Papua New Guinea|Papua Yeni Gine|Port Moresby|OC|-9.44|147.18
Paraguay|Paraguay|Asunción|SA|-25.26|-57.58
Peru|Peru|Lima|SA|-12.05|-77.04
Philippines|Filipinler|Manila|AS|14.60|120.98
Poland|Polonya|Warsaw|EU|52.23|21.01
Portugal|Portekiz|Lisbon|EU|38.72|-9.14
Qatar|Katar|Doha|AS|25.29|51.53
Romania|Romanya|Bucharest|EU|44.43|26.10
Russia|Rusya|Moscow|EU|55.76|37.62
Rwanda|Ruanda|Kigali|AF|-1.95|30.06
Saint Kitts and Nevis|Saint Kitts ve Nevis|Basseterre|NA|17.30|-62.72
Saint Lucia|Saint Lucia|Castries|NA|14.01|-60.99
Saint Vincent and the Grenadines|Saint Vincent ve Grenadinler|Kingstown|NA|13.16|-61.22
Samoa|Samoa|Apia|OC|-13.83|-171.76
San Marino|San Marino|San Marino|EU|43.94|12.45
São Tomé and Príncipe|São Tomé ve Príncipe|São Tomé|AF|0.34|6.73
Saudi Arabia|Suudi Arabistan|Riyadh|AS|24.71|46.68
Senegal|Senegal|Dakar|AF|14.72|-17.47
Serbia|Sırbistan|Belgrade|EU|44.79|20.45
Seychelles|Seyşeller|Victoria|AF|-4.62|55.45
Sierra Leone|Sierra Leone|Freetown|AF|8.47|-13.23
Singapore|Singapur|Singapore|AS|1.35|103.82
Slovakia|Slovakya|Bratislava|EU|48.15|17.11
Slovenia|Slovenya|Ljubljana|EU|46.06|14.51
Solomon Islands|Solomon Adaları|Honiara|OC|-9.43|159.95
Somalia|Somali|Mogadishu|AF|2.05|45.32
South Africa|Güney Afrika|Pretoria|AF|-25.75|28.19
South Korea|Güney Kore|Seoul|AS|37.57|126.98
South Sudan|Güney Sudan|Juba|AF|4.85|31.58
Spain|İspanya|Madrid|EU|40.42|-3.70
Sri Lanka|Sri Lanka|Sri Jayawardenepura Kotte|AS|6.89|79.90
Sudan|Sudan|Khartoum|AF|15.50|32.56
Suriname|Surinam|Paramaribo|SA|5.85|-55.20
Sweden|İsveç|Stockholm|EU|59.33|18.07
Switzerland|İsviçre|Bern|EU|46.95|7.45
Syria|Suriye|Damascus|AS|33.51|36.29
Tajikistan|Tacikistan|Dushanbe|AS|38.56|68.79
Tanzania|Tanzanya|Dodoma|AF|-6.16|35.75
Thailand|Tayland|Bangkok|AS|13.76|100.50
Timor-Leste|Doğu Timor|Dili|AS|-8.56|125.57
Togo|Togo|Lomé|AF|6.13|1.22
Tonga|Tonga|Nukuʻalofa|OC|-21.14|-175.20
Trinidad and Tobago|Trinidad ve Tobago|Port of Spain|NA|10.66|-61.51
Tunisia|Tunus|Tunis|AF|36.81|10.18
Türkiye|Türkiye|Ankara|AS|39.93|32.86
Turkmenistan|Türkmenistan|Ashgabat|AS|37.96|58.33
Tuvalu|Tuvalu|Funafuti|OC|-8.52|179.20
Uganda|Uganda|Kampala|AF|0.35|32.58
Ukraine|Ukrayna|Kyiv|EU|50.45|30.52
United Arab Emirates|Birleşik Arap Emirlikleri|Abu Dhabi|AS|24.45|54.38
United Kingdom|Birleşik Krallık|London|EU|51.51|-0.13
United States|Amerika Birleşik Devletleri|Washington, D.C.|NA|38.90|-77.04
Uruguay|Uruguay|Montevideo|SA|-34.90|-56.16
Uzbekistan|Özbekistan|Tashkent|AS|41.30|69.24
Vanuatu|Vanuatu|Port Vila|OC|-17.73|168.32
Vatican City|Vatikan|Vatican City|EU|41.90|12.45
Venezuela|Venezuela|Caracas|SA|10.48|-66.90
Vietnam|Vietnam|Hanoi|AS|21.03|105.85
Yemen|Yemen|Sana'a|AS|15.37|44.19
Zambia|Zambiya|Lusaka|AF|-15.39|28.32
Zimbabwe|Zimbabve|Harare|AF|-17.83|31.05
''';

class Country {
  final List<String> name;
  final String capital;
  final String continent;
  final double lat, lng;
  const Country(this.name, this.capital, this.continent, this.lat, this.lng);
}

final List<Country> kCountries = [
  for (final line in kCountryData.trim().split('\n'))
    () {
      final p = line.split('|');
      return Country([p[1], p[0]], p[2], p[3], double.parse(p[4]), double.parse(p[5]));
    }(),
];
