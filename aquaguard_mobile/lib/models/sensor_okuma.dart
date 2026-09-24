/// AquaGuard - Sensor Okuma Veri Modeli
/// =======================================
///
/// Amac:
///   Deneyap Kart'tan (veya gelistirme asamasinda mock yayincidan) MQTT
///   uzerinden gelen JSON mesajini Dart nesnesine cevirir.
///
///   BU SINIFTAKI ALANLAR, firmware/mqtt_handler.h dosyasinin basinda
///   tanimlanan JSON semasiyla VE python/aquaguard_mock_yayinci.py
///   dosyasindaki _mesaj_olustur() fonksiyonuyla BIREBIR AYNI OLMALIDIR.
///   Sema degisirse HER UC dosya birlikte guncellenmelidir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

/// Tikanma teshis durumu (Katman 1'in ciktisi)
enum TeshisDurumu { normal, belirsiz, tespitEdildi, bilinmiyor }

/// Tikanma turu
enum TikanmaTuru { yok, kimyasal, biyolojik, fiziksel }

/// Aktif tedavi turu.
/// besinSivi/besinToz (Faz 3, 2026-09-25): tikanma teshisinden BAGIMSIZ,
/// operatorun kendi karariyla (orn. besin takviyesi) manuel baslattigi
/// dozlama -- AYNI guvenlik kilidine (mutex) tabidir, asit/klor/yikama
/// ile ASLA ayni anda calismaz. bkz. firmware/treatment.h TedaviTuru.
enum TedaviTuru {
  yok,
  asitDozlama,
  klorEnjeksiyon,
  yuksekBasincliYikama,
  besinSivi,
  besinToz,
}

TeshisDurumu durumAyristir(String? deger) {
  switch (deger) {
    case 'normal':
      return TeshisDurumu.normal;
    case 'belirsiz':
      return TeshisDurumu.belirsiz;
    case 'tespit_edildi':
      return TeshisDurumu.tespitEdildi;
    default:
      return TeshisDurumu.bilinmiyor;
  }
}

TikanmaTuru turAyristir(String? deger) {
  switch (deger) {
    case 'kimyasal':
      return TikanmaTuru.kimyasal;
    case 'biyolojik':
      return TikanmaTuru.biyolojik;
    case 'fiziksel':
      return TikanmaTuru.fiziksel;
    default:
      return TikanmaTuru.yok;
  }
}

TedaviTuru tedaviAyristir(String? deger) {
  switch (deger) {
    case 'asit_dozlama':
      return TedaviTuru.asitDozlama;
    case 'klor_enjeksiyon':
      return TedaviTuru.klorEnjeksiyon;
    case 'yuksek_basincli_yikama':
      return TedaviTuru.yuksekBasincliYikama;
    case 'besin_sivi':
      return TedaviTuru.besinSivi;
    case 'besin_toz':
      return TedaviTuru.besinToz;
    default:
      return TedaviTuru.yok;
  }
}

/// tedaviAyristir()'in TERSI -- MQTT'ye komut GONDERIRKEN kullanilir
/// (bkz. UygulamaDurumu.manuelTedaviBaslat). ACIMASIZ DENETIM DUZELTMESI
/// (2026-09-14): daha once dogrudan `tedavi.name` (Dart'in varsayilan
/// camelCase kimligi, orn. "asitDozlama") MQTT komutuna yaziliyordu --
/// firmware/mqtt_handler.h VE python/aquaguard_mock_yayinci.py ise snake_case
/// bekler ("asit_dozlama"). Sonuc: gercek donanim/MQTT modunda operatorun
/// "manuel tedavi baslat" eylemi cihaz tarafinda SESSIZCE reddediliyordu
/// (firmware log'unda "Geçersiz/eksik tedavi_turu" hatasi), ama Dart tarafi
/// yine de basarili=true donduruyordu -- operator tedavinin basladigini
/// sanirdi. Bu SADECE gercek MQTT modunda gorulur, Demo Modu bu komut
/// yolunu hic kullanmadigi icin (TikanmaTuru uzerinden dogrudan calisir)
/// bu hata hicbir demo/test senaryosunda ortaya cikmamisti.
String tedaviKoduGetir(TedaviTuru tedavi) {
  switch (tedavi) {
    case TedaviTuru.yok:
      return 'yok';
    case TedaviTuru.asitDozlama:
      return 'asit_dozlama';
    case TedaviTuru.klorEnjeksiyon:
      return 'klor_enjeksiyon';
    case TedaviTuru.yuksekBasincliYikama:
      return 'yuksek_basincli_yikama';
    case TedaviTuru.besinSivi:
      return 'besin_sivi';
    case TedaviTuru.besinToz:
      return 'besin_toz';
  }
}

