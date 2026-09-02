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

  // --- Konu (topic) sablonlari -- firmware/mqtt_handler.h ile BIREBIR AYNI ---
  static String veriKonusu(int zone) => 'aquaguard/zone$zone/veri';
  static String durumKonusu(int zone) => 'aquaguard/zone$zone/durum';

  // --- Operator komut konusu -- SADECE uygulamadan cihaza (yayinlanmaz,
  //     retained DEGIL): manuel mudahale (bkz. providers/uygulama_durumu.dart
  //     manuelTedaviBaslat/Durdur/NormaleDondur) bu konuya JSON komut yayinlar,
  //     firmware/mqtt_handler.h buna abone olup treatment.h'ye iletir. ---
  static String komutKonusu(int zone) => 'aquaguard/zone$zone/komut';

  // --- Tedavi sureleri (firmware/config.h TEDAVI_*_SURESI_MS ile ayni, saniye) ---
  static const Map<TedaviTuru, int> tedaviSuresiSaniye = {
    TedaviTuru.asitDozlama: 30,
    TedaviTuru.klorEnjeksiyon: 30,
    TedaviTuru.yuksekBasincliYikama: 60,
  };

  static const int durulamaSuresiSaniye = 45;

  // --- Cevrimdisi kabul edilme suresi: bu sureden uzun mesaj gelmezse
  //     baglanti "cevrimdisi" sayilir ve son bilinen durum gosterilir ---
  static const Duration cevrimdisiEsigi = Duration(seconds: 30);
}
