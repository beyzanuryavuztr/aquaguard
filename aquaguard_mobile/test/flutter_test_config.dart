/// AquaGuard - Test Yapılandırması (google_fonts Ağ İzolasyonu)
/// =================================================================
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
/// Tarih:  2026-09-16
library;

import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() main) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await main();
}
