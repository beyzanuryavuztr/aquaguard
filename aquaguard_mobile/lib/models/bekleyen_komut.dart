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
///   GERCEK donanim (firmware) HENUZ komut_durumu konusunu yayinlamiyor
///   (bkz. firmware/mqtt_handler.h sema v2 notu) -- bu yuzden pratikte
///   gercek MQTT modunda her komut su an icin HER ZAMAN zamanAsimi ile
///   sonuclanacaktir, donanim entegrasyonuna kadar. Demo Modu bu yolu hic
///   kullanmaz (dogrudan SimulasyonServisi uzerinden calisir, bkz.
///   UygulamaDurumu.manuelTedaviBaslat).
///
/// Tarih:  2026-09-16
library;

enum KomutSonucu { uygulandi, reddedildi, zamanAsimi }
