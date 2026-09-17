/// AquaGuard - Hata Gunlugu Servisi
/// =====================================
///
/// Amac:
///   Yakalanan (FlutterError.onError) VE yakalanmamis (runZonedGuarded)
///   TUM hatalari, uygulama coksede kaybolmayacak sekilde KALICI olarak
///   kaydeder -- bkz. main.dart'taki kurulum. Ucuncu parti bir servise
///   (Crashlytics/Sentry) BILEREK baglanmiyoruz: bu proje internet
///   OLMADAN calisabilmeyi (offline-first) temel ilke sayiyor, bir hata
///   raporlama servisinin agdan geri donmemesi/basarisiz olmasi kendi
///   basina yeni bir soruna donusmemeli. Yerel dosya/localStorage +
///   Ayarlar'dan "Dışa Aktar" (mevcut CSV disa aktarma deseniyle ayni)
///   yeterli ve bu projenin felsefesiyle tutarli.
///
/// Tarih:  2026-09-18
library;

import 'package:flutter/foundation.dart';

import 'hata_gunlugu_kalici_yazici_factory.dart';

class HataGunluguServisi {
  HataGunluguServisi._();

  static const _maksimumBellekteTutulan = 500;
  static final List<String> _girdiler = [];
  static bool _hazir = false;

  /// EN YENI EN SONDA (kronolojik) -- ekranda/disa aktarimda ters
  /// cevirmeye gerek kalmadan dogrudan gosterilebilir.
  static List<String> get girdiler => List.unmodifiable(_girdiler);

  /// main()'de, runApp() cagrilmadan ONCE (ayni zone icinde) cagrilmalidir --
  /// bkz. main.dart. Kalici depodaki onceki oturumlarin gunluklerini
  /// belleğe yukler ki uygulama yeniden acildiginda gecmis hatalar
  /// kaybolmasin.
  static Future<void> baslat() async {
    if (_hazir) return;
    await kaliciYaziciyiHazirla();
    _girdiler
      ..clear()
      ..addAll(kaliciGunlugunuOku());
    _hazir = true;
  }

  /// TEK giris noktasi -- FlutterError.onError VE runZonedGuarded'in
  /// onError'undan cagrilir. [baglam] hatanin nereden geldigini ayirt
  /// etmeye yarar ("FlutterError" vs "Yakalanmamis").
  static void logla(Object hata, StackTrace? yigin, {String? baglam}) {
    final zamanDamgasi = DateTime.now().toIso8601String();
    final baslikEki = baglam == null ? '' : ' [$baglam]';
    final satir = '[$zamanDamgasi]$baslikEki $hata';

    _girdiler.add(satir);
    if (yigin != null) {
      // Yigin izini TAMAMI ile degil, ilk birkac satiriyla sakla -- tam
      // yigin izleri onlarca satir olabilir, gunluk hizla sisirilmis olur;
      // ilk birkac satir genelde hatanin kaynagini teshis etmeye yeter.
      final yiginOzeti = yigin.toString().split('\n').take(6).join('\n');
      _girdiler.add(yiginOzeti);
    }

    if (_girdiler.length > _maksimumBellekteTutulan) {
      _girdiler.removeRange(0, _girdiler.length - _maksimumBellekteTutulan);
    }

    kaliciYaz(satir);
    if (yigin != null) {
      kaliciYaz(yigin.toString().split('\n').take(6).join('\n'));
    }

    debugPrint('[AquaGuard/Hata]$baslikEki $hata');
  }

  /// Ayarlar'daki "Hata Günlüğünü Dışa Aktar" butonu tarafindan kullanilir.
  static String metinOlarakBirlestir() => _girdiler.join('\n');

  /// SADECE testler icin: bellekteki gunlugu sifirlar (kalici depoyu
  /// ETKILEMEZ) -- testler arasi durum sizintisini onler.
  @visibleForTesting
  static void sifirla() {
    _girdiler.clear();
    _hazir = false;
  }
}
