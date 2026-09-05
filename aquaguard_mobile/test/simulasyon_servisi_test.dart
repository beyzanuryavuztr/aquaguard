// AquaGuard - senaryoAdimlariUret Sira Testleri (Oncelik 4)
//
// Sonsuz demo senaryo ureteciinin TAM BIR DONGUSUNUN (normal -> kotulesme
// -> tedavi -> durulama -> iyilesme -> yeni tur ile tekrar basa donus)
// dogru SIRADA ve dogru ADIM SAYILARINDA uretildigini dogrular. Manuel
// mudahale komutlarinin (tedaviVeIyilesmeAdimlariUret,
// durulamaVeIyilesmeAdimlariUret) sira testleri zaten manuel_mudahale_test.dart
// icinde var -- bu dosya SADECE otonom (sonsuz) senaryo akisinin kendisine odaklanir.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/services/simulasyon_servisi.dart';

math.Random _sabitRng() => math.Random(7);

void main() {
  test('ilk 4 adim: tedavi/durulama yok (normal izleme adimlari)', () {
    final adimlar = senaryoAdimlariUret(_sabitRng()).take(4).toList();

    for (final adim in adimlar) {
      expect(adim.tedaviAktif, TedaviTuru.yok);
      expect(adim.durulamaAktif, isFalse);
    }
  });

  test(
    '5-10. adimlar arasi (kotulesme): tedavi/durulama hala yok, ama hedef '
    'tur profiline DOGRU kademeli olarak ilerler',
    () {
      final tumAdimlar = senaryoAdimlariUret(_sabitRng()).take(10).toList();
      final kotulesmeAdimlari = tumAdimlar.skip(4).toList();

      expect(kotulesmeAdimlari.length, 6);
      for (final adim in kotulesmeAdimlari) {
        expect(adim.tedaviAktif, TedaviTuru.yok);
        expect(adim.durulamaAktif, isFalse);
      }
      // Turbidite (sadece hedef tur 'normal' disindaysa anlamli artar) --
      // en azindan monotonik SABIT KALMADIGINI (gercekten kademeli
      // ilerledigini) dogrulamak icin ardisik degerlerin AYNI OLMADIGINI kontrol et.
      final turbiditeler = kotulesmeAdimlari
          .map((a) => a.ornek['turbidite'])
          .toSet();
      expect(
        turbiditeler.length,
        greaterThan(1),
        reason: 'kademeli ilerleme sirasinda turbidite sabit kalmamali',
      );
    },
  );

  test(
    'tam bir dongu (19 adim): kotulesme sonrasi 3 tedavi + 2 durulama + 4 iyilesme adimi gelir, sonra YENI bir dongu (normal) baslar',
    () {
      final adimlar = senaryoAdimlariUret(_sabitRng()).take(19 + 4).toList();

      final tedaviAdimlari = adimlar.skip(10).take(3).toList();
      final durulamaAdimlari = adimlar.skip(13).take(2).toList();
      final iyilesmeAdimlari = adimlar.skip(15).take(4).toList();
      final yeniDonguAdimlari = adimlar.skip(19).take(4).toList();

      // Tedavi adimlari: hepsi AYNI (tek) tedavi turunu gosterir, durulama yok.
      final tedaviTurleri = tedaviAdimlari.map((a) => a.tedaviAktif).toSet();
      expect(tedaviTurleri.length, 1);
      expect(tedaviTurleri.single, isNot(TedaviTuru.yok));
      for (final adim in tedaviAdimlari) {
        expect(adim.durulamaAktif, isFalse);
      }

      // Durulama adimlari: tedavi bitmis (yok), durulama aktif.
      for (final adim in durulamaAdimlari) {
        expect(adim.tedaviAktif, TedaviTuru.yok);
        expect(adim.durulamaAktif, isTrue);
      }

      // Iyilesme adimlari: ne tedavi ne durulama.
      for (final adim in iyilesmeAdimlari) {
        expect(adim.tedaviAktif, TedaviTuru.yok);
        expect(adim.durulamaAktif, isFalse);
      }

      // 20. adimdan itibaren YENI bir dongu (normal izleme) baslamis olmali.
      for (final adim in yeniDonguAdimlari) {
        expect(adim.tedaviAktif, TedaviTuru.yok);
        expect(adim.durulamaAktif, isFalse);
      }
    },
  );

  test(
    'ayni tohum (seed) ile senaryo HER ZAMAN AYNI sirayi uretir (deterministik demo)',
    () {
      final birinci = senaryoAdimlariUret(math.Random(42)).take(19).toList();
      final ikinci = senaryoAdimlariUret(math.Random(42)).take(19).toList();

      for (var i = 0; i < 19; i++) {
        expect(birinci[i].tedaviAktif, ikinci[i].tedaviAktif);
        expect(birinci[i].durulamaAktif, ikinci[i].durulamaAktif);
        expect(birinci[i].ornek['debi'], ikinci[i].ornek['debi']);
      }
    },
  );

  test('simAdimindanOkumaUret, SimAdim verisini dogru SensorOkuma alanlarina esler', () {
    final adim = senaryoAdimlariUret(_sabitRng()).first;
    final zaman = DateTime(2026, 9, 5, 12);

    final okuma = simAdimindanOkumaUret(adim, 3, zaman);

    expect(okuma.zone, 3);
    expect(okuma.zaman, zaman);
    expect(okuma.ph, adim.ornek['ph']);
    expect(okuma.tedaviAktif, adim.tedaviAktif);
    expect(okuma.durulamaAktif, adim.durulamaAktif);
  });
}
