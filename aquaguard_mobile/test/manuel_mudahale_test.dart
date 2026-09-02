// AquaGuard - Operator Manuel Mudahale Testleri
//
// "Belirsiz -> operatör kontrolü gerekiyor" mesajinin artik gercek bir
// aksiyona baglandigini (bkz. widgets/manuel_mudahale_paneli.dart,
// providers/uygulama_durumu.dart manuelTedaviBaslat/Durdur/NormaleDondur)
// dogrular. Hem saf simulasyon katmanini hem de UygulamaDurumu entegrasyonunu
// (aktivite kaydi + son okuma guncellemesi) kapsar.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/services/simulasyon_servisi.dart';

math.Random _sabitRng() => math.Random(42);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tedaviyeKarsilikGelenTur', () {
    test('her tedavi turu brief SS3 tedavi tablosundaki tikanma turune eslenir', () {
      expect(
        tedaviyeKarsilikGelenTur(TedaviTuru.asitDozlama),
        TikanmaTuru.kimyasal,
      );
      expect(
        tedaviyeKarsilikGelenTur(TedaviTuru.klorEnjeksiyon),
        TikanmaTuru.biyolojik,
      );
      expect(
        tedaviyeKarsilikGelenTur(TedaviTuru.yuksekBasincliYikama),
        TikanmaTuru.fiziksel,
      );
      expect(tedaviyeKarsilikGelenTur(TedaviTuru.yok), TikanmaTuru.yok);
    });
  });

  group('SimulasyonServisi manuel komut uretecleri', () {
    test('tedaviVeIyilesmeAdimlariUret dogru tedaviyi aktif gosterip durulamayla biter', () {
      final adimlar = tedaviVeIyilesmeAdimlariUret(
        'biyolojik',
        _sabitRng(),
      ).take(9).toList();

      expect(adimlar.first.tedaviAktif, TedaviTuru.klorEnjeksiyon);
      // Ilk 3 adim tedavi (durulama yok), sonraki adimlar durulama+iyilesme.
      expect(adimlar.take(3).every((a) => !a.durulamaAktif), isTrue);
      expect(adimlar.skip(3).any((a) => a.durulamaAktif), isTrue);
    });

    test('durulamaVeIyilesmeAdimlariUret once durulama sonra normale donus uretir', () {
      final adimlar = durulamaVeIyilesmeAdimlariUret(
        'fiziksel',
        _sabitRng(),
      ).take(6).toList();

      expect(adimlar[0].durulamaAktif, isTrue);
      expect(adimlar[0].tedaviAktif, TedaviTuru.yok);
      expect(adimlar.last.durulamaAktif, isFalse);
    });

    test('manuelTedaviBaslat, zonun bir sonraki zamanlayici tikinde etkili olur', () async {
      final uretilenler = <SensorOkuma>[];
      final servis = SimulasyonServisi(
        zonlar: [1],
        veriUretildiginde: uretilenler.add,
      );
      servis.baslat(aralik: const Duration(milliseconds: 20));
      uretilenler.clear();

      servis.manuelTedaviBaslat(1, TikanmaTuru.biyolojik);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(uretilenler, isNotEmpty);
      expect(uretilenler.first.tedaviAktif, TedaviTuru.klorEnjeksiyon);

      servis.durdur();
    });

    test('manuelNormaleDondur, bilinmeyen bir zon icin sessizce hicbir sey yapmaz', () {
      final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
      expect(() => servis.manuelNormaleDondur(999), returnsNormally);
      servis.durdur();
    });
  });

  group('UygulamaDurumu operator mudahalesi (entegrasyon)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('manuelTedaviBaslat: aktivite gecmisine manuelMudahale kaydi ekler', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await durum.manuelTedaviBaslat(1, TedaviTuru.asitDozlama);

      expect(durum.aktiviteGecmisi.first.tur, AktiviteTuru.manuelMudahale);
      expect(durum.aktiviteGecmisi.first.mesaj, contains('Operatör'));
      expect(durum.aktiviteGecmisi.first.mesaj, contains('Asit Dozlama'));

      durum.dispose();
    });

    test('manuelTedaviDurdur: aktif tedavi yoksa sessizce hicbir sey yapmaz', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      final oncekiUzunluk = durum.aktiviteGecmisi.length;
      await durum.manuelTedaviDurdur(999); // hic veri gelmemis bir zon
      expect(durum.aktiviteGecmisi.length, oncekiUzunluk);

      durum.dispose();
    });

    test('manuelNormaleDondur: aktivite gecmisine manuelMudahale kaydi ekler', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await durum.manuelNormaleDondur(2);

      expect(durum.aktiviteGecmisi.first.tur, AktiviteTuru.manuelMudahale);
      expect(durum.aktiviteGecmisi.first.mesaj, contains('yanlış alarm'));

      durum.dispose();
    });
  });
}