String durumEtiketi(TeshisDurumu durum) {
  switch (durum) {
    case TeshisDurumu.normal:
      return 'Normal';
    case TeshisDurumu.belirsiz:
      return 'Belirsiz - Operatör Kontrolü Gerekli';
    case TeshisDurumu.tespitEdildi:
      return 'Tıkanma Tespit Edildi';
    case TeshisDurumu.bilinmiyor:
      return 'Bilinmiyor';
  }
}

String turEtiketi(TikanmaTuru tur) {
  switch (tur) {
    case TikanmaTuru.yok:
      return 'Yok';
    case TikanmaTuru.kimyasal:
      return 'Kimyasal';
    case TikanmaTuru.biyolojik:
      return 'Biyolojik';
    case TikanmaTuru.fiziksel:
      return 'Fiziksel';
  }
}

/// Bir tedavi turunun hangi tikanma turune karsi kullanildigini doner --
/// manuel mudahale ekraninda operator bir TEDAVI secer (ekipmanla eslesir),
/// ic mantik (simulasyon/demo) bunu ilgili tikanma turune cevirmelidir.
/// simulasyon_servisi.dart'taki _tedaviEslemesi() ile TERSI yonde ayni eslemedir.
/// besinSivi/besinToz HICBIR tikanma turune karsilik gelmez (TikanmaTuru.yok
/// doner) -- bunlar `manuelTedaviBaslat` DEGIL, ayri `besinDozlamaBaslat`
/// yolundan gecer (bkz. providers/cihaz_iletisim_provider.dart).
TikanmaTuru tedaviyeKarsilikGelenTur(TedaviTuru tedavi) {
  switch (tedavi) {
    case TedaviTuru.asitDozlama:
      return TikanmaTuru.kimyasal;
    case TedaviTuru.klorEnjeksiyon:
      return TikanmaTuru.biyolojik;
    case TedaviTuru.yuksekBasincliYikama:
      return TikanmaTuru.fiziksel;
    case TedaviTuru.yok:
    case TedaviTuru.besinSivi:
    case TedaviTuru.besinToz:
      return TikanmaTuru.yok;
  }
}

String tedaviEtiketi(TedaviTuru tedavi) {
  switch (tedavi) {
    case TedaviTuru.yok:
      return 'Yok';
    case TedaviTuru.asitDozlama:
      return 'Asit Dozlama';
    case TedaviTuru.klorEnjeksiyon:
      return 'Klor Enjeksiyonu';
    case TedaviTuru.yuksekBasincliYikama:
      return 'Yüksek Basınçlı Yıkama';
    case TedaviTuru.besinSivi:
      return 'Besin Takviyesi (Sıvı)';
    case TedaviTuru.besinToz:
      return 'Besin Takviyesi (Toz)';
  }
}

/// Tek bir MQTT mesajinin karsiligi olan degismez (immutable) veri modeli.
class SensorOkuma {
  final DateTime zaman;
  final int zone;
  final double ph;
  final double ec;
  final double orp;
  final double turbidite;
  final double debi;
  final double deltaBasinc;
  final TeshisDurumu durum;
  final TikanmaTuru tikanmaTuru;
  final double guven;

  // Karar motorunun UC tikanma turunu de ne kadar olasi gordugu (aciklanabilirlik).
  // Tikanma yoksa (durum=normal) ucu de 0.0'dir.
  final double guvenKimyasal;
  final double guvenBiyolojik;
  final double guvenFiziksel;

