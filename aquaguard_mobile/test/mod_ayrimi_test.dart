// AquaGuard - Demo/Gercek veri ayrimi testleri (K7)
//
// Demo Modu SENTETIK veri uretir; gercek mod GERCEK cihaz verisi. Ikisi
// asla karismamali: gercek modda sahte gecmis/olay/istatistik olmamali ve
// demoya gecip donmek gercek gecmisi kirletmemeli.
//
// Broker 127.0.0.1:1 (dinleyen yok) -- gercek bir ag servisine BAGIMLI DEGIL.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/depolama_unawaited.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

SensorOkuma _gercekOkuma(DateTime zaman) => SensorOkuma(
  zaman: zaman,
  zone: 1,
  ph: 7.11,
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
);

void _prefs({required bool demo}) => SharedPreferences.setMockInitialValues({
  'aquaguard_demo_modu_acik': demo,
  'aquaguard_mqtt_host': '127.0.0.1',
  'aquaguard_mqtt_port': 1,
});

void main() {
  test(
    'GERCEK modda ilk acilista sentetik gecmis/aktivite URETILMEZ',
    () async {
      _prefs(demo: false);
      final durum = UygulamaDurumu();
      await durum.baslat();

      expect(durum.cihazProvider.gecmis(1), isEmpty);
      expect(durum.cihazProvider.sonOkuma(1), isNull);
      expect(durum.aktiviteProvider.aktiviteGecmisi, isEmpty);
      expect(durum.aktiviteProvider.bildirimGecmisi, isEmpty);
      durum.dispose();
    },
  );

  test('DEMO modunda ilk acilista sentetik gecmis uretilir', () async {
    _prefs(demo: true);
    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.cihazProvider.gecmis(1), isNotEmpty);
    expect(durum.aktiviteProvider.aktiviteGecmisi, isNotEmpty);
    durum.dispose();
  });

  test('demo -> gercek gecisinde sentetik veri GERCEK moda sizmaz', () async {
    _prefs(demo: true);
    final durum = UygulamaDurumu();
    await durum.baslat();
    expect(durum.cihazProvider.gecmis(1), isNotEmpty); // demo seed

    await durum.cihazProvider.demoModunuKapat();

    expect(durum.cihazProvider.gecmis(1), isEmpty);
    expect(durum.cihazProvider.sonOkuma(1), isNull);
    expect(durum.aktiviteProvider.aktiviteGecmisi, isEmpty);
    durum.dispose();
  });

  test(
    'gercek veri demoya gecip donunce KORUNUR, demo verisi karismaz',
    () async {
      _prefs(demo: false);
      final durum = UygulamaDurumu();
      await durum.baslat();
      final cihaz = durum.cihazProvider;

      // Gercek moda bir cihaz okumasi geldi.
      final gercekZaman = DateTime(2026, 9, 19, 12);
      cihaz.telemetriGeldiTestIcin(_gercekOkuma(gercekZaman));
      await bekleyenYazimlariBekle();
      expect(cihaz.gecmis(1), hasLength(1));

      // Demoya gec: sentetik gecmis gorunur, gercek okuma GORUNMEZ.
      await cihaz.demoModunuAc();
      expect(cihaz.gecmis(1), isNotEmpty);
      expect(
        cihaz.gecmis(1).any((o) => o.ph == 7.11 && o.zaman == gercekZaman),
        isFalse,
      );
      // Demo sirasinda (simulasyon) yazilanlar gercek depoya GITMEZ.
      await bekleyenYazimlariBekle();

      // Gercege don: tam olarak o TEK gercek okuma geri gelir.
      await cihaz.demoModunuKapat();
      expect(cihaz.gecmis(1), hasLength(1));
      expect(cihaz.gecmis(1).single.zaman, gercekZaman);
      durum.dispose();
    },
  );
}
