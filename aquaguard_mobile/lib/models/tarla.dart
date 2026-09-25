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

import 'bitki_turu.dart';

class Tarla {
  final String id;
  final String ad;
  final List<int> zonNumaralari;
  final String? konum;
  final String? aciklama;
  final String? fotografBase64;
  // GPS KONUMU (opsiyonel, sema v2): serbest metin `konum` alanindan
  // BAGIMSIZ, ikisi BIRLIKTE var olabilir (ornegin "Şanlıurfa, Harran
  // Ovası" + gercek koordinatlar). Ayri tutulmasinin nedeni: konum metni
  // HER ZAMAN operator tarafindan girilir, enlem/boylam ise GPS'ten
  // OKUNUR -- ikisini tek bir alanda birlestirmek, birini degistirirken
  // digerinin YANLISLIKLA silinmesi riskini tasirdi.
  final double? enlem;
  final double? boylam;
  // BITKI TURU (opsiyonel, Faz 4, 2026-09-25): sadece hava durumu tabanli
  // basit sulama onerisi (bkz. models/sulama_onerisi.dart) icin kullanilir
  // -- sensor/teshis mantigina hicbir etkisi yoktur. null = "diger/
  // belirtilmedi" (notr oneri).
  final BitkiTuru? bitkiTuru;

  const Tarla({
    required this.id,
    required this.ad,
    required this.zonNumaralari,
    this.konum,
    this.aciklama,
    this.fotografBase64,
    this.enlem,
    this.boylam,
    this.bitkiTuru,
  });

  bool get gpsKonumuVarMi => enlem != null && boylam != null;

  Tarla kopyalaVeGuncelle({
    String? ad,
    List<int>? zonNumaralari,
    String? konum,
    String? aciklama,
    String? fotografBase64,
    bool fotografiKaldir = false,
    double? enlem,
    double? boylam,
    BitkiTuru? bitkiTuru,
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
      enlem: enlem ?? this.enlem,
      boylam: boylam ?? this.boylam,
      bitkiTuru: bitkiTuru ?? this.bitkiTuru,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ad': ad,
    'zonNumaralari': zonNumaralari,
    'konum': konum,
    'aciklama': aciklama,
    'fotografBase64': fotografBase64,
    'enlem': enlem,
    'boylam': boylam,
    'bitkiTuru': bitkiTuru == null ? null : bitkiTuruKoduGetir(bitkiTuru!),
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
    enlem: (json['enlem'] as num?)?.toDouble(),
    boylam: (json['boylam'] as num?)?.toDouble(),
    bitkiTuru: json['bitkiTuru'] == null
        ? null
        : bitkiTuruAyristir(json['bitkiTuru'] as String?),
  );

  /// Uygulama ilk acildiginda (kayitli tarla yokken) gosterilecek varsayilan
  /// ciftlik. TASARIM KARARI (2026-09-04 -- "SDI Tıkanma Yonetim Merkezi"
  /// yenilemesi): onceki surum bilerek 3 tarla/6 zonla basliyordu (coklu
  /// tarla destegini gostermek icin); yeni brief ise demo/varsayilan
  /// durumun FIZIKSEL PROTOTIPLE (brief SS3'teki "3+1 bolmeli seffaf akrilik
  /// test duzenegi" = 4 bolme/zon) BIREBIR eslesmesini istiyor -- juri
  /// demoda gercek cihazla yan yana bakacagi icin bu tutarlilik onemli.
  /// Coklu ciftlik EKLEME yetenegi (tarlaEkle) koddan kaldirilmadi, sadece
  /// varsayilan/demo verisi artik tek ciftlik. Konum/aciklama alanlari,
  /// profil kartinin/asistanin ilk acilista bile "gercek bir ciftlik"
  /// hissi vermesi icin doldurulur.
  static List<Tarla> varsayilanListe() => const [
    Tarla(
      id: 'tarla-1',
      ad: 'Ana Çiftlik',
      zonNumaralari: [1, 2, 3, 4],
      konum: 'Şanlıurfa, Harran Ovası',
      aciklama:
          'Pamuk ekili, toprak altı damla sulama ile 4 parsel (prototip test düzeneğiyle birebir eşleşir).',
    ),
  ];
}