  final TedaviTuru tedaviAktif;
  final bool durulamaAktif;

  // HAZNE SEVIYESI (opsiyonel, sema v2): gercek donanimda henuz bir hazne
  // seviye sensoru YOK -- bu alanlar `null` gelirse UI hazne kartini HIC
  // GOSTERMEZ (bkz. models/hazne_durumu.dart dosya basi notu). Sadece
  // Python mock yayinci (demo/gelistirme amacli) bu alanlari doldurur.
  final double? hazneAsitSeviyeYuzde;
  final double? hazneKlorSeviyeYuzde;

  // ANA VANA DURUMU (sema v2, 2026-09-19): cihazin GERCEK vana durumu. `null`
  // = alan gelmedi (eski firmware, demo simulasyonu) -- uygulama o zaman
  // kendi tahminini korur.
  final bool? anaVanaAcik;

  // SURELI SULAMA GERI SAYIMI (sema v3, 2026-09-24): "sulama_baslat"
  // komutu bir sure_dakika ile baslatildiysa, vananin kendiliginden
  // kapanmasina kalan saniye. Alan hic gelmezse (eski firmware) null;
  // gelip 0 ise sureli bir sulama YOK demektir (suresiz acik/kapali).
  final int? sulamaKalanSaniye;

  const SensorOkuma({
    required this.zaman,
    required this.zone,
    required this.ph,
    required this.ec,
    required this.orp,
    required this.turbidite,
    required this.debi,
    required this.deltaBasinc,
    required this.durum,
    required this.tikanmaTuru,
    required this.guven,
    this.guvenKimyasal = 0.0,
    this.guvenBiyolojik = 0.0,
    this.guvenFiziksel = 0.0,
    required this.tedaviAktif,
    required this.durulamaAktif,
    this.hazneAsitSeviyeYuzde,
    this.hazneKlorSeviyeYuzde,
    this.anaVanaAcik,
    this.sulamaKalanSaniye,
  });

  /// Ucunun turu icin guven yuzdesini isimle sorgulamak icin yardimci (grafik cizimlerinde kullanislidir).
  Map<TikanmaTuru, double> get tumTurGuvenleri => {
    TikanmaTuru.kimyasal: guvenKimyasal,
    TikanmaTuru.biyolojik: guvenBiyolojik,
    TikanmaTuru.fiziksel: guvenFiziksel,
  };

  /// MQTT'den gelen JSON haritasindan (Map) nesne olusturur.
  /// Sayisal alanlar hem int hem double olarak gelebilir, bu yuzden
  /// `num` uzerinden guvenli donusum yapilir.
  factory SensorOkuma.fromJson(Map<String, dynamic> json) {
    double sayi(dynamic deger) => (deger as num?)?.toDouble() ?? 0.0;
    double? sayiNullable(dynamic deger) => (deger as num?)?.toDouble();

    return SensorOkuma(
      zaman: _zamanAyristir(json['zaman'] as String?),
      zone: (json['zone'] as num?)?.toInt() ?? 0,
      ph: sayi(json['ph']),
      ec: sayi(json['ec']),
      orp: sayi(json['orp']),
      turbidite: sayi(json['turbidite']),
      debi: sayi(json['debi']),
      deltaBasinc: sayi(json['delta_basinc']),
      durum: durumAyristir(json['durum'] as String?),
      tikanmaTuru: turAyristir(json['tikanma_turu'] as String?),
      guven: sayi(json['guven']),
      guvenKimyasal: sayi(json['guven_kimyasal']),
      guvenBiyolojik: sayi(json['guven_biyolojik']),
      guvenFiziksel: sayi(json['guven_fiziksel']),
      tedaviAktif: tedaviAyristir(json['tedavi_aktif'] as String?),
      durulamaAktif: json['durulama_aktif'] as bool? ?? false,
      hazneAsitSeviyeYuzde: sayiNullable(json['hazne_asit_seviye_yuzde']),
      hazneKlorSeviyeYuzde: sayiNullable(json['hazne_klor_seviye_yuzde']),
      anaVanaAcik: json['ana_vana_acik'] is bool
          ? json['ana_vana_acik'] as bool
          : null,
      sulamaKalanSaniye: (json['sulama_kalan_saniye'] as num?)?.toInt(),
    );
  }

