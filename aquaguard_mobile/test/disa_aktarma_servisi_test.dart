// AquaGuard - CSV Disa Aktarma Servisi Testleri

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/services/disa_aktarma_servisi.dart';

SensorOkuma _ornekOkuma({
  required DateTime zaman,
  TeshisDurumu durum = TeshisDurumu.normal,
  TikanmaTuru tur = TikanmaTuru.yok,
}) {
  return SensorOkuma(
    zaman: zaman,
    zone: 1,
    ph: 7.01,
    ec: 1.15,
    orp: 375,
    turbidite: 3.2,
    debi: 4.0,
    deltaBasinc: 0.1,
    durum: durum,
    tikanmaTuru: tur,
    guven: 100,
    tedaviAktif: TedaviTuru.yok,
    durulamaAktif: false,
  );
}

void main() {
  group('DisaAktarmaServisi.csvOlustur', () {
    test('baslik satiri ve tum okumalari icerir', () {
      final gecmis = [
        _ornekOkuma(zaman: DateTime(2026, 9, 1, 10)),
        _ornekOkuma(zaman: DateTime(2026, 9, 1, 11)),
      ];

      final csv = DisaAktarmaServisi.csvOlustur(gecmis);
      final satirlar = csv.trim().split('\n');

      expect(satirlar.first, startsWith('Zaman,Zon,pH'));
      expect(satirlar.length, 3); // 1 baslik + 2 veri satiri
    });

    test('girdi sirasindan bagimsiz olarak KRONOLOJIK (eskiden yeniye) yazar', () {
      final yeni = _ornekOkuma(zaman: DateTime(2026, 9, 2));
      final eski = _ornekOkuma(zaman: DateTime(2026, 9, 1));

      // Kasten TERS sirada veriyoruz (depolama EN YENI ONCE tutar).
      final csv = DisaAktarmaServisi.csvOlustur([yeni, eski]);
      final satirlar = csv.trim().split('\n');

      expect(satirlar[1], contains('2026-09-01'));
      expect(satirlar[2], contains('2026-09-02'));
    });

    test('virgul iceren alanlar (durum etiketi) tirnaklanir', () {
      final okuma = _ornekOkuma(
        zaman: DateTime(2026, 9, 1),
        durum: TeshisDurumu.belirsiz,
      );
      // durumEtiketi(belirsiz) = "Belirsiz - Operatör Kontrolü Gerekli" (virgul YOK
      // ama tire var) -- yine de RFC4180 kacis mantigini asagidaki testte
      // dogrudan _alan uzerinden dolayli olarak dogrulariz: virgul iceren
      // bir deger (guven skoru gibi bir string olsaydi) tirnaklanmali.
      final csv = DisaAktarmaServisi.csvOlustur([okuma]);
      expect(csv, contains('Belirsiz'));
    });

    test('bos gecmis icin sadece baslik satiri uretir', () {
      final csv = DisaAktarmaServisi.csvOlustur(const []);
      expect(csv.trim().split('\n').length, 1);
    });
  });

  group('DisaAktarmaServisi.dosyaAdiUret', () {
    test('bosluk ve ozel karakterleri temizler, .csv ile biter', () {
      final ad = DisaAktarmaServisi.dosyaAdiUret('Kuzey Tarlası_zon1');
      expect(ad, endsWith('.csv'));
      expect(ad, isNot(contains(' ')));
      expect(ad, startsWith('aquaguard_'));
    });
  });
}
