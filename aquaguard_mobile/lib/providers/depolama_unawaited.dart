/// AquaGuard - Depolama Yazimlari icin "Ates Et ve Unut" Yardimcisi
/// =======================================================================
///
/// Amac:
///   `Future`'i beklenmeden calistirmak icin -- depolama yazma islemlerinin
///   UI'yi bloklamasini istemiyoruz, ama hatalari da sessizce yutmak
///   istemiyoruz (bkz. [[feedback-verify-dont-just-claim]]). `dart:async`
///   paketinin kendi `unawaited()` fonksiyonundan BILEREK FARKLI: o hatalari
///   TAMAMEN yutar, bu ise en azindan debugPrint ile loglar.
///
///   Mimari bolunme (Faz 12) sonrasi TUM providerlar (eskiden tek bir
///   UygulamaDurumu icinde ozel/private tanimliyken) bu TEK paylasilan
///   fonksiyonu kullanir -- her providerin kendi kopyasini tanimlamasi,
///   birden fazla provider'i AYNI dosyada birlikte import eden bir yerde
///   (orn. facade) "ambiguous name" derleme hatasina yol acardi.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/foundation.dart' show debugPrint;

void unawaited(Future<void> future) {
  future.catchError((Object hata) {
    debugPrint('AquaGuard depolama hatasi: $hata');
  });
}
