/// AquaGuard - Tedavi Once/Sonra Karsilastirmasi
/// ==================================================
///
/// Amac:
///   Bir zonun geçmişinde EN SON TAMAMLANMIŞ tedavinin hemen ÖNCESİNDEKİ ve
///   (tedavi + zorunlu durulama tamamen bittikten) hemen SONRASINDAKİ debi
///   değerlerini bulan SAF bir fonksiyon -- "tedavi gerçekten işe yaradı mı?"
///   sorusuna Zon Detay'da somut bir sayıyla cevap verir (Önce/Sonra kartı).
///
/// Tarih:  2026-09-04
library;

import 'sensor_okuma.dart';
import 'tedavi_tamamlanma_tespiti.dart';

class TedaviOncesiSonrasi {
  final double onceDebi;
  final double sonraDebi;
  final DateTime tedaviBaslangicZamani;

  const TedaviOncesiSonrasi({
    required this.onceDebi,
    required this.sonraDebi,
    required this.tedaviBaslangicZamani,
  });
}

/// `gecmisEnYeniOnce`: UygulamaDurumu.gecmis(zone) formatında, EN YENİ ÖNCE
/// sıralı. Geçmişte tamamlanmış (başlayıp, ardından hem tedaviAktif==yok
/// hem de zorunlu durulaması bitmiş) en son tedaviyi bulur; hiç tamamlanmış
/// tedavi yoksa (veya geçmiş çok kısaysa, veya en son tedavinin durulaması
/// elimizdeki veri içinde henüz bitmemişse) null döner.
TedaviOncesiSonrasi? tedaviOncesiSonrasiBul(
  List<SensorOkuma> gecmisEnYeniOnce,
) {
  if (gecmisEnYeniOnce.length < 2) return null;
  final kronolojik = gecmisEnYeniOnce.reversed.toList(); // eskiden yeniye
  final gecisler = tamamlananTedavileriBul(kronolojik).toList();
  if (gecisler.isEmpty) return null;

  final son = gecisler.last; // en son tamamlanan tedavi
  return TedaviOncesiSonrasi(
    onceDebi: kronolojik[son.baslangicIndeksi - 1].debi,
    sonraDebi: kronolojik[son.bitisIndeksi].debi,
    tedaviBaslangicZamani: kronolojik[son.baslangicIndeksi].zaman,
  );
}
