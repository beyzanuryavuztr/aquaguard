/// AquaGuard - Kural Tabanli Karar Motoru (Dart Karsiligi)
/// ============================================================
///
/// Amac:
///   python/aquaguard_karar_motoru.py ve firmware/decision_engine.h
///   dosyalarindaki Katman 1 (kural tabanli esik + Gauss olabilirlik)
///   mantiginin UCUNCU birebir uygulamasi. Uygulama ici Simulasyon Modu
///   (bkz. simulasyon_servisi.dart), gercekci gorunumlu tikanma turu ve
///   guven skoru uretebilmek icin bu motoru kullanir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:math' as math;

import '../config/sensor_imzalari.dart';
import '../models/sensor_okuma.dart';

class KararSonucu {
  final TeshisDurumu durum;
  final TikanmaTuru tur;
  final double guven;

  const KararSonucu({required this.durum, required this.tur, required this.guven});
}

class KararMotoru {
  KararMotoru._();

  static const List<String> _tipSiniflari = ['kimyasal', 'biyolojik', 'fiziksel'];

  static double _logGaussYogunlugu(double x, double ortalama, double std) {
    final z = (x - ortalama) / std;
    return -0.5 * z * z - math.log(std * math.sqrt(2 * math.pi));
  }

  /// ornek haritasi 'ph','ec','orp','turbidite','debi','delta_basinc'
  /// anahtarlarini icermelidir (bkz. sensorSirasi).
  static KararSonucu teshisEt(Map<String, double> ornek) {
    final debiDusus = (referansDebi - ornek['debi']!) >= debiDususEsigi;
    final basincArtis = ornek['delta_basinc']! >= basincArtisEsigi;
    final turbiditeYuksek = ornek['turbidite']! >= turbiditeEsigi;
    final tikanmaVar = debiDusus || basincArtis || turbiditeYuksek;

    if (!tikanmaVar) {
      return const KararSonucu(durum: TeshisDurumu.normal, tur: TikanmaTuru.yok, guven: 100.0);
    }

    final logSkorlar = <String, double>{};
    for (final tur in _tipSiniflari) {
      final imza = sensorImzalari[tur]!;
      var toplam = 0.0;
      for (final sensor in ['ph', 'ec', 'orp']) {
        final i = imza[sensor]!;
        toplam += _logGaussYogunlugu(ornek[sensor]!, i.ortalama, i.std);
      }
      logSkorlar[tur] = toplam;
    }

    final enBuyukLogSkor = logSkorlar.values.reduce(math.max);
    final ustel = <String, double>{};
    var toplamUstel = 0.0;
    for (final e in logSkorlar.entries) {
      final v = math.exp(e.value - enBuyukLogSkor);
      ustel[e.key] = v;
      toplamUstel += v;
    }

    var enIyiTur = _tipSiniflari.first;
    var enYuksekGuven = 0.0;
    for (final e in ustel.entries) {
      final guven = 100.0 * e.value / toplamUstel;
      if (guven > enYuksekGuven) {
        enYuksekGuven = guven;
        enIyiTur = e.key;
      }
    }

    final tur = turAyristir(enIyiTur);
    final durum = enYuksekGuven >= guvenEsigi ? TeshisDurumu.tespitEdildi : TeshisDurumu.belirsiz;

    return KararSonucu(durum: durum, tur: tur, guven: enYuksekGuven);
  }
}
