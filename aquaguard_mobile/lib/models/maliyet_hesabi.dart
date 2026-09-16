/// AquaGuard - Maliyet Hesabi (Saf Fonksiyonlar)
/// ===================================================
///
/// Amac:
///   Su ve kimyasal tuketim maliyetini hesaplayan SAF fonksiyonlar.
///   Su maliyeti, MEVCUT `su_tuketimi.dart`'taki (`suTuketimiHesaplaLitre`)
///   gercek debi verisinden turetilen litre miktarinin UZERINE insa
///   edilir -- burada TEKRAR hesaplanmaz, sadece birim fiyatla carpilir.
///
///   Kimyasal maliyeti ISE tahminidir: gercek donanimda bir dozlama debisi
///   OLCUMU yok (bkz. models/maliyet_parametreleri.dart durustluk notu),
///   bu yuzden sabit tedavi suresi (AyarlarSabitleri.tedaviSuresiSaniye --
///   TedaviIlerlemesi'nin de kullandigi AYNI tek kaynak) ile tahmini bir
///   dozlama oraninin CARPIMI kullanilir.
///
/// Tarih:  2026-09-16
library;

import '../config/ayarlar_sabitleri.dart';
import 'maliyet_parametreleri.dart';
import 'sensor_okuma.dart';

double suMaliyetiHesapla({
  required double litre,
  required double birimFiyatTLm3,
}) => (litre / 1000.0) * birimFiyatTLm3;

/// Bir [tur] (tespit edilen tikanma turu) icin, o turu KARSILAYAN otonom
/// tedavinin TAHMINI maliyeti. Fiziksel (yuksek basincli yikama) icin 0.0
/// doner -- o tedavinin maliyeti zaten suMaliyetiHesapla() araciligiyla
/// GERCEK debi verisinden kapsanir, burada AYRICA sayilmaz (cift sayim
/// olmasin diye).
double tedaviMaliyetiTahminiHesapla({
  required TikanmaTuru tur,
  required MaliyetParametreleri parametreler,
}) {
  switch (tur) {
    case TikanmaTuru.kimyasal:
      final sureDk =
          (AyarlarSabitleri.tedaviSuresiSaniye[TedaviTuru.asitDozlama] ?? 0) /
          60.0;
      return sureDk *
          parametreler.asitDozlamaOraniLDk *
          parametreler.asitBirimFiyatiTLLitre;
    case TikanmaTuru.biyolojik:
      final sureDk =
          (AyarlarSabitleri.tedaviSuresiSaniye[TedaviTuru.klorEnjeksiyon] ??
              0) /
          60.0;
      return sureDk *
          parametreler.klorDozlamaOraniLDk *
          parametreler.klorBirimFiyatiTLLitre;
    case TikanmaTuru.fiziksel:
    case TikanmaTuru.yok:
      return 0.0;
  }
}
