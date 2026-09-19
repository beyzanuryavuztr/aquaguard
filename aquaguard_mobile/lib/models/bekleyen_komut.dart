/// AquaGuard - Komut ACK/NACK Sonucu (Sema v2)
/// =================================================
///
/// Amac:
///   Operatorun gonderdigi bir komutun (su an SADECE manuel tedavi
///   baslatma) cihaz tarafindan GERCEKTEN alinip alinmadigini tasir --
///   onceden bu "gonder ve unut" seklindeydi (bkz. MqttServisi.komutGonder
///   eski imzasi). `uygulandi`/`reddedildi` cihazdan gelen ACK/NACK'e
///   karsilik gelir; `zamanAsimi`, 30 saniye icinde HICBIR yanit
///   gelmediginde kullanilir (bkz. AyarlarSabitleri.komutZamanAsimi) --
///   operatore "cihazla baglanti sorunlu olabilir" bilgisini tasir, "mutex
///   kilidi reddetti" ile KARISTIRILMAMALIDIR.
///
///   Firmware (2026-09-19) ve Python mock komut_durumu konusunu yayinlar
///   (bkz. firmware/mqtt_handler.h _komutDurumuYayinla). GERCEK donanimda
///   henuz denenmedi -- yanit gelmezse zamanAsimi sonucu KALIR. Demo Modu bu
///   yolu hic kullanmaz (dogrudan SimulasyonServisi uzerinden calisir, bkz.
///   UygulamaDurumu.manuelTedaviBaslat).
///
/// Tarih:  2026-09-16
library;

enum KomutSonucu { uygulandi, reddedildi, zamanAsimi }
