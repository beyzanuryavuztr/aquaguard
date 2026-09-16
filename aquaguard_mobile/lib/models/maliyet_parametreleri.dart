/// AquaGuard - Maliyet Parametreleri (Birim Fiyatlar)
/// ========================================================
///
/// Amac:
///   Su/kimyasal maliyet hesabinin dayandigi birim fiyatlar. Bunlar
///   BOLGEYE/TEDARIKCIYE gore DEGISEN piyasa degerleridir -- proje
///   genelindeki diger sabitlerin aksine (orn. karar esikleri, literatur
///   kaynakli) burada TEK BIR "dogru" deger YOKTUR, bu yuzden Ayarlar'da
///   operator tarafindan DUZENLENEBILIR varsayilanlar olarak sunulur
///   (2026 Turkiye tarimsal fiyatlarina kabaca dayanan, ama KESIN/dogrulanmis
///   OLMAYAN baslangic degerleri).
///
///   Dozlama oranlari (L/dk) da benzer sekilde TAHMINIDIR -- gercek
///   donanimda henuz bir dozlama debisi olcumu YOK (bkz. models/
///   hazne_durumu.dart benzer durustluk notu), bu yuzden sabit tedavi
///   suresiyle (AyarlarSabitleri.tedaviSuresiSaniye) CARPILARAK kaba bir
///   tahmin uretilir.
///
/// Tarih:  2026-09-16
library;

class MaliyetParametreleri {
  final double suBirimFiyatiTLm3;
  final double asitBirimFiyatiTLLitre;
  final double klorBirimFiyatiTLLitre;
  final double asitDozlamaOraniLDk;
  final double klorDozlamaOraniLDk;

  const MaliyetParametreleri({
    this.suBirimFiyatiTLm3 = 15.0,
    this.asitBirimFiyatiTLLitre = 8.0,
    this.klorBirimFiyatiTLLitre = 6.0,
    this.asitDozlamaOraniLDk = 0.5,
    this.klorDozlamaOraniLDk = 0.5,
  });

  MaliyetParametreleri kopyalaVeGuncelle({
    double? suBirimFiyatiTLm3,
    double? asitBirimFiyatiTLLitre,
    double? klorBirimFiyatiTLLitre,
    double? asitDozlamaOraniLDk,
    double? klorDozlamaOraniLDk,
  }) {
    return MaliyetParametreleri(
      suBirimFiyatiTLm3: suBirimFiyatiTLm3 ?? this.suBirimFiyatiTLm3,
      asitBirimFiyatiTLLitre:
          asitBirimFiyatiTLLitre ?? this.asitBirimFiyatiTLLitre,
      klorBirimFiyatiTLLitre:
          klorBirimFiyatiTLLitre ?? this.klorBirimFiyatiTLLitre,
      asitDozlamaOraniLDk: asitDozlamaOraniLDk ?? this.asitDozlamaOraniLDk,
      klorDozlamaOraniLDk: klorDozlamaOraniLDk ?? this.klorDozlamaOraniLDk,
    );
  }

  Map<String, dynamic> toJson() => {
    'suBirimFiyatiTLm3': suBirimFiyatiTLm3,
    'asitBirimFiyatiTLLitre': asitBirimFiyatiTLLitre,
    'klorBirimFiyatiTLLitre': klorBirimFiyatiTLLitre,
    'asitDozlamaOraniLDk': asitDozlamaOraniLDk,
    'klorDozlamaOraniLDk': klorDozlamaOraniLDk,
  };

  factory MaliyetParametreleri.fromJson(Map<String, dynamic> json) {
    const varsayilan = MaliyetParametreleri();
    double al(String anahtar, double varsayilanDeger) =>
        (json[anahtar] as num?)?.toDouble() ?? varsayilanDeger;
    return MaliyetParametreleri(
      suBirimFiyatiTLm3: al(
        'suBirimFiyatiTLm3',
        varsayilan.suBirimFiyatiTLm3,
      ),
      asitBirimFiyatiTLLitre: al(
        'asitBirimFiyatiTLLitre',
        varsayilan.asitBirimFiyatiTLLitre,
      ),
      klorBirimFiyatiTLLitre: al(
        'klorBirimFiyatiTLLitre',
        varsayilan.klorBirimFiyatiTLLitre,
      ),
      asitDozlamaOraniLDk: al(
        'asitDozlamaOraniLDk',
        varsayilan.asitDozlamaOraniLDk,
      ),
      klorDozlamaOraniLDk: al(
        'klorDozlamaOraniLDk',
        varsayilan.klorDozlamaOraniLDk,
      ),
    );
  }
}
