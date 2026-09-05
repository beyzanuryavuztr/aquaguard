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

  // Sondan basa dogru, TEDAVI ASAMASININ bittigi (tedaviAktif'in YOK'a
  // DONDUGU) en son anı bul -- durulamanin kendisi ayrı bir bayraktır
  // (tedaviAktif zaten durulama sırasında da YOK'tur), bu yüzden bitis
  // anini ayrı olarak ILERI dogru ariyoruz.
  for (var i = kronolojik.length - 1; i > 0; i--) {
    final simdiki = kronolojik[i];
    final onceki = kronolojik[i - 1];
    final tedaviAsamasiBittiMi =
        onceki.tedaviAktif != TedaviTuru.yok &&
        simdiki.tedaviAktif == TedaviTuru.yok;
    if (!tedaviAsamasiBittiMi) continue;

    // Zorunlu durulamanin da GERCEKTEN bittigi ilk anı ileri dogru ara.
    var sonIndeks = i;
    while (sonIndeks < kronolojik.length - 1 &&
        kronolojik[sonIndeks].durulamaAktif) {
      sonIndeks++;
    }
    if (kronolojik[sonIndeks].durulamaAktif) {
      // Elimizdeki veri bitene kadar durulama hala suruyor -- bu tedavi
      // henuz "tamamlanmis" sayilmaz, kart gosterilmez.
      return null;
    }

    // Bu tedavinin (onceki ile ayni turden geriye giden) BASLADIGI ana kadar git.
    var baslangicIndeksi = i - 1;
    while (baslangicIndeksi > 0 &&
        kronolojik[baslangicIndeksi - 1].tedaviAktif == onceki.tedaviAktif) {
      baslangicIndeksi--;
    }
    if (baslangicIndeksi == 0) return null; // oncesine dair kayit yok

    return TedaviOncesiSonrasi(
      onceDebi: kronolojik[baslangicIndeksi - 1].debi,
      sonraDebi: kronolojik[sonIndeks].debi,
      tedaviBaslangicZamani: kronolojik[baslangicIndeksi].zaman,
    );
  }
  return null;
}
