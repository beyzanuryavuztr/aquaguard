/// AquaGuard - Tarla (Cok Tarlali Destek) Veri Modeli
/// ======================================================
///
/// Amac:
///   Uygulama, birden fazla tarlayi ve her tarladaki birden fazla zonu
///   (her zon = bir Deneyap Kart cihazi) yonetebilir. Bu model, tarla
///   bilgisini ve o tarlaya ait zon numaralarini tutar. Tum tarlalar ayni
///   MQTT brokerina baglanir; zonlar konu (topic) icindeki zon numarasiyla
///   birbirinden ayrilir ("aquaguard/zone{N}/veri").
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

class Tarla {
  final String id;
  final String ad;
  final List<int> zonNumaralari;

  const Tarla({
    required this.id,
    required this.ad,
    required this.zonNumaralari,
  });

  Tarla kopyalaVeGuncelle({String? ad, List<int>? zonNumaralari}) {
    return Tarla(
      id: id,
      ad: ad ?? this.ad,
      zonNumaralari: zonNumaralari ?? this.zonNumaralari,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ad': ad,
    'zonNumaralari': zonNumaralari,
  };

  factory Tarla.fromJson(Map<String, dynamic> json) => Tarla(
    id: json['id'] as String,
    ad: json['ad'] as String,
    zonNumaralari: (json['zonNumaralari'] as List<dynamic>)
        .map((e) => (e as num).toInt())
        .toList(),
  );

  /// Uygulama ilk acildiginda (kayitli tarla yokken) gosterilecek varsayilan
  /// ornek tarlalar. Bilerek TEK degil COKLU tarla/zon ile baslar --
  /// AquaGuard'in temel iddialarindan biri "birden fazla tarla destegi"dir
  /// (bkz. PROJE_BRIEF.md SS4.4); tek zonlu bir demo bu yetenegi hic
  /// gostermez ve her ekran (Istatistikler, Aktivite Gecmisi, Tarlalar) gercek
  /// veri olmadigi icin bomboş gorunur. 3 tarla / 6 zon, Simulasyon Modu'nun
  /// her zonu BAGIMSIZ rastgele bir senaryoyla calistirmasiyla birlikte,
  /// demoyu ilk acilista bile dolu ve gercekci gosterir.
  static List<Tarla> varsayilanListe() => const [
    Tarla(id: 'tarla-1', ad: 'Kuzey Tarlası', zonNumaralari: [1, 2, 3]),
    Tarla(id: 'tarla-2', ad: 'Güney Tarlası', zonNumaralari: [4, 5]),
    Tarla(id: 'tarla-3', ad: 'Sera Bölgesi', zonNumaralari: [6]),
  ];
}
