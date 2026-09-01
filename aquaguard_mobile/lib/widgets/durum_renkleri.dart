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
///   Mavi   -> Tedavi su an aktif olarak uygulaniyor
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';

class DurumRenkleri {
  DurumRenkleri._();

  static const Color cevrimdisi = Color(0xFF9E9E9E);
  static const Color normal = Color(0xFF2E7D32);
  static const Color belirsiz = Color(0xFFF9A825);
  static const Color tespitEdildi = Color(0xFFC62828);
  static const Color tedaviAktif = Color(0xFF1565C0);

  static Color renkGetir({required SensorOkuma? okuma, required bool cevrimici}) {
    if (okuma == null) return cevrimdisi;
    if (!cevrimici) return cevrimdisi;
    if (okuma.tedaviAktif != TedaviTuru.yok) return tedaviAktif;

    switch (okuma.durum) {
      case TeshisDurumu.normal:
        return normal;
      case TeshisDurumu.belirsiz:
        return belirsiz;
      case TeshisDurumu.tespitEdildi:
        return tespitEdildi;
      case TeshisDurumu.bilinmiyor:
        return cevrimdisi;
    }
  }

  static IconData ikonGetir({required SensorOkuma? okuma, required bool cevrimici}) {
    if (okuma == null || !cevrimici) return Icons.cloud_off;
    if (okuma.tedaviAktif != TedaviTuru.yok) return Icons.build_circle;

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

  static String ozetMetniGetir({required SensorOkuma? okuma, required bool cevrimici}) {
    if (okuma == null) return 'Henüz veri alınmadı';
    if (!cevrimici) return 'Çevrimdışı — son bilinen durum';
    if (okuma.tedaviAktif != TedaviTuru.yok) {
      return '${tedaviEtiketi(okuma.tedaviAktif)} uygulanıyor';
    }
    return durumEtiketi(okuma.durum);
  }
}
