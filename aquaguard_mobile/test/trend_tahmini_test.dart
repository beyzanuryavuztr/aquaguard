// AquaGuard - TrendTahmini (Lineer Regresyon) Testleri

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/trend_tahmini.dart';

SensorOkuma _okuma({required DateTime zaman, required double debi}) {
  return SensorOkuma(
    zaman: zaman,
    zone: 1,
    ph: 7,
    ec: 1.2,
    orp: 300,
    turbidite: 5,
    debi: debi,
    deltaBasinc: 0.1,
    durum: TeshisDurumu.normal,
    tikanmaTuru: TikanmaTuru.yok,
    guven: 0,
    tedaviAktif: TedaviTuru.yok,
    durulamaAktif: false,
  );
}

void main() {
  group('trendHesapla', () {
    test('2\'den az/3\'ten az noktada null doner', () {
      final baslangic = DateTime(2026, 1, 1);
      final okumalar = [
        _okuma(zaman: baslangic, debi: 4.0),
        _okuma(zaman: baslangic.add(const Duration(days: 1)), debi: 3.8),
      ];
      expect(trendHesapla(okumalar, (o) => o.debi), isNull);
    });

    test('KUSURSUZ dogrusal veride (y = 2x + 5) egim ve kesisim dogru bulunur', () {
      final baslangic = DateTime(2026, 1, 1);
      // x (gun): 0, 1, 2, 3, 4  ->  y = 2x + 5: 5, 7, 9, 11, 13
      final okumalar = List.generate(5, (i) {
        return _okuma(
          zaman: baslangic.add(Duration(days: i)),
          debi: 2.0 * i + 5.0,
        );
      });

      final tahmin = trendHesapla(okumalar, (o) => o.debi);

      expect(tahmin, isNotNull);
      expect(tahmin!.egim, closeTo(2.0, 0.001));
      expect(tahmin.kesisim, closeTo(5.0, 0.001));
    });

    test('degerTahminEt gelecege dogru ekstrapolasyon yapar', () {
      final baslangic = DateTime(2026, 1, 1);
      final okumalar = List.generate(5, (i) {
        return _okuma(
          zaman: baslangic.add(Duration(days: i)),
          debi: 2.0 * i + 5.0,
        );
      });
      final tahmin = trendHesapla(okumalar, (o) => o.debi)!;

      // 3 gun sonrasi (x=7): 2*7+5 = 19
      expect(tahmin.degerTahminEt(7), closeTo(19.0, 0.001));
    });

    test('duz (sabit) veride egim sifira yakin doner', () {
      final baslangic = DateTime(2026, 1, 1);
      final okumalar = List.generate(4, (i) {
        return _okuma(zaman: baslangic.add(Duration(days: i)), debi: 4.0);
      });
      final tahmin = trendHesapla(okumalar, (o) => o.debi)!;
      expect(tahmin.egim, closeTo(0.0, 0.001));
    });

    test('tum noktalar AYNI zaman damgasindaysa bolme hatasi olmaz (egim=0)', () {
      final ayniZaman = DateTime(2026, 1, 1);
      final okumalar = List.generate(
        3,
        (i) => _okuma(zaman: ayniZaman, debi: 4.0 + i),
      );
      expect(
        () => trendHesapla(okumalar, (o) => o.debi),
        returnsNormally,
      );
      final tahmin = trendHesapla(okumalar, (o) => o.debi)!;
      expect(tahmin.egim, 0.0);
    });

    test('azalan (negatif egimli) trend dogru tespit edilir', () {
      final baslangic = DateTime(2026, 1, 1);
      // debi zaman icinde azaliyor (tikanma egilimi) -- y = -0.3x + 4
      final okumalar = List.generate(6, (i) {
        return _okuma(
          zaman: baslangic.add(Duration(days: i)),
          debi: -0.3 * i + 4.0,
        );
      });
      final tahmin = trendHesapla(okumalar, (o) => o.debi)!;
      expect(tahmin.egim, lessThan(0));
    });
  });
}
