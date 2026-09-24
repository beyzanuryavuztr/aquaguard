// AquaGuard - Besin/Takviye Dozlama Testleri (Faz 3, 2026-09-25)
//
// Tikanma teshisinden BAGIMSIZ, operatorun kendi karariyla baslattigi
// besin/takviye dozlamanin (bkz. services/simulasyon_servisi.dart
// besinDozlamaBaslat/besinDozlamaAdimlariUret) AYNI mutex kilidine tabi
// oldugunu ve sensorlerin "normal" imzasinda kaldigini dogrular.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/services/simulasyon_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('besinDozlamaAdimlariUret (saf jenerator)', () {
    test(
      'tedavi fazi dogru TedaviTuru ile baslar, sensorler normal araliginda kalir',
      () {
        final rng = math.Random(7);
        final adimlar = besinDozlamaAdimlariUret(
          TedaviTuru.besinSivi,
          rng,
        ).take(3).toList();

        expect(
          adimlar.every((a) => a.tedaviAktif == TedaviTuru.besinSivi),
          isTrue,
        );
        expect(adimlar.every((a) => !a.durulamaAktif), isTrue);
        // "normal" sinifinin tipik pH araligi (bkz. sensor imzalari) --
        // gercek bir kayma simule edilmedigini dogrulayan kaba bir kontrol.
        for (final adim in adimlar) {
          expect(adim.ornek['ph'], inInclusiveRange(5.5, 8.5));
        }
      },
    );

    test('tedavi fazindan sonra durulama fazina gecer', () {
      final rng = math.Random(3);
      final adimlar = besinDozlamaAdimlariUret(
        TedaviTuru.besinToz,
        rng,
      ).take(5).toList(); // 3 tedavi + 2 durulama

      final durulamaAdimlari = adimlar.skip(3);
      expect(durulamaAdimlari.every((a) => a.durulamaAktif), isTrue);
      expect(
        durulamaAdimlari.every((a) => a.tedaviAktif == TedaviTuru.yok),
        isTrue,
      );
    });
  });

  group('SimulasyonServisi.besinDozlamaBaslat', () {
    test('mesgul olmayan zonda basarili baslar', () {
      final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
      servis.baslat(aralik: const Duration(minutes: 5));

      final basarili = servis.besinDozlamaBaslat(1, TedaviTuru.besinSivi);

      expect(basarili, isTrue);
      expect(servis.zonMesgulMu(1), isTrue);

      servis.durdur();
    });

    test('zon zaten mesgulse (manuelTedaviBaslat ile) REDDEDILIR', () {
      final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
      servis.baslat(aralik: const Duration(minutes: 5));

      servis.manuelTedaviBaslat(1, TikanmaTuru.kimyasal);
      final besinBasarili = servis.besinDozlamaBaslat(1, TedaviTuru.besinToz);

      expect(besinBasarili, isFalse);

      servis.durdur();
    });

    test('besin dozlama surerken normal tedavi de REDDEDILIR (cift yonlu kilit)', () {
      final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
      servis.baslat(aralik: const Duration(minutes: 5));

      servis.besinDozlamaBaslat(1, TedaviTuru.besinSivi);
      final tedaviBasarili = servis.manuelTedaviBaslat(1, TikanmaTuru.biyolojik);

      expect(tedaviBasarili, isFalse);

      servis.durdur();
    });

    test('kayitli olmayan bir zon icin false doner', () {
      final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
      servis.baslat(aralik: const Duration(minutes: 5));

      expect(servis.besinDozlamaBaslat(999, TedaviTuru.besinSivi), isFalse);

      servis.durdur();
    });
  });
}
