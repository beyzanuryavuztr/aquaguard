// AquaGuard - HavaTahmini JSON Parsing Testleri (Faz 4)
//
// Open-Meteo'nun gercek yanit sekliyle BIREBIR ayni yapida ornek bir JSON
// kullanir (bkz. https://open-meteo.com/en/docs).

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/hava_tahmini.dart';

void main() {
  final ornekJson = {
    'daily': {
      'time': ['2026-09-25', '2026-09-26', '2026-09-27'],
      'temperature_2m_max': [34.5, 36.1, 29.8],
      'temperature_2m_min': [21.2, 22.0, 19.5],
      'precipitation_probability_max': [5, 70, 20],
      'precipitation_sum': [0.0, 8.4, 1.1],
    },
  };

  group('HavaTahmini.fromOpenMeteoJson', () {
    test('gunluk tahminleri dogru sirada ve degerlerle ayristirir', () {
      final tahmin = HavaTahmini.fromOpenMeteoJson(
        ornekJson,
        enlem: 37.16,
        boylam: 38.79,
      );

      expect(tahmin.gunlukTahminler, hasLength(3));
      expect(tahmin.gunlukTahminler[1].maksSicaklikC, 36.1);
      expect(tahmin.gunlukTahminler[1].yagisIhtimaliYuzde, 70);
      expect(tahmin.enlem, 37.16);
      expect(tahmin.boylam, 38.79);
    });

    test('bugun/yarin getter dogru gunleri doner', () {
      final tahmin = HavaTahmini.fromOpenMeteoJson(
        ornekJson,
        enlem: 0,
        boylam: 0,
      );

      expect(tahmin.bugun?.maksSicaklikC, 34.5);
      expect(tahmin.yarin?.maksSicaklikC, 36.1);
      expect(tahmin.yarin?.yagisIhtimaliYuzde, 70);
    });

    test('eksik/bos "daily" alaniyla cokmez, bos liste doner', () {
      final tahmin = HavaTahmini.fromOpenMeteoJson({}, enlem: 0, boylam: 0);
      expect(tahmin.gunlukTahminler, isEmpty);
      expect(tahmin.bugun, isNull);
      expect(tahmin.yarin, isNull);
    });

    test('tek gunluk veriyle yarin null doner (cokmez)', () {
      final tekGunluk = {
        'daily': {
          'time': ['2026-09-25'],
          'temperature_2m_max': [30.0],
          'temperature_2m_min': [18.0],
          'precipitation_probability_max': [10],
          'precipitation_sum': [0.0],
        },
      };
      final tahmin = HavaTahmini.fromOpenMeteoJson(
        tekGunluk,
        enlem: 0,
        boylam: 0,
      );
      expect(tahmin.bugun, isNotNull);
      expect(tahmin.yarin, isNull);
    });
  });
}
