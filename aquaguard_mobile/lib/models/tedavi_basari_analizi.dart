/// AquaGuard - Tedavi Basari Analizi
/// =====================================
///
/// Amac:
///   Bir zonun geçmişindeki TÜM tamamlanmış tedavilerin, debiyi referans
///   değere (config/sensor_imzalari.dart'ın tek kaynağı `referansDebi`,
///   4.0 LPM) makul bir toleransla GERÇEKTEN döndürüp döndürmediğini
///   sayan saf fonksiyon -- Tedavi Geçmişi ekranındaki "Ortalama Başarı
///   Oranı" kartının dayandığı hesap.
///
///   Tespit mantığı `tedavi_tamamlanma_tespiti.dart` ile PAYLAŞILIR (aynı
///   "tedavi bitti" / "durulama gerçekten bitti" ayrımı, bkz. o dosyanın
///   dokümantasyonu) -- tek kaynak, iki yerde kopyalanmaz.
///
/// Tarih:  2026-09-05
library;

import '../config/sensor_imzalari.dart';
import 'sensor_okuma.dart';
import 'tedavi_tamamlanma_tespiti.dart';

/// Referans debiden bu kadar (LPM) sapma hala "başarılı" sayılır --
/// sensör gürültüsü/doğal salınım payı (bkz. sensor_imzalari.dart'taki
/// 'normal' sınıfının debi std'si ~0.25 LPM; 0.5 LPM bunun 2 katı,
/// makul bir tolerans).
const double basariToleransi = 0.5;

class TedaviBasariAnalizi {
  final int tamamlananSayisi;
  final int basariliSayisi;

  const TedaviBasariAnalizi({
    required this.tamamlananSayisi,
    required this.basariliSayisi,
  });

  double get basariOrani =>
      tamamlananSayisi == 0 ? 0.0 : basariliSayisi / tamamlananSayisi;

  /// Birden fazla zonun analizini TEK bir sistem-geneli ozete birlestirir.
  factory TedaviBasariAnalizi.birlestir(
    Iterable<TedaviBasariAnalizi> parcalar,
  ) {
    var tamamlanan = 0;
    var basarili = 0;
    for (final parca in parcalar) {
      tamamlanan += parca.tamamlananSayisi;
      basarili += parca.basariliSayisi;
    }
    return TedaviBasariAnalizi(
      tamamlananSayisi: tamamlanan,
      basariliSayisi: basarili,
    );
  }
}

/// [gecmisEnYeniOnce]: TEK BIR zonun UygulamaDurumu.gecmis(zone) formatında
/// (EN YENİ ÖNCE) geçmişi. Birden fazla zonu birleştirmek için her zonun
/// sonucunu ayrı hesaplayıp `TedaviBasariAnalizi.birlestir` ile toplayın --
/// zonların HAM okumalarını tek listede birleştirip bu fonksiyona vermeyin,
/// aksi halde bir zonun son okumasıyla diğerinin ilk okuması arasında SAHTE
/// bir "geçiş" tespit edilebilir.
TedaviBasariAnalizi tedaviBasarisiniHesapla(
  List<SensorOkuma> gecmisEnYeniOnce,
) {
  if (gecmisEnYeniOnce.length < 2) {
    return const TedaviBasariAnalizi(tamamlananSayisi: 0, basariliSayisi: 0);
  }
  final kronolojik = gecmisEnYeniOnce.reversed.toList();

  var tamamlanan = 0;
  var basarili = 0;
  for (final gecis in tamamlananTedavileriBul(kronolojik)) {
    tamamlanan++;
    final sonraDebi = kronolojik[gecis.bitisIndeksi].debi;
    if ((sonraDebi - referansDebi).abs() <= basariToleransi) {
      basarili++;
    }
  }
  return TedaviBasariAnalizi(
    tamamlananSayisi: tamamlanan,
    basariliSayisi: basarili,
  );
}
