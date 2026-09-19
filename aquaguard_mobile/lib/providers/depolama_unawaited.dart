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

/// Henuz tamamlanmamis "ates et ve unut" yazimlari. Veritabani kapatilmadan
/// ONCE bunlarin bitmesi beklenir (bkz. [bekleyenYazimlariBekle]) -- aksi
/// halde dispose() sirasinda yarim kalan bir transaction "database has
/// already been closed" hatasiyla dusuyor ve yazilmasi gereken veri
/// kayboluyordu (A5).
final Set<Future<void>> _bekleyenYazimlar = {};

void unawaited(Future<void> future) {
  late final Future<void> izlenen;
  izlenen = future
      .catchError((Object hata) {
        debugPrint('AquaGuard depolama hatasi: $hata');
      })
      .whenComplete(() => _bekleyenYazimlar.remove(izlenen));
  _bekleyenYazimlar.add(izlenen);
}

/// O ana kadar baslatilmis (ve bu sirada baslatilanlar dahil) tum yazimlar
/// bitene kadar bekler. Hicbir zaman hata firlatmaz.
Future<void> bekleyenYazimlariBekle() async {
  while (_bekleyenYazimlar.isNotEmpty) {
    await Future.wait(_bekleyenYazimlar.toList());
  }
}
