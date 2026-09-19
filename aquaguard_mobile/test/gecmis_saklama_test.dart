// AquaGuard - Sensor gecmisi saklama testleri (Y2)
//
// 1) Gecmise dakikada bir kayit yazilir; DURUM DEGISIMLERI hemen yazilir.
// 2) Bellekteki gecmis eskiden 100 kayda kirpiliyordu -- artik kirpilmaz.
// 3) Tedavi Gecmisi "tikanma olayi" sayisi, ardisik tespit okumalarini TEK
//    olay sayar (eskiden her okuma ayri sayiliyordu).
//
// Gercek modu (Demo KAPALI) simule eder; broker 127.0.0.1:1 (dinleyen yok).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/tedavi_gecmisi_ekrani.dart';

SensorOkuma _okuma(
  DateTime zaman, {
  TeshisDurumu durum = TeshisDurumu.normal,
  TikanmaTuru tur = TikanmaTuru.yok,
  TedaviTuru tedavi = TedaviTuru.yok,
}) => SensorOkuma(
  zaman: zaman,
  zone: 1,
  ph: 7,
  ec: 1.2,
  orp: 350,
  turbidite: 3,
  debi: 4,
  deltaBasinc: 0.1,
  durum: durum,
  tikanmaTuru: tur,
  guven: 95,
  tedaviAktif: tedavi,
  durulamaAktif: false,
);

void _gercekMod() => SharedPreferences.setMockInitialValues({
  'aquaguard_demo_modu_acik': false,
  'aquaguard_mqtt_host': '127.0.0.1',
  'aquaguard_mqtt_port': 1,
});

void main() {
  test('ayni durumdaki okumalar dakikada bir yazilir', () async {
    _gercekMod();
    final durum = UygulamaDurumu();
    await durum.baslat();
    final cihaz = durum.cihazProvider;
    final t0 = DateTime(2026, 9, 19, 12);

    // 10 sn araliklarla 5 dakika = 31 okuma, hepsi "normal".
    for (var i = 0; i <= 30; i++) {
      cihaz.telemetriGeldiTestIcin(_okuma(t0.add(Duration(seconds: 10 * i))));
    }

    // t0, +60, +120, +180, +240, +300 sn -> 6 kayit (31 DEGIL).
    expect(cihaz.gecmis(1), hasLength(6));
    durum.dispose();
  });

  test('durum degisimi dakika dolmadan HEMEN yazilir', () async {
    _gercekMod();
    final durum = UygulamaDurumu();
    await durum.baslat();
    final cihaz = durum.cihazProvider;
    final t0 = DateTime(2026, 9, 19, 12);

    cihaz.telemetriGeldiTestIcin(_okuma(t0));
    cihaz.telemetriGeldiTestIcin(
      _okuma(
        t0.add(const Duration(seconds: 10)),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.kimyasal,
      ),
    );
    cihaz.telemetriGeldiTestIcin(
      _okuma(
        t0.add(const Duration(seconds: 20)),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.kimyasal,
        tedavi: TedaviTuru.asitDozlama,
      ),
    );

    // normal, tespit, tespit+tedavi: uc gecis de kaydedildi.
    expect(cihaz.gecmis(1), hasLength(3));
    durum.dispose();
  });

  test('bellekteki gecmis 100 kayda KIRPILMAZ', () async {
    _gercekMod();
    final durum = UygulamaDurumu();
    await durum.baslat();
    final cihaz = durum.cihazProvider;
    final t0 = DateTime(2026, 9, 1);

    // 300 okuma, 1 dk arayla (hepsi yazilir).
    for (var i = 0; i < 300; i++) {
      cihaz.telemetriGeldiTestIcin(_okuma(t0.add(Duration(minutes: i))));
    }

    expect(cihaz.gecmis(1), hasLength(300));
    durum.dispose();
  });

  testWidgets('ardisik tespit okumalari TEK tikanma olayi sayilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _gercekMod();
    final durum = UygulamaDurumu();
    await tester.runAsync(() => durum.baslat());
    final cihaz = durum.cihazProvider;
    final t0 = DateTime.now().subtract(const Duration(hours: 2));

    cihaz.telemetriGeldiTestIcin(_okuma(t0));
    // 20 ardisik tespit okumasi (1 dk arayla) = TEK olay.
    for (var i = 1; i <= 20; i++) {
      cihaz.telemetriGeldiTestIcin(
        _okuma(
          t0.add(Duration(minutes: i)),
          durum: TeshisDurumu.tespitEdildi,
          tur: TikanmaTuru.biyolojik,
        ),
      );
    }
    cihaz.telemetriGeldiTestIcin(_okuma(t0.add(const Duration(minutes: 30))));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
          ChangeNotifierProvider.value(value: durum.tarlaProvider),
          ChangeNotifierProvider.value(value: durum.ayarlarProvider),
        ],
        child: const MaterialApp(home: TedaviGecmisiEkrani()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('tespit edilen 1 tıkanma olayının'),
      findsOneWidget,
    );
    durum.dispose();
  });
}
