/// AquaGuard - Durum Renk/Ikon Yardimcilari
/// ============================================
///
/// Amac:
///   Uygulama genelinde tutarli renk kodlamasi saglar (brief'te istenen
///   "yeşil/sarı/kırmızı" zon durumu gostergesi). Tum ekranlar bu tek
///   kaynaktan renk alir; boylece "kirmizi neyi ifade ediyor" sorusunun
///   TEK bir cevabi olur.
///
/// Renk anlamlari:
///   Gri    -> Zon cevrimdisi (son bilinen veri gosteriliyor)
///   Yesil  -> Normal, tikanma yok
///   Sari   -> Belirsiz (guven dusuk), operator kontrolu gerekiyor
///   Kirmizi-> Tikanma tespit edildi (tedavi tetiklendi veya tetiklenecek)
///   Mavi   -> Tedavi aktif UYGULANIYOR YA DA zorunlu durulama suruyor --
///             ikisi de "sistem su an mesgul, henuz tam olarak normale
///             donmedi" anlamina gelir ve AYNI renkle gosterilir (durulama
///             suren bir zonu duz yesil gostermek, ayni ekranda "Zorunlu
///             durulama suruyor" banneri ile celisir).
///
/// Tarih:  2026-09-01 (durulama tutarliligi + tek kaynak oncelik: 2026-09-03)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';

/// Bir zonun "ne kadar dikkat gerektirdigi" onceligi, EN DUSUKTEN EN
/// YUKSEGE sirali. TEK KAYNAK: hem tarla kartinin (bir tarladaki en
/// oncelikli zonun rengini secmek icin) hem de
/// UygulamaDurumu.durumOzetiHesapla'nin (ozet sayaclari icin) kullanmasi
/// gereken ortak siniflandirma budur. Daha once bu iki yerde BIRBIRINDEN
/// FARKLI sirali elle yazilmis kopyalar vardi (tarla karti "tespit"i
/// tedaviden daha oncelikli sayiyordu, ozet ise tam tersini) -- bu, ayni
/// projede daha once yasanmis "sema/mantik tek kaynak degil" hatasinin bir
/// baska ornegiydi.
enum ZonOnceligi { cevrimdisi, normal, belirsiz, tespitEdildi, tedavide }

class DurumRenkleri {
  DurumRenkleri._();

  static const Color cevrimdisi = Color(0xFF6B7A8C);
  static const Color normal = Color(0xFF43A047); // Basari (marka paleti)
  static const Color belirsiz = Color(0xFFFFB300); // Uyari (marka paleti)
  static const Color tespitEdildi = Color(0xFFE53935); // Tehlike (marka paleti)
  // "Tedavide" rengi KASITLI olarak marka vurgu rengi (#00BFA6 turkuvaz)
  // DEGILDIR -- ikisi karisirsa "bu turkuvaz marka mi yoksa bir durum mu?"
  // belirsizligi olusur (bkz. tema.dart dosya basi aciklamasi).
  static const Color tedaviAktif = Color(0xFF2E90FA);

  static ZonOnceligi onceligiBelirle({
    required SensorOkuma? okuma,
    required bool cevrimici,
  }) {
    if (okuma == null || !cevrimici) return ZonOnceligi.cevrimdisi;
    if (okuma.tedaviAktif != TedaviTuru.yok || okuma.durulamaAktif) {
      return ZonOnceligi.tedavide;
    }
    switch (okuma.durum) {
      case TeshisDurumu.tespitEdildi:
        return ZonOnceligi.tespitEdildi;
      case TeshisDurumu.belirsiz:
        return ZonOnceligi.belirsiz;
      case TeshisDurumu.normal:
      case TeshisDurumu.bilinmiyor:
        return ZonOnceligi.normal;
    }
  }

  static Color renkGetir({
    required SensorOkuma? okuma,
    required bool cevrimici,
  }) {
    switch (onceligiBelirle(okuma: okuma, cevrimici: cevrimici)) {
      case ZonOnceligi.cevrimdisi:
        return cevrimdisi;
      case ZonOnceligi.normal:
        return normal;
      case ZonOnceligi.belirsiz:
        return belirsiz;
      case ZonOnceligi.tespitEdildi:
        return tespitEdildi;
      case ZonOnceligi.tedavide:
        return tedaviAktif;
    }
  }

  static IconData ikonGetir({
    required SensorOkuma? okuma,
    required bool cevrimici,
  }) {
    if (okuma == null || !cevrimici) return Icons.cloud_off;
    if (okuma.tedaviAktif != TedaviTuru.yok) return Icons.build_circle;
    if (okuma.durulamaAktif) return Icons.water_drop;

    switch (okuma.durum) {
      case TeshisDurumu.normal:
        return Icons.check_circle;
      case TeshisDurumu.belirsiz:
        return Icons.help;
      case TeshisDurumu.tespitEdildi:
        return Icons.warning;
      case TeshisDurumu.bilinmiyor:
        return Icons.cloud_off;
    }
  }

  static String ozetMetniGetir({
    required SensorOkuma? okuma,
    required bool cevrimici,
  }) {
    if (okuma == null) return 'Henüz veri alınmadı';
    if (!cevrimici) return 'Çevrimdışı — son bilinen durum';
    if (okuma.tedaviAktif != TedaviTuru.yok) {
      return '${tedaviEtiketi(okuma.tedaviAktif)} uygulanıyor';
    }
    if (okuma.durulamaAktif) return 'Zorunlu durulama sürüyor';
    return durumEtiketi(okuma.durum);
  }
}
