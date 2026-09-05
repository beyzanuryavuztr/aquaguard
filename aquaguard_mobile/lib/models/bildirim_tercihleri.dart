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

  const BildirimTercihleri({
    this.tespit = true,
    this.tedaviBaslangic = true,
    this.tedaviTamamlanma = true,
    this.dusukPil = true,
  });

  BildirimTercihleri kopyalaVeGuncelle({
    bool? tespit,
    bool? tedaviBaslangic,
    bool? tedaviTamamlanma,
    bool? dusukPil,
  }) {
    return BildirimTercihleri(
      tespit: tespit ?? this.tespit,
      tedaviBaslangic: tedaviBaslangic ?? this.tedaviBaslangic,
      tedaviTamamlanma: tedaviTamamlanma ?? this.tedaviTamamlanma,
      dusukPil: dusukPil ?? this.dusukPil,
    );
  }

  Map<String, dynamic> toJson() => {
    'tespit': tespit,
    'tedaviBaslangic': tedaviBaslangic,
    'tedaviTamamlanma': tedaviTamamlanma,
    'dusukPil': dusukPil,
  };

  factory BildirimTercihleri.fromJson(Map<String, dynamic> json) =>
      BildirimTercihleri(
        tespit: json['tespit'] as bool? ?? true,
        tedaviBaslangic: json['tedaviBaslangic'] as bool? ?? true,
        tedaviTamamlanma: json['tedaviTamamlanma'] as bool? ?? true,
        dusukPil: json['dusukPil'] as bool? ?? true,
      );
}
