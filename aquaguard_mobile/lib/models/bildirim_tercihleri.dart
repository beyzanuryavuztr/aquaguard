/// AquaGuard - Bildirim Tercihleri (4 ayrı kategori)
/// ======================================================
///
/// Amac:
///   Önceki tek "bildirimler açık/kapalı" anahtarının yerini, operatörün
///   HER olay kategorisini ayrı ayrı açıp kapatabildiği 4 anahtar alır --
///   örn. tespit bildirimlerini isteyip tedavi tamamlanma bildirimlerini
///   istemeyebilir.
///
/// Tarih:  2026-09-05
library;

class BildirimTercihleri {
  final bool tespit;
  final bool tedaviBaslangic;
  final bool tedaviTamamlanma;
  final bool dusukPil;

  // SESSIZ SAATLER (sema v2, 2026-09-16): gun-ici dakika olarak (0-1439,
  // 0=00:00). Ikisi de null ise sessiz saat KAPALIDIR. Baslangic > bitis
  // olabilir (ornegin 22:00-07:00, gece yarisini gecen bir aralik) --
  // kontrol mantigi bunu isFalse yerine "araligin DISINDA mi" seklinde
  // ele alir (bkz. providers/uygulama_durumu.dart _sessizSaattaMi).
  // KRITIK oncelikli bildirimler sessiz saatte BILE gosterilir (guvenlik
  // onceligi) -- bkz. models/bildirim_onceligi.dart.
  final int? sessizBaslangicDakika;
  final int? sessizBitisDakika;

  const BildirimTercihleri({
    this.tespit = true,
    this.tedaviBaslangic = true,
    this.tedaviTamamlanma = true,
    this.dusukPil = true,
    this.sessizBaslangicDakika,
    this.sessizBitisDakika,
  });

  bool get sessizSaatAktif =>
      sessizBaslangicDakika != null && sessizBitisDakika != null;

  BildirimTercihleri kopyalaVeGuncelle({
    bool? tespit,
    bool? tedaviBaslangic,
    bool? tedaviTamamlanma,
    bool? dusukPil,
    int? sessizBaslangicDakika,
    int? sessizBitisDakika,
    bool sessizSaatiKaldir = false,
  }) {
    return BildirimTercihleri(
      tespit: tespit ?? this.tespit,
      tedaviBaslangic: tedaviBaslangic ?? this.tedaviBaslangic,
      tedaviTamamlanma: tedaviTamamlanma ?? this.tedaviTamamlanma,
      dusukPil: dusukPil ?? this.dusukPil,
      sessizBaslangicDakika: sessizSaatiKaldir
          ? null
          : (sessizBaslangicDakika ?? this.sessizBaslangicDakika),
      sessizBitisDakika: sessizSaatiKaldir
          ? null
          : (sessizBitisDakika ?? this.sessizBitisDakika),
    );
  }

  Map<String, dynamic> toJson() => {
    'tespit': tespit,
    'tedaviBaslangic': tedaviBaslangic,
    'tedaviTamamlanma': tedaviTamamlanma,
    'dusukPil': dusukPil,
    'sessizBaslangicDakika': sessizBaslangicDakika,
    'sessizBitisDakika': sessizBitisDakika,
  };

  factory BildirimTercihleri.fromJson(Map<String, dynamic> json) =>
      BildirimTercihleri(
        tespit: json['tespit'] as bool? ?? true,
        tedaviBaslangic: json['tedaviBaslangic'] as bool? ?? true,
        tedaviTamamlanma: json['tedaviTamamlanma'] as bool? ?? true,
        dusukPil: json['dusukPil'] as bool? ?? true,
        sessizBaslangicDakika: (json['sessizBaslangicDakika'] as num?)
            ?.toInt(),
        sessizBitisDakika: (json['sessizBitisDakika'] as num?)?.toInt(),
      );
}
