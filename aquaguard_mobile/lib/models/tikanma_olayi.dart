/// AquaGuard - Tikanma Olayi (Tedavi Geçmişi log satırı)
/// ===========================================================
///
/// Amac:
///   Bir zonun geçmişinde YENİ bir tıkanma tespitinin gerçekleştiği anları
///   (durum'un TESPİT_EDİLDİ'ye İLK GEÇTİĞİ noktalar) yapısal olarak
///   temsil eder -- Tedavi Geçmişi ekranındaki filtrelenebilir olay
///   günlüğünün satırlarıdır.
///
///   `AktiviteKaydi`'nin (models/aktivite_kaydi.dart) aksine `TikanmaTuru`
///   alanını DOĞRUDAN taşır (biçimlendirilmiş bir mesaj dizesi değil),
///   böylece tür filtresi (Kimyasal/Biyolojik/Fiziksel) dize eşlemesine
///   değil gerçek enum değerine dayanarak GÜVENİLİR şekilde uygulanabilir.
///
/// Tarih:  2026-09-05
library;

import 'sensor_okuma.dart';

class TikanmaOlayi {
  final DateTime zaman;
  final int zone;
  final TikanmaTuru tur;
  final double guven;

  const TikanmaOlayi({
    required this.zaman,
    required this.zone,
    required this.tur,
    required this.guven,
  });
}

/// [kronolojik]: TEK bir zonun eskiden yeniye sıralı geçmişi. Durum'un
/// YENİ olarak tespit_edildi'ye geçtiği (bir önceki okuma tespit
/// DEĞİLKEN) her anı bir [TikanmaOlayi] olarak döner -- devam eden aynı
/// olayın her tekrarlanan okuması değil, sadece BAŞLANGIÇ anı.
Iterable<TikanmaOlayi> tikanmaOlaylariniBul(
  List<SensorOkuma> kronolojik,
) sync* {
  for (var i = 0; i < kronolojik.length; i++) {
    final simdiki = kronolojik[i];
    if (simdiki.durum != TeshisDurumu.tespitEdildi) continue;
    final oncekiTespitMi =
        i > 0 && kronolojik[i - 1].durum == TeshisDurumu.tespitEdildi;
    if (oncekiTespitMi) continue;

    yield TikanmaOlayi(
      zaman: simdiki.zaman,
      zone: simdiki.zone,
      tur: simdiki.tikanmaTuru,
      guven: simdiki.guven,
    );
  }
}
