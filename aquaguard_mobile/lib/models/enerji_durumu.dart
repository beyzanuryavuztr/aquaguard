/// AquaGuard - Enerji Durumu Hesaplayıcısı (SİMÜLE)
/// ======================================================
///
/// Amac:
///   `widgets/enerji_gostergesi.dart` VE `UygulamaDurumu` (düşük pil
///   bildirimi tetiklemek için) AYNI pil yüzdesi hesabını kullanır --
///   tek kaynak, iki yerde farklı sayı üretmesin.
///
///   DÜRÜSTLÜK NOTU: bkz. enerji_gostergesi.dart'ın başlığı -- bu GERÇEK
///   bir telemetri değildir, firmware/MQTT şeması böyle bir alan
///   taşımıyor. Günün tarihine bağlı deterministik bir "şarj döngüsü"
///   simüle eder: ~%90'dan başlar, her gün 8 puan düşer, 10 günde bir
///   (bakım/güneş şarjı) tekrar %90'a döner -- böylece düşük pil
///   bildirimi ARA SIRA gerçekten tetiklenebilir.
///
/// Tarih:  2026-09-05
library;

class EnerjiDurumu {
  EnerjiDurumu._();

  static const int dusukPilEsigi = 30;

  static int pilYuzdesiHesapla({DateTime? simdi}) {
    final gun = (simdi ?? DateTime.now())
        .difference(DateTime(2026, 1, 1))
        .inDays;
    return 90 - (gun % 10) * 8;
  }

  static bool gsmGucluMu({DateTime? simdi}) {
    final gun = (simdi ?? DateTime.now())
        .difference(DateTime(2026, 1, 1))
        .inDays;
    return gun % 7 != 0; // cogunlukla guclu, haftada bir gun orta
  }
}
