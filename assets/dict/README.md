# Sözlük ve kelime listesi varlıkları

| Dosya | İçerik | Kaynak / lisans |
|---|---|---|
| `tr_en.tsv` | ~28.700 Türkçe–İngilizce madde (`tr<TAB>en`) | FreeDict English-Turkish 0.3 + Turkish-English 0.3, © 1999-2017 çeşitli yazarlar, **GNU GPL 2.0 veya sonrası** (`LICENSE-GPL2.txt`). Kaynak: https://github.com/freedict/fd-dictionaries (`eng-tur/eng-tur.tei`, `tur-eng/tur-eng.tei`) |
| `../vocab/tr_en_levels.tsv` | 4.400 sözcük, A1–C1 (`seviye<TAB>tr<TAB>en`) | Karşılıklar yukarıdaki FreeDict verisi + uygulamanın özgün çekirdek listesi ve elle düzeltmeler; seviyeler wordfreq (Apache-2.0 kod, CC-BY-SA 4.0 veri) İngilizce sıklığına göre yaklaşık atanır, resmî CEFR değildir |

Veri uygulama koduna gömülmez; ayrı varlık dosyası olarak dağıtılır ve uygulama içinde (sözlük notu) kaynak ile lisans belirtilir. Kaynak (TEI) dosyalarına yukarıdaki bağlantıdan ulaşılabilir.

Yeniden üretmek için (FreeDict TEI dosyalarını indirip):

```
pip install wordfreq
python3 -I proto/apps/egitim/mkdict.py eng-tur.tei tur-eng.tei <egitim-motoru dizini>
```

Dönüştürme otomatik olduğundan bazı karşılıklar hatalı olabilir; uygulama bunu kullanıcıya söyler.
