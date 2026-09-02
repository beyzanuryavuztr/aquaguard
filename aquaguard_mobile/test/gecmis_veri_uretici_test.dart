// AquaGuard - Gecmis Veri Ureticisi Testleri

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/services/gecmis_veri_uretici.dart';

void main() {
  group('GecmisVeriUreticisi.zonGecmisiUret', () {
    test('kronolojik (eskiden yeniye) sirali, hicbir bosluk/ters siralama yok', () {
      final gecmis = GecmisVeriUreticisi.zonGecmisiUret(1);

      expect(gecmis, isNotEmpty);
      for (var i = 1; i < gecmis.length; i++) {
        expect(
          gecmis[i].zaman.isAfter(gecmis[i - 1].zaman),
          isTrue,
          reason: 'her okuma bir oncekinden daha yeni olmali',
        );
      }
    });

    test('ayni zon icin tekrarlanabilir (sabit seed)', () {
      final g1 = GecmisVeriUreticisi.zonGecmisiUret(2);
      final g2 = GecmisVeriUreticisi.zonGecmisiUret(2);

      expect(g1.length, g2.length);
      expect(g1.first.ph, g2.first.ph);
      expect(g1.last.durum, g2.last.durum);
    });

    test('farkli zonlar farkli senaryolar uretir (hepsi ayni degil)', () {
      final g1 = GecmisVeriUreticisi.zonGecmisiUret(1);
      final g6 = GecmisVeriUreticisi.zonGecmisiUret(6);

      expect(g1.first.ph == g6.first.ph, isFalse);
    });

    test('uretilen gecmiste en az bir tikanma tespiti veya tedavi olayi var '
        '(tamamen duz "normal" degil -- gercekci bir "saha gecmisi" hissi)', () {
      final gecmis = GecmisVeriUreticisi.zonGecmisiUret(3);
      final ilginc = gecmis.any(
        (o) => o.durum == TeshisDurumu.tespitEdildi || o.tedaviAktif != TedaviTuru.yok,
      );
      expect(ilginc, isTrue);
    });
  });

  group('GecmisVeriUreticisi.aktiviteleriTuret', () {
    test('uretilen gecmisten en az bir aktivite kaydi cikar', () {
      final gecmis = GecmisVeriUreticisi.zonGecmisiUret(4);
      final aktiviteler = GecmisVeriUreticisi.aktiviteleriTuret(gecmis);

      expect(aktiviteler, isNotEmpty);
      for (final a in aktiviteler) {
        expect(a.zone, 4);
      }
    });
  });
}
