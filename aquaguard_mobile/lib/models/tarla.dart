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
///   konum/aciklama/fotografBase64 TAMAMEN OPSIYONELDIR ve sensor/teshis
///   verisinden BAGIMSIZDIR -- bunlar operatorun kendi girdigi, tarlayi
///   "tanimlayan" profil bilgileridir (bkz. screens/tarla_secim_ekrani.dart
///   formu, widgets/tarla_profil_karti.dart).
///
/// Tarih:  2026-09-01 (profil alanlari: 2026-09-03)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

class Tarla {
  final String id;
  final String ad;
  final List<int> zonNumaralari;
  final String? konum;
  final String? aciklama;
  final String? fotografBase64;

  const Tarla({
    required this.id,
    required this.ad,
    required this.zonNumaralari,
    this.konum,
    this.aciklama,
    this.fotografBase64,
  });

  Tarla kopyalaVeGuncelle({
    String? ad,
    List<int>? zonNumaralari,
    String? konum,
    String? aciklama,
    String? fotografBase64,
    bool fotografiKaldir = false,
  }) {
    return Tarla(
      id: id,
      ad: ad ?? this.ad,
      zonNumaralari: zonNumaralari ?? this.zonNumaralari,
      konum: konum ?? this.konum,
      aciklama: aciklama ?? this.aciklama,
      fotografBase64: fotografiKaldir
          ? null
          : (fotografBase64 ?? this.fotografBase64),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ad': ad,
    'zonNumaralari': zonNumaralari,
    'konum': konum,
    'aciklama': aciklama,
    'fotografBase64': fotografBase64,
  };

  factory Tarla.fromJson(Map<String, dynamic> json) => Tarla(
    id: json['id'] as String,
    ad: json['ad'] as String,
    zonNumaralari: (json['zonNumaralari'] as List<dynamic>)
        .map((e) => (e as num).toInt())
        .toList(),
    konum: json['konum'] as String?,
    aciklama: json['aciklama'] as String?,
    fotografBase64: json['fotografBase64'] as String?,
  );

  /// Uygulama ilk acildiginda (kayitli tarla yokken) gosterilecek varsayilan
  /// ornek tarlalar. Bilerek TEK degil COKLU tarla/zon ile baslar --
  /// AquaGuard'in temel iddialarindan biri "birden fazla tarla destegi"dir
  /// (bkz. PROJE_BRIEF.md SS4.4); tek zonlu bir demo bu yetenegi hic
  /// gostermez ve her ekran (Istatistikler, Aktivite Gecmisi, Tarlalar) gercek
  /// veri olmadigi icin bomboş gorunur. 3 tarla / 6 zon, Simulasyon Modu'nun
  /// her zonu BAGIMSIZ rastgele bir senaryoyla calistirmasiyla birlikte,
  /// demoyu ilk acilista bile dolu ve gercekci gosterir. Konum/aciklama
  /// alanlari da AYNI nedenle bos birakilmaz -- profil kartinin/asistanin
  /// ilk acilista bile "gercek bir ciftlik" hissi vermesi icin doldurulur.
  static List<Tarla> varsayilanListe() => const [
    Tarla(
      id: 'tarla-1',
      ad: 'Kuzey Tarlası',
      zonNumaralari: [1, 2, 3],
      konum: 'Şanlıurfa, Harran Ovası',
      aciklama: 'Pamuk ekili, toprak altı damla sulama ile 3 parsel.',
    ),
    Tarla(
      id: 'tarla-2',
      ad: 'Güney Tarlası',
      zonNumaralari: [4, 5],
      konum: 'Şanlıurfa, Akçakale yolu üzeri',
      aciklama: 'Mısır ekili, 2 parsel.',
    ),
    Tarla(
      id: 'tarla-3',
      ad: 'Sera Bölgesi',
      zonNumaralari: [6],
      konum: 'Şanlıurfa, merkez sera tesisi',
      aciklama: 'Kapalı sera, domates yetiştiriciliği.',
    ),
  ];
}
