/// AquaGuard - Uygulama Genelinde Kullanilan Sabitler
/// ======================================================
///
/// Amac:
///   MQTT baglanti varsayilanlari ve tedavi sureleri gibi, firmware
///   tarafiyla (config.h) TUTARLI kalmasi gereken sabitleri tek yerde
///   toplar. Tedavi sureleri, "aktif tedavi" ekranindaki ilerleme
///   cubugunu (progress bar) hesaplamak icin kullanilir; gercek surenin
///   ne zaman bittigini kesin olarak bilemeyiz (bu bilgi cihazdan
///   gelmiyor), bu yuzden config.h'deki sureler TAHMINI gosterge olarak
///   kullanilir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/sensor_okuma.dart';

class AyarlarSabitleri {
  AyarlarSabitleri._();

  // --- MQTT varsayilanlari (firmware/config.h ile ayni gelistirme brokeri) ---
  static const String varsayilanBroker = 'test.mosquitto.org';

  // Duz TCP portu (Android/masaustu icin) -- tarayici bunu KULLANAMAZ,
  // cunku tarayicilar ham TCP soketi acamaz.
  static const int varsayilanTcpPort = 1883;

  // WebSocket portu (Web/Chrome icin) -- test.mosquitto.org bu portta
  // MQTT-over-WebSocket dinler.
  static const int varsayilanWebSocketPort = 8080;

  /// Platforma gore doğru varsayilan portu doner. Web'de yanlislikla TCP
  /// portu (1883) kullanilirsa WebSocket baglantisi asla kurulamaz --
  /// bu yuzden varsayilan deger burada platforma gore SECILIR, sabit
  /// birakilmaz.
  static int get varsayilanPort =>
      kIsWeb ? varsayilanWebSocketPort : varsayilanTcpPort;

  // --- TLS/Guvenli baglanti portlari -- Ayarlar'daki "Guvenli Baglanti
  //     (TLS)" anahtari acilinca kullanilir. test.mosquitto.org bu iki
  //     portta da TLS dinler (8883: duz TLS soketi, 8081: WSS). Gercek
  //     uretimde kendi broker'inizin TLS dinleyici portuyla ESLESMELIDIR. ---
  static const int varsayilanTcpTlsPort = 8883;
  static const int varsayilanWebSocketTlsPort = 8081;

  /// guvenli=true ise platforma gore doğru TLS portunu, degilse duz
  /// baglanti portunu doner -- varsayilanPort ile AYNI platform mantigi.
  static int varsayilanPortGetir({required bool guvenli}) {
    if (guvenli) {
      return kIsWeb ? varsayilanWebSocketTlsPort : varsayilanTcpTlsPort;
    }
    return varsayilanPort;
  }

  // --- Konu (topic) sablonlari -- firmware/mqtt_handler.h ile BIREBIR AYNI ---
  static String veriKonusu(int zone) => 'aquaguard/zone$zone/veri';
  static String durumKonusu(int zone) => 'aquaguard/zone$zone/durum';

  // --- Operator komut konusu -- SADECE uygulamadan cihaza (yayinlanmaz,
  //     retained DEGIL): manuel mudahale (bkz. providers/uygulama_durumu.dart
  //     manuelTedaviBaslat/Durdur/NormaleDondur) bu konuya JSON komut yayinlar,
  //     firmware/mqtt_handler.h buna abone olup treatment.h'ye iletir. ---
  static String komutKonusu(int zone) => 'aquaguard/zone$zone/komut';

  // --- Komut durumu (ACK/NACK) konusu -- cihazdan uygulamaya, "komut_id"si
  //     verilen bir komutun islendigini bildirir (bkz. models/bekleyen_komut.dart,
  //     services/mqtt_servisi.dart). Gercek firmware HENUZ bunu yayinlamiyor
  //     (bkz. firmware/mqtt_handler.h sema v2 notu) -- altyapi hazir, donanim
  //     entegrasyonu bekleniyor. ---
  static String komutDurumuKonusu(int zone) =>
      'aquaguard/zone$zone/komut_durumu';

  // --- Komut ACK/NACK zaman asimi -- bu sureden uzun yanit gelmezse
  //     operatore "zaman asimi" gosterilir (bkz. providers/uygulama_durumu.dart
  //     _komutGonderVeOnayBekle). ---
  static const Duration komutZamanAsimi = Duration(seconds: 30);

  /// Yerel vana komutundan sonra, cihaz telemetrisiyle vana esitlemesinin
  /// ASKIYA alindigi sure (cihaz 10 sn yayinlar; komut + yansima payi).
  static const Duration vanaEsitlemeBeklemesi = Duration(seconds: 25);

  // --- Sensor gecmisi saklama (Y2) -- bellek ve veritabani AYNI seriyi tutar.
  //     Gercek cihaz 10 sn'de bir yayinlar (8.640 kayit/gun); ham kaydi tutmak
  //     10.000 satir sinirini ~28 saatte doldururdu ve "7 gun" trendleri
  //     bos/yanlis olurdu. Bu yuzden gecmise en fazla dakikada BIR kayit
  //     yazilir; DURUM DEGISIMLERI (tespit/tedavi/durulama) ise ARADAKI sure
  //     ne olursa olsun HEMEN yazilir (olay analizi hicbir seyi kacirmaz).
  //     60 sn x 7 gun = 10.080 kayit/zon ~ repository siniri (10.000 + pay). ---
  static const Duration gecmisKayitAraligi = Duration(seconds: 60);
  static const Duration gecmisSaklamaSuresi = Duration(days: 7);
  static const int gecmisBellekMaksimumKayit = 10500;

  // --- Offline mod: cihazin kendi agi/broker baglantisi yokken kuyruga
  //     alinan komutlarin gecerlilik suresi -- bundan eski komutlar
  //     SESSIZCE silinir, otomatik gonderilmez (bkz. models/
  //     kuyruklanmis_komut.dart). ---
  static const Duration kuyrukKomutGecerlilikSuresi = Duration(minutes: 5);

  // --- Tedavi sureleri (firmware/config.h TEDAVI_*_SURESI_MS ile ayni, saniye) ---
  static const Map<TedaviTuru, int> tedaviSuresiSaniye = {
    TedaviTuru.asitDozlama: 30,
    TedaviTuru.klorEnjeksiyon: 30,
    TedaviTuru.yuksekBasincliYikama: 60,
    // Faz 3 (2026-09-25) -- firmware/config.h TEDAVI_BESIN_SIVI_SURESI_MS/
    // TEDAVI_BESIN_TOZ_SURESI_MS (karistirma+pompalama toplami) ile ayni.
    TedaviTuru.besinSivi: 30,
    TedaviTuru.besinToz: 40,
  };

  static const int durulamaSuresiSaniye = 45;

  // --- Sureli sulama (firmware/config.h SULAMA_MAKS_SURE_DK ve
  //     python/aquaguard_mock_yayinci.py SULAMA_MAKS_SURE_DK ile BIREBIR
  //     AYNI olmali -- tek kaynak. Kullanici bundan uzun bir sure giremez,
  //     girmeye calisirsa form bunu reddeder/kirpar. ---
  static const int sulamaMaksSureDakika = 180;

  // --- Cevrimdisi kabul edilme suresi: bu sureden uzun mesaj gelmezse
  //     baglanti "cevrimdisi" sayilir ve son bilinen durum gosterilir ---
  static const Duration cevrimdisiEsigi = Duration(seconds: 30);
}