  /// Yerel depolamaya (SharedPreferences) kaydetmek icin JSON'a cevirir.
  Map<String, dynamic> toJson() => {
    'zaman': zaman.toIso8601String(),
    'zone': zone,
    'ph': ph,
    'ec': ec,
    'orp': orp,
    'turbidite': turbidite,
    'debi': debi,
    'delta_basinc': deltaBasinc,
    'durum': durum.name,
    'tikanma_turu': tikanmaTuru.name,
    'guven': guven,
    'guven_kimyasal': guvenKimyasal,
    'guven_biyolojik': guvenBiyolojik,
    'guven_fiziksel': guvenFiziksel,
    'tedavi_aktif': tedaviAktif.name,
    'durulama_aktif': durulamaAktif,
    'hazne_asit_seviye_yuzde': hazneAsitSeviyeYuzde,
    'hazne_klor_seviye_yuzde': hazneKlorSeviyeYuzde,
    'ana_vana_acik': anaVanaAcik,
    'sulama_kalan_saniye': sulamaKalanSaniye,
  };

  /// toJson() ile kaydedilmis (dolayisiyla Turkce string kodlari degil,
  /// enum.name kodlarini tasiyan) bir haritadan geri yukler.
  factory SensorOkuma.fromCacheJson(Map<String, dynamic> json) {
    double sayi(dynamic deger) => (deger as num?)?.toDouble() ?? 0.0;
    double? sayiNullable(dynamic deger) => (deger as num?)?.toDouble();

    return SensorOkuma(
      zaman:
          DateTime.tryParse(json['zaman'] as String? ?? '') ?? DateTime.now(),
      zone: (json['zone'] as num?)?.toInt() ?? 0,
      ph: sayi(json['ph']),
      ec: sayi(json['ec']),
      orp: sayi(json['orp']),
      turbidite: sayi(json['turbidite']),
      debi: sayi(json['debi']),
      deltaBasinc: sayi(json['delta_basinc']),
      durum: TeshisDurumu.values.firstWhere(
        (e) => e.name == json['durum'],
        orElse: () => TeshisDurumu.bilinmiyor,
      ),
      tikanmaTuru: TikanmaTuru.values.firstWhere(
        (e) => e.name == json['tikanma_turu'],
        orElse: () => TikanmaTuru.yok,
      ),
      guven: sayi(json['guven']),
      guvenKimyasal: sayi(json['guven_kimyasal']),
      guvenBiyolojik: sayi(json['guven_biyolojik']),
      guvenFiziksel: sayi(json['guven_fiziksel']),
      tedaviAktif: TedaviTuru.values.firstWhere(
        (e) => e.name == json['tedavi_aktif'],
        orElse: () => TedaviTuru.yok,
      ),
      durulamaAktif: json['durulama_aktif'] as bool? ?? false,
      hazneAsitSeviyeYuzde: sayiNullable(json['hazne_asit_seviye_yuzde']),
      hazneKlorSeviyeYuzde: sayiNullable(json['hazne_klor_seviye_yuzde']),
      anaVanaAcik: json['ana_vana_acik'] is bool
          ? json['ana_vana_acik'] as bool
          : null,
      sulamaKalanSaniye: (json['sulama_kalan_saniye'] as num?)?.toInt(),
    );
  }

  static DateTime _zamanAyristir(String? deger) {
    if (deger == null) return DateTime.now();
    // Firmware/mock "YYYY-MM-DD HH:MM:SS" formatinda gonderir (ISO degil,
    // araya 'T' eklenmesi gerekir).
    final iso = deger.contains('T') ? deger : deger.replaceFirst(' ', 'T');
    return DateTime.tryParse(iso) ?? DateTime.now();
  }
}
