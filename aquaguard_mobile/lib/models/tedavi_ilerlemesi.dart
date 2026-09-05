/// AquaGuard - Tedavi Ilerlemesi Hesaplayicisi
/// ===============================================
///
/// Amac:
///   Aktif bir tedavinin (yuzde) ilerlemesini ve tahmini kalan suresini
///   hesaplayan SAF fonksiyon. `screens/aktif_tedavi_ekrani.dart` VE
///   `widgets/aktif_tedaviler_bolumu.dart` (Genel Bakis mini listesi)
///   AYNI hesabi kullanir -- daha once bu projede ayni mantigin iki
///   yerde birbirinden farkli elle yazilmasi gercek bir hataya sebep
///   olmustu (bkz. durum_renkleri.dart basindaki ZonOnceligi notu),
///   bu yuzden tek kaynak burasi.
///
/// Tarih:  2026-09-04
library;

import '../config/ayarlar_sabitleri.dart';
import 'sensor_okuma.dart';

class TedaviIlerlemesi {
  final double oran; // 0.0 - 1.0
  final int kalanSaniye;
  final int toplamSaniye;

  const TedaviIlerlemesi({
    required this.oran,
    required this.kalanSaniye,
    required this.toplamSaniye,
  });

  factory TedaviIlerlemesi.hesapla({
    required TedaviTuru tedavi,
    required DateTime? baslangic,
  }) {
    final toplamSaniye = AyarlarSabitleri.tedaviSuresiSaniye[tedavi] ?? 30;
    final gecenSaniye = baslangic == null
        ? 0
        : DateTime.now()
              .difference(baslangic)
              .inSeconds
              .clamp(0, toplamSaniye);
    final oran = toplamSaniye == 0 ? 0.0 : gecenSaniye / toplamSaniye;
    return TedaviIlerlemesi(
      oran: oran,
      kalanSaniye: toplamSaniye - gecenSaniye,
      toplamSaniye: toplamSaniye,
    );
  }
}
