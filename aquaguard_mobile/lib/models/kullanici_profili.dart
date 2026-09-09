/// AquaGuard - Kullanici Profili
/// =================================
///
/// Amac:
///   Operatorun kendi girdigi, TAMAMEN yerel kisisel/isletme bilgisi --
///   uygulamada gercek bir hesap/backend YOK (bkz. giris_ekrani.dart'in
///   ayni durustluk notu: bu bir kimlik dogrulama degil, sadece marka+mod
///   secim ekrani). Bu profil de aynen oyle: sunucuya gonderilmez, sadece
///   cihazda saklanir ve PDF raporun basligini kisisellestirmek gibi yerel
///   bir amac icin kullanilir.
///
/// Tarih:  2026-09-09
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

class KullaniciProfili {
  final String isim;
  final String isletmeAdi;
  final String telefon;

  const KullaniciProfili({
    this.isim = '',
    this.isletmeAdi = '',
    this.telefon = '',
  });

  KullaniciProfili kopyalaVeGuncelle({
    String? isim,
    String? isletmeAdi,
    String? telefon,
  }) {
    return KullaniciProfili(
      isim: isim ?? this.isim,
      isletmeAdi: isletmeAdi ?? this.isletmeAdi,
      telefon: telefon ?? this.telefon,
    );
  }

  Map<String, dynamic> toJson() => {
    'isim': isim,
    'isletmeAdi': isletmeAdi,
    'telefon': telefon,
  };

  factory KullaniciProfili.fromJson(Map<String, dynamic> json) =>
      KullaniciProfili(
        isim: json['isim'] as String? ?? '',
        isletmeAdi: json['isletmeAdi'] as String? ?? '',
        telefon: json['telefon'] as String? ?? '',
      );
}
