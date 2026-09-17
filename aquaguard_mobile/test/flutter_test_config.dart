/// AquaGuard - Test Yapılandırması (google_fonts Ağ İzolasyonu + SQLite)
/// ===========================================================================
///
/// Amac:
///   `config/tema.dart`, tipografi icin google_fonts (Inter) kullanir.
///   Bu paket varsayilan olarak font dosyasini ilk kullanimda AGDAN
///   ceker -- test/CI ortaminda bu, yavas/kararsiz veya tamamen basarisiz
///   bir bagimlilik yaratir (bu projede tekrarlanan, gozlemlenmis bir
///   sorun). `allowRuntimeFetching = false`, google_fonts'un kendi
///   belgeledigi standart test-izolasyon deseni: testler sistem/fallback
///   fontuna duser, hicbir ag cagrisi yapilmaz. Testler zaten metin
///   varligini/duzeni kontrol ediyor, piksel-mukemmel font render'ini
///   degil -- bu yuzden gorsel fark onemsizdir.
///
///   SQLite (drift, Faz 13): `AquaGuardVeritabani`'nin gercek (native)
///   baglanti yolu `path_provider` platform kanalini kullanir, bu kanal
///   duz `flutter test` host'unda mevcut degildir. `testBaglantiFabrikasi`
///   GLOBAL olarak bellek-ici (`NativeDatabase.memory()`) bir veritabanina
///   yonlendirilir -- 334+ mevcut test dosyasi (hepsi parametresiz
///   `UygulamaDurumu()` kullanir) DEGISMEDEN calisir, her cagri kendi
///   izole veritabanini alir.
///
/// Tarih:  2026-09-16 (ilk yazim) / 2026-09-17 (SQLite test izolasyonu)
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aquaguard_mobile/services/veritabani.dart';

Future<void> testExecutable(FutureOr<void> Function() main) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  AquaGuardVeritabani.testBaglantiFabrikasi = NativeDatabase.memory;
  // Her testin KENDI izole bellek-ici veritabanini acmasi BEKLENEN/ISTENEN
  // davranistir (bkz. AquaGuardVeritabani.testBaglantiFabrikasi notu) --
  // drift'in "ayni QueryExecutor'i paylasan birden fazla veritabani"
  // uyarisi burada YANLIS ALARM, kapatilir.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await main();
}
