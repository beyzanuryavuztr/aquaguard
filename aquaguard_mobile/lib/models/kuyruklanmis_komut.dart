/// AquaGuard - Kuyruklanmis Komut (Offline Mod)
/// ==================================================
///
/// Amac:
///   Cihazin (telefonun) kendi ağ bağlantısı YOKKEN operatorun verdigi
///   "gonder ve unut" turu komutlar (tedavi_durdur/normale_dondur/
///   sulama_durdur/sulama_baslat -- manuelTedaviBaslat'in ACK/NACK
///   bekleyen ayri yolundan FARKLI, bkz. models/bekleyen_komut.dart)
///   sessizce KAYBOLMAK yerine burada saklanir, baglanti geri gelince
///   sirayla gonderilir.
///
///   GUVENLIK: 5 dakikadan eski bir komut artik gecerli olmayabilir (o
///   sirada saha durumu degismis olabilir) -- SESSIZCE silinir, otomatik
///   gonderilmez (bkz. AyarlarSabitleri.kuyrukKomutGecerlilikSuresi).
///
/// Tarih:  2026-09-16
library;

class KuyruklanmisKomut {
  final int zone;
  final Map<String, dynamic> komut;
  final DateTime olusturmaZamani;

  const KuyruklanmisKomut({
    required this.zone,
    required this.komut,
    required this.olusturmaZamani,
  });

  bool suresiGecmisMi(Duration gecerlilikSuresi, [DateTime? simdi]) =>
      (simdi ?? DateTime.now()).difference(olusturmaZamani) >
      gecerlilikSuresi;

  Map<String, dynamic> toJson() => {
    'zone': zone,
    'komut': komut,
    'olusturmaZamani': olusturmaZamani.toIso8601String(),
  };

  factory KuyruklanmisKomut.fromJson(Map<String, dynamic> json) =>
      KuyruklanmisKomut(
        zone: (json['zone'] as num).toInt(),
        komut: Map<String, dynamic>.from(json['komut'] as Map),
        olusturmaZamani: DateTime.parse(json['olusturmaZamani'] as String),
      );
}
