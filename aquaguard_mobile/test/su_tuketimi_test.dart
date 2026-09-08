// AquaGuard - Su Tuketimi Hesabi Testleri
//
// suTuketimiHesaplaLitre() saf fonksiyonunu dogrudan test eder --
// ardisik okumalar arasindaki debi*sure carpimlarinin dogru toplandigini,
// bos/tek elemanli girdilerde 0.0 dondugunu ve girdinin EN YENI ONCE
// (UygulamaDurumu.gecmis() formati) beklendigini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/su_tuketimi.dart';

SensorOkuma _okuma({required DateTime zaman, required double debi}) {
  return SensorOkuma(
    zaman: zaman,
    zone: 1,
    ph: 7.0,
    ec: 1.15,
    orp: 375,
    turbidite: 3,
    debi: debi,
    deltaBasinc: 0.10,
    durum: TeshisDurumu.normal,
    tikanmaTuru: TikanmaTuru.yok,
    guven: 100,
    tedaviAktif: TedaviTuru.yok,
    durulamaAktif: false,
  );
}

void main() {
  group('suTuketimiHesaplaLitre', () {
    test('bos liste icin 0.0 doner', () {
      expect(suTuketimiHesaplaLitre([]), 0.0);
    });

    test('tek okuma icin 0.0 doner (sure farki hesaplanamaz)', () {
      final tek = [_okuma(zaman: DateTime(2026, 9, 1, 12, 0), debi: 4.0)];
      expect(suTuketimiHesaplaLitre(tek), 0.0);
    });

    test('iki okuma arasinda debi*sure(dakika) dogru hesaplanir', () {
      // En yeni once: t=13:00 (debi onemsiz, en sonraki), t=12:00 (debi=4.0).
      // Beklenen: 4.0 LPM * 60 dakika = 240.0 litre.
      final gecmisEnYeniOnce = [
        _okuma(zaman: DateTime(2026, 9, 1, 13, 0), debi: 3.0),
        _okuma(zaman: DateTime(2026, 9, 1, 12, 0), debi: 4.0),
      ];
      expect(suTuketimiHesaplaLitre(gecmisEnYeniOnce), closeTo(240.0, 0.001));
    });

    test('birden fazla araligin toplami dogru alinir', () {
      // Kronolojik: 10:00 (debi=2.0) -> 10:30 (debi=5.0) -> 11:00 (debi=1.0).
      // Beklenen: (2.0*30) + (5.0*30) = 60 + 150 = 210.0 litre
      // (son okumanin debisi -- 1.0 -- kendisinden SONRA bir okuma
      // olmadigi icin hesaba katilmaz, tam da fonksiyonun dogru davranisi).
      final gecmisEnYeniOnce = [
        _okuma(zaman: DateTime(2026, 9, 1, 11, 0), debi: 1.0),
        _okuma(zaman: DateTime(2026, 9, 1, 10, 30), debi: 5.0),
        _okuma(zaman: DateTime(2026, 9, 1, 10, 0), debi: 2.0),
      ];
      expect(suTuketimiHesaplaLitre(gecmisEnYeniOnce), closeTo(210.0, 0.001));
    });

    test('sifir/negatif sure farkli (bozuk siralama) araliklar atlanir', () {
      // Ayni zaman damgasina sahip iki ardisik okuma (sure farki 0) --
      // o aralik icin katki 0 olmali, istisna firlatilmamali.
      final ayniAn = DateTime(2026, 9, 1, 10, 0);
      final gecmisEnYeniOnce = [
        _okuma(zaman: ayniAn, debi: 4.0),
        _okuma(zaman: ayniAn, debi: 4.0),
      ];
      expect(suTuketimiHesaplaLitre(gecmisEnYeniOnce), 0.0);
    });
  });
}
