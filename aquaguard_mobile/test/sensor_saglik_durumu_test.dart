import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_saglik_durumu.dart';

void main() {
  group('sensorSagligiDegerlendir', () {
    test('yetersiz veri (4\'ten az) her zaman normal doner', () {
      final durum = sensorSagligiDegerlendir(
        sonDegerlerEnYeniOnce: [7.1, 7.0, 6.9],
        normalStd: 0.3,
      );
      expect(durum, SensorSaglikDurumu.normal);
    });

    test('normal dalgalanma normal doner', () {
      final durum = sensorSagligiDegerlendir(
        sonDegerlerEnYeniOnce: [7.1, 7.0, 6.9, 7.05, 6.95],
        normalStd: 0.3,
      );
      expect(durum, SensorSaglikDurumu.normal);
    });

    test('ardisik iki okuma arasinda std*5\'i asan fark ani sicrama sayilir', () {
      // normalStd=0.3 -> esik 1.5; 7.0 -> 9.0 farki 2.0, esigi asiyor.
      final durum = sensorSagligiDegerlendir(
        sonDegerlerEnYeniOnce: [9.0, 7.0, 6.9, 7.05, 6.95],
        normalStd: 0.3,
      );
      expect(durum, SensorSaglikDurumu.aniSicrama);
    });

    test('esigin TAM ALTINDAKI fark ani sicrama SAYILMAZ', () {
      // fark = 1.4, esik = 1.5 -- esigin altinda.
      final durum = sensorSagligiDegerlendir(
        sonDegerlerEnYeniOnce: [8.4, 7.0, 6.9, 7.05, 6.95],
        normalStd: 0.3,
      );
      expect(durum, SensorSaglikDurumu.normal);
    });

    test('son 4 okuma birebir ayniysa sabit deger sayilir', () {
      final durum = sensorSagligiDegerlendir(
        sonDegerlerEnYeniOnce: [7.0, 7.0, 7.0, 7.0, 6.5],
        normalStd: 0.3,
      );
      expect(durum, SensorSaglikDurumu.sabitDeger);
    });

    test('normalStd=0 iken ani sicrama kontrolu atlanir (sifira bolme yok)', () {
      final durum = sensorSagligiDegerlendir(
        sonDegerlerEnYeniOnce: [50.0, 1.0, 6.9, 7.05],
        normalStd: 0.0,
      );
      expect(durum, isNot(SensorSaglikDurumu.aniSicrama));
    });
  });
}
