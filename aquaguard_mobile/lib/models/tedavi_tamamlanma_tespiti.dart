/// AquaGuard - Tedavi Tamamlanma Tespiti (paylaşılan saf mantık)
/// ==================================================================
///
/// Amac:
///   Bir zonun KRONOLOJIK (eskiden yeniye sıralı) geçmişinde, her TAM
///   olarak tamamlanmış tedavinin (tedavi aşaması + zorunlu durulama
///   İKİSİ DE bitmiş) geçişini bulan paylaşılan saf üreteç.
///
///   Hem `tedavi_karsilastirmasi.dart` (en son tamamlananı bulmak için)
///   hem de `tedavi_basari_analizi.dart` (TÜMÜNÜ sayıp başarı oranı
///   hesaplamak için) bu TEK tespit mantığını kullanır -- "tedaviAktif
///   YOK'a dönmesi" ile "durulamanın GERÇEKTEN bitmesi"nin FARKLI anlar
///   olduğu inceliği iki yerde ayrı ayrı yanlış kopyalanmasın diye (bkz.
///   feedback: schema single source of truth).
///
/// Tarih:  2026-09-05
library;

import 'sensor_okuma.dart';

/// Tamamlanmış bir tedavinin geçişi: [baslangicIndeksi] tedavinin
/// BAŞLADIĞI anın indeksi, [bitisIndeksi] durulamanın da GERÇEKTEN
/// bittiği ilk anın indeksi (kronolojik listede).
class TamamlananTedaviGecisi {
  final int baslangicIndeksi;
  final int bitisIndeksi;

  const TamamlananTedaviGecisi({
    required this.baslangicIndeksi,
    required this.bitisIndeksi,
  });
}

/// [kronolojik]: eskiden yeniye sıralı. Her TAM tamamlanmış tedavi için bir
/// geçiş döner (en eskiden en yeniye sıralı).
Iterable<TamamlananTedaviGecisi> tamamlananTedavileriBul(
  List<SensorOkuma> kronolojik,
) sync* {
  for (var i = 1; i < kronolojik.length; i++) {
    final onceki = kronolojik[i - 1];
    final simdiki = kronolojik[i];
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
      continue; // elimizdeki veri bitene kadar durulama hala suruyor
    }

    // Bu tedavinin (onceki ile ayni turden geriye giden) BASLADIGI ana kadar git.
    var baslangicIndeksi = i - 1;
    while (baslangicIndeksi > 0 &&
        kronolojik[baslangicIndeksi - 1].tedaviAktif == onceki.tedaviAktif) {
      baslangicIndeksi--;
    }
    if (baslangicIndeksi == 0) continue; // oncesine dair kayit yok

    yield TamamlananTedaviGecisi(
      baslangicIndeksi: baslangicIndeksi,
      bitisIndeksi: sonIndeks,
    );
  }
}
