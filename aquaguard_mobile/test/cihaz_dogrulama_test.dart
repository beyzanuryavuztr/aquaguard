// AquaGuard - Cihaz dogrulama testleri (K1 + Y3)
//
// 1) Cihaz telemetrisindeki `ana_vana_acik` alani yerel vana tahminiyle
//    esitlenir (komut sonrasi bekleme suresi HARIC).
// 2) Acil durdurma gercek modda cihaza ULASAMAZSA kuyruga alinan komut
//    sayisi raporlanir -- arayuz "durduruldu" diye yalan soylemez.
//
// Gercek modu (Demo KAPALI) simule eder; broker 127.0.0.1:1 (dinleyen yok)
// -> ag baglantisi hizla basarisiz olur, gercek bir servise BAGIMLI DEGIL.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

SensorOkuma _okuma({int zone = 1, bool? vanaAcik}) => SensorOkuma(
  zaman: DateTime.now(),
  zone: zone,
  ph: 7,
  ec: 1.2,
  orp: 350,
  turbidite: 3,
  debi: 4,
  deltaBasinc: 0.1,
  durum: TeshisDurumu.normal,
  tikanmaTuru: TikanmaTuru.yok,
  guven: 100,
  tedaviAktif: TedaviTuru.yok,
  durulamaAktif: false,
  anaVanaAcik: vanaAcik,
);

Future<UygulamaDurumu> _gercekModDurumu({bool demo = false}) async {
  SharedPreferences.setMockInitialValues({
    'aquaguard_demo_modu_acik': demo,
    'aquaguard_mqtt_host': '127.0.0.1',
    'aquaguard_mqtt_port': 1,
  });
  final durum = UygulamaDurumu();
  await durum.baslat();
  return durum;
}

void main() {
  group('SensorOkuma.anaVanaAcik', () {
    test('JSON true/false okunur, alan yoksa veya bool degilse null', () {
      Map<String, dynamic> taban() =>
          _okuma().toJson()..remove('ana_vana_acik');

      expect(
        SensorOkuma.fromJson({...taban(), 'ana_vana_acik': true}).anaVanaAcik,
        isTrue,
      );
      expect(
        SensorOkuma.fromJson({...taban(), 'ana_vana_acik': false}).anaVanaAcik,
        isFalse,
      );
      expect(SensorOkuma.fromJson(taban()).anaVanaAcik, isNull);
      expect(
        SensorOkuma.fromJson({...taban(), 'ana_vana_acik': 'evet'}).anaVanaAcik,
        isNull,
      );
    });

    test('toJson -> fromCacheJson gidis-donus korunur', () {
      final geri = SensorOkuma.fromCacheJson(_okuma(vanaAcik: false).toJson());
      expect(geri.anaVanaAcik, isFalse);
    });
  });

  group('vana esitleme (gercek mod)', () {
    test('cihazda KAPALI ise yerel durum kapali olur', () async {
      final durum = await _gercekModDurumu();
      final cihaz = durum.cihazProvider;
      expect(cihaz.sulamasiDurduruldu(1), isFalse);

      cihaz.telemetriGeldiTestIcin(_okuma(vanaAcik: false));

      expect(cihaz.sulamasiDurduruldu(1), isTrue);
      durum.dispose();
    });

    test('cihazda ACIK ise yerel kapali durum acilir', () async {
      final durum = await _gercekModDurumu();
      final cihaz = durum.cihazProvider;
      cihaz.telemetriGeldiTestIcin(_okuma(vanaAcik: false));
      expect(cihaz.sulamasiDurduruldu(1), isTrue);

      cihaz.telemetriGeldiTestIcin(_okuma(vanaAcik: true));

      expect(cihaz.sulamasiDurduruldu(1), isFalse);
      durum.dispose();
    });

    test('alan gelmediyse (null) yerel tahmin degismez', () async {
      final durum = await _gercekModDurumu();
      final cihaz = durum.cihazProvider;
      await cihaz.sulamayiDurdur(1);

      cihaz.telemetriGeldiTestIcin(_okuma());

      expect(cihaz.sulamasiDurduruldu(1), isTrue);
      durum.dispose();
    });

    test('yerel komuttan hemen sonra eski telemetri komutu EZMEZ', () async {
      final durum = await _gercekModDurumu();
      final cihaz = durum.cihazProvider;
      await cihaz.sulamayiDurdur(1); // yerel: kapali

      // Komut cihaza henuz yansimadi: telemetri hala "acik" diyor.
      cihaz.telemetriGeldiTestIcin(_okuma(vanaAcik: true));

      expect(cihaz.sulamasiDurduruldu(1), isTrue);
      durum.dispose();
    });

    test('Demo Modu\'nda cihaz alani yok sayilir', () async {
      final durum = await _gercekModDurumu(demo: true);
      final cihaz = durum.cihazProvider;

      cihaz.telemetriGeldiTestIcin(_okuma(vanaAcik: false));

      expect(cihaz.sulamasiDurduruldu(1), isFalse);
      durum.dispose();
    });
  });

  group('acil durdurma iletim raporu', () {
    test(
      'gercek modda cihaza ulasilamazsa komutlar KUYRUGA alinir ve sayilir',
      () async {
        final durum = await _gercekModDurumu();
        final cihaz = durum.cihazProvider;
        final zonSayisi = durum.tumZonNumaralari.length;

        await cihaz.acilDurdurmaTetikle();

        // Her zon icin bir sulama_durdur komutu, hicbiri iletilemedi.
        expect(cihaz.sonAcilDurdurmaKuyrugaAlinan, zonSayisi);
        durum.dispose();
      },
    );

    test('Demo Modu\'nda kuyruga alinan komut yoktur', () async {
      final durum = await _gercekModDurumu(demo: true);
      final cihaz = durum.cihazProvider;

      await cihaz.acilDurdurmaTetikle();

      expect(cihaz.sonAcilDurdurmaKuyrugaAlinan, 0);
      durum.dispose();
    });
  });
}
