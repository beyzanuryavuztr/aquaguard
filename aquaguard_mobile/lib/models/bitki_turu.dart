/// AquaGuard - Bitki Turu (Sulama Onerisi icin, Faz 4)
/// =========================================================
///
/// Amac:
///   Hava durumu tabanli basit sulama onerisinin (bkz. models/sulama_onerisi.dart)
///   girdilerinden biri. BILEREK cok kaba/genel bir siniflandirma -- gercek
///   bir agronomik su ihtiyaci modeli (evapotranspirasyon/Penman-Monteith
///   vb.) DEGILDIR, sadece "bu bitki tipik olarak digerinden biraz daha
///   fazla/az suya ihtiyac duyar" seklinde KABA bir yon verir. Operator
///   bunu Tarla profilinde secer (opsiyonel, secmezse 'diger' -- notr).
///
/// Tarih:  2026-09-25
library;

enum BitkiTuru { sebze, meyveAgaci, tarlaBitkisi, diger }

String bitkiTuruEtiketi(BitkiTuru tur) {
  switch (tur) {
    case BitkiTuru.sebze:
      return 'Sebze';
    case BitkiTuru.meyveAgaci:
      return 'Meyve Ağacı';
    case BitkiTuru.tarlaBitkisi:
      return 'Tarla Bitkisi (tahıl/pamuk vb.)';
    case BitkiTuru.diger:
      return 'Diğer / Belirtilmedi';
  }
}

/// Su ihtiyacini "az/orta/fazla" seklinde KABA bir egilime cevirir --
/// sulama_onerisi.dart bunu sayisal bir carpan olarak DEGIL, sadece
/// oneri metninin tonu icin kullanir (bkz. o dosyanin durustluk notu).
enum SuIhtiyaciEgilimi { dusuk, orta, yuksek }

SuIhtiyaciEgilimi bitkiSuIhtiyaciEgilimi(BitkiTuru tur) {
  switch (tur) {
    case BitkiTuru.sebze:
      return SuIhtiyaciEgilimi.yuksek;
    case BitkiTuru.meyveAgaci:
      return SuIhtiyaciEgilimi.orta;
    case BitkiTuru.tarlaBitkisi:
      return SuIhtiyaciEgilimi.orta;
    case BitkiTuru.diger:
      return SuIhtiyaciEgilimi.orta;
  }
}

BitkiTuru bitkiTuruAyristir(String? deger) {
  switch (deger) {
    case 'sebze':
      return BitkiTuru.sebze;
    case 'meyveAgaci':
      return BitkiTuru.meyveAgaci;
    case 'tarlaBitkisi':
      return BitkiTuru.tarlaBitkisi;
    default:
      return BitkiTuru.diger;
  }
}

String bitkiTuruKoduGetir(BitkiTuru tur) => tur.name;
