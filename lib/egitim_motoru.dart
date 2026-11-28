/// Eğitim ve Yaşam motoru: 52 uygulamanın gerçek uygulamaları, 33 dilde
/// metinleri ve merkez görünümü. İnce depolar (uyg-*) buradan tek bir
/// uygulama alır.
library;

export 'src/astro.dart';
export 'src/ek4_core.dart';
export 'src/geo.dart' show City, kCities, cityByName, dstActive, Place;
export 'src/learn_core.dart';
export 'src/registry.dart';
export 'src/tools/food.dart' show Ingredient, Recipe, aggregate, exportRecipes, importRecipes, weekDays, copyWeekPlan;
export 'src/tools/faith.dart' show ramadanDays, upcomingHolyDays, kHolyDays, prayerAlertTimes;
export 'src/tools/garden.dart' show badPairs;
export 'src/tools/learn.dart' show searchWords, sampleText, buildVocabDecks;
export 'src/data/dict_assets.dart' show parseDictTsv, parseVocabTsv, kVocabLevels, kDictAsset, kVocabAsset;
export 'src/tools/records.dart' show RecordSpec, nextDue, nextAnniversary, progressOf, sumOf, notifyId, DueMode;
export 'src/tools/home.dart';
export 'src/tools/science.dart' show projectile;
export 'src/tools/travel.dart' show Expense, balances, settle, overlapHours, bearing;
export 'src/data/elements.dart' show kElements;
export 'src/data/garden.dart' show kCrops, plantsFit, cropById;
export 'src/data/words.dart' show kWords;
export 'src/data/phrases.dart' show kPhrases, kLangCodes;
export 'src/data/countries.dart' show kCountries;
export 'src/data/sky.dart' show kStars, kConstellations;
export 'src/data/molecules.dart' show kMolecules, bondsOf;
export 'src/data/formulas.dart' show kFormulas;
export 'src/data/guides.dart' show kFirstAid, kKnots, kCareSymbols;
export 'src/data/core_words.dart';
export 'src/data/timeline.dart';
export 'src/data/ehliyet.dart';
export 'src/data/turkce.dart';
export 'src/turkce_core.dart';
export 'src/tools/lang.dart' show vocabOf, vocabQuestion, kVocabCats, yearOptions, eraOf, kEras, buildExam, examScore, kPassScore;
