/// AquaGuard - Simulasyon (Demo) Servisi
/// =========================================
///
/// Amac:
///   Henuz gercek Deneyap Kart donanimi baglanmamisken uygulamayi TAM
///   FONKSIYONEL, gercekci ve profesyonel bir demo halinde gostermek icin
///   uygulama icinde (herhangi bir ag/MQTT baglantisi olmadan) sahte ama
///   FIZIKSEL OLARAK ANLAMLI sensor verisi uretir.
///
///   Mantik, python/aquaguard_mock_yayinci.py ile AYNIDIR (normal ->
///   kotulesme -> tedavi -> durulama -> iyilesme dongusu), sadece MQTT
///   yerine dogrudan Dart callback'i ile UygulamaDurumu'na beslenir. Karar
///   hesaplamasi icin karar_motoru.dart (Katman 1'in Dart karsiligi)
///   kullanilir -- boylece demo modundaki veriler, gercek cihazdan
///   gelecek verilerle AYNI KURALLARA gore siniflandirilir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';
import 'dart:math' as math;

import '../config/sensor_imzalari.dart';
import '../models/sensor_okuma.dart';
import 'karar_motoru.dart';

class _SimAdim {
  final Map<String, double> ornek;
  final TedaviTuru tedaviAktif;
  final bool durulamaAktif;

  const _SimAdim(this.ornek, this.tedaviAktif, this.durulamaAktif);
}

TedaviTuru _tedaviEslemesi(String tur) {
  switch (tur) {
    case 'kimyasal':
      return TedaviTuru.asitDozlama;
    case 'biyolojik':
      return TedaviTuru.klorEnjeksiyon;
    case 'fiziksel':
      return TedaviTuru.yuksekBasincliYikama;
    default:
      return TedaviTuru.yok;
  }
}

double _gaussianRastgele(math.Random rng) {
  final u1 = 1.0 - rng.nextDouble();
  final u2 = rng.nextDouble();
  return math.sqrt(-2.0 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

const double _demoGurultuCarpani = 0.5;

double _sensorDegeriHesapla(
  String sensor,
  String kaynakSinif,
  String hedefSinif,
  double ilerleme,
  math.Random rng,
) {
  final kaynak = sensorImzalari[kaynakSinif]![sensor]!;
  final hedef = sensorImzalari[hedefSinif]![sensor]!;
  final ort = kaynak.ortalama + (hedef.ortalama - kaynak.ortalama) * ilerleme;
  final std = kaynak.std + (hedef.std - kaynak.std) * ilerleme;
  return ort + _gaussianRastgele(rng) * std * _demoGurultuCarpani;
}

Map<String, double> _tamOrnekUret(
  String kaynakSinif,
  String hedefSinif,
  double ilerleme,
  math.Random rng,
) {
  return {
    for (final sensor in sensorSirasi)
      sensor: _sensorDegeriHesapla(sensor, kaynakSinif, hedefSinif, ilerleme, rng),
  };
}

/// Sonsuz bir senaryo akisi: normal -> kotulesme -> tedavi -> durulama ->
/// iyilesme, ardindan yeni rastgele bir tikanma turuyle tekrar basa doner.
Iterable<_SimAdim> _senaryoUret(math.Random rng) sync* {
  const turler = ['kimyasal', 'biyolojik', 'fiziksel'];

  while (true) {
    final hedefTur = turler[rng.nextInt(turler.length)];

    for (var i = 0; i < 4; i++) {
      yield _SimAdim(_tamOrnekUret('normal', 'normal', 0.0, rng), TedaviTuru.yok, false);
    }

    const kotulesmeAdim = 6;
    for (var i = 1; i <= kotulesmeAdim; i++) {
      final ilerleme = i / kotulesmeAdim;
      yield _SimAdim(_tamOrnekUret('normal', hedefTur, ilerleme, rng), TedaviTuru.yok, false);
    }

    final tedaviTuru = _tedaviEslemesi(hedefTur);
    const tedaviAdim = 3;
    for (var i = 0; i < tedaviAdim; i++) {
      final ilerleme = (1.0 - 0.15 * i).clamp(0.0, 1.0);
      yield _SimAdim(_tamOrnekUret('normal', hedefTur, ilerleme, rng), tedaviTuru, false);
    }

    const durulamaAdim = 2;
    for (var i = 0; i < durulamaAdim; i++) {
      final ilerleme = (0.5 - 0.25 * i).clamp(0.0, 1.0);
      yield _SimAdim(_tamOrnekUret('normal', hedefTur, ilerleme, rng), TedaviTuru.yok, true);
    }

    const iyilesmeAdim = 4;
    for (var i = 1; i <= iyilesmeAdim; i++) {
      final ilerleme = (0.25 - 0.25 * (i / iyilesmeAdim)).clamp(0.0, 1.0);
      yield _SimAdim(_tamOrnekUret('normal', hedefTur, ilerleme, rng), TedaviTuru.yok, false);
    }
  }
}

class SimulasyonServisi {
  final List<int> zonlar;
  final void Function(SensorOkuma okuma) veriUretildiginde;

  final Map<int, Iterator<_SimAdim>> _iteratorlar = {};
  Timer? _zamanlayici;

  SimulasyonServisi({required this.zonlar, required this.veriUretildiginde});

  bool get calisiyorMu => _zamanlayici != null;

  void baslat({Duration aralik = const Duration(seconds: 3)}) {
    final tohumRng = math.Random();
    _iteratorlar.clear();
    for (final zon in zonlar) {
      _iteratorlar[zon] = _senaryoUret(math.Random(tohumRng.nextInt(0x7FFFFFFF))).iterator;
    }

    _zamanlayici?.cancel();
    _birAdimUret(); // ilk veriyi hemen goster, kullanici beklemesin
    _zamanlayici = Timer.periodic(aralik, (_) => _birAdimUret());
  }

  void durdur() {
    _zamanlayici?.cancel();
    _zamanlayici = null;
    _iteratorlar.clear();
  }

  void _birAdimUret() {
    for (final zon in zonlar) {
      final iterator = _iteratorlar[zon];
      if (iterator == null || !iterator.moveNext()) continue;

      final adim = iterator.current;
      final teshis = KararMotoru.teshisEt(adim.ornek);

      veriUretildiginde(SensorOkuma(
        zaman: DateTime.now(),
        zone: zon,
        ph: adim.ornek['ph']!,
        ec: adim.ornek['ec']!,
        orp: adim.ornek['orp']!,
        turbidite: adim.ornek['turbidite']!,
        debi: adim.ornek['debi']!,
        deltaBasinc: adim.ornek['delta_basinc']!,
        durum: teshis.durum,
        tikanmaTuru: teshis.tur,
        guven: teshis.guven,
        tedaviAktif: adim.tedaviAktif,
        durulamaAktif: adim.durulamaAktif,
      ));
    }
  }
}
