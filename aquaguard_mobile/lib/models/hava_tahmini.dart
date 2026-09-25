/// AquaGuard - Hava Durumu Tahmini Veri Modeli (Faz 4, 2026-09-25)
/// ======================================================================
///
/// Amac:
///   Open-Meteo API'sinden (https://open-meteo.com) gelen gunluk tahmin
///   verisinin uygulama-ici temsili. Open-Meteo BILEREK secildi: API
///   ANAHTARI/hesap gerektirmez, ucretsizdir, ticari olmayan/kucuk olcekli
///   kullanim icin acikca tasarlanmistir -- projenin daha once benimsedigi
///   "guvenilmez/anahtarli dis servisten kacin" ilkesiyle CELISMEZ (o ilke
///   ucretli/anahtarli servisler icindi, bkz. models/sulama_onerisi.dart
///   dosya basi notu).
///
/// Tarih:  2026-09-25
library;

class GunlukHavaTahmini {
  final DateTime tarih;
  final double maksSicaklikC;
  final double minSicaklikC;
  /// 0-100 arasi, o gun icin en yuksek yagis olasiligi.
  final int yagisIhtimaliYuzde;
  final double toplamYagisMm;

  const GunlukHavaTahmini({
    required this.tarih,
    required this.maksSicaklikC,
    required this.minSicaklikC,
    required this.yagisIhtimaliYuzde,
    required this.toplamYagisMm,
  });
}

class HavaTahmini {
  final double enlem;
  final double boylam;
  final List<GunlukHavaTahmini> gunlukTahminler; // en yakin gun once
  final DateTime alinmaZamani;

  const HavaTahmini({
    required this.enlem,
    required this.boylam,
    required this.gunlukTahminler,
    required this.alinmaZamani,
  });

  GunlukHavaTahmini? get bugun =>
      gunlukTahminler.isNotEmpty ? gunlukTahminler.first : null;
  GunlukHavaTahmini? get yarin =>
      gunlukTahminler.length > 1 ? gunlukTahminler[1] : null;

  factory HavaTahmini.fromOpenMeteoJson(
    Map<String, dynamic> json, {
    required double enlem,
    required double boylam,
  }) {
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final tarihler = (daily['time'] as List<dynamic>? ?? [])
        .cast<String>();
    final maksSicaklik = (daily['temperature_2m_max'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final minSicaklik = (daily['temperature_2m_min'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final yagisIhtimali =
        (daily['precipitation_probability_max'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList();
    final yagisMm = (daily['precipitation_sum'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();

    final gunSayisi = tarihler.length;
    final gunlukler = <GunlukHavaTahmini>[
      for (var i = 0; i < gunSayisi; i++)
        GunlukHavaTahmini(
          tarih: DateTime.tryParse(tarihler[i]) ?? DateTime.now(),
          maksSicaklikC: i < maksSicaklik.length ? maksSicaklik[i] : 0.0,
          minSicaklikC: i < minSicaklik.length ? minSicaklik[i] : 0.0,
          yagisIhtimaliYuzde: i < yagisIhtimali.length ? yagisIhtimali[i] : 0,
          toplamYagisMm: i < yagisMm.length ? yagisMm[i] : 0.0,
        ),
    ];

    return HavaTahmini(
      enlem: enlem,
      boylam: boylam,
      gunlukTahminler: gunlukler,
      alinmaZamani: DateTime.now(),
    );
  }
}
