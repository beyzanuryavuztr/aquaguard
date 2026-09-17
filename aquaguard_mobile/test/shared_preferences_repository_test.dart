// AquaGuard - SharedPreferences* Repository Testleri (Faz 15)
//
// Faz 12b'de tanimlanan repository arayuzlerinin (SensorOkumaRepository,
// AktiviteBildirimRepository, TarlaNotuRepository) SharedPreferences tabanli
// uygulamalarini dogrudan test eder. Uretimde artik SADECE Drift tabanli
// uygulamalar kullaniliyor (bkz. UygulamaDurumu facade'i, Faz 13) -- bu
// SharedPreferences uygulamalari facade tarafindan HIC cagirilmiyor, bu
// yuzden onlari dogrulayan TEK yer bu dosyadir. Davranislarinin, arayuzun
// vaat ettigi sozlesmeyle (DepolamaServisi'ne birebir INCE bir sarmalayici)
// hala eslestigini kilitler.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tarla_notu.dart';
import 'package:aquaguard_mobile/repositories/aktivite_bildirim_repository.dart';
import 'package:aquaguard_mobile/repositories/sensor_okuma_repository.dart';
import 'package:aquaguard_mobile/repositories/tarla_notu_repository.dart';

SensorOkuma _okuma({required int zone, required DateTime zaman}) {
  return SensorOkuma(
    zaman: zaman,
    zone: zone,
    ph: 7,
    ec: 1.2,
    orp: 300,
    turbidite: 5,
    debi: 4,
    deltaBasinc: 0.1,
    durum: TeshisDurumu.normal,
    tikanmaTuru: TikanmaTuru.yok,
    guven: 100,
    tedaviAktif: TedaviTuru.yok,
    durulamaAktif: false,
  );
}

AktiviteKaydi _aktivite({required DateTime zaman, String mesaj = 'Test'}) {
  return AktiviteKaydi(
    zaman: zaman,
    zone: 1,
    mesaj: mesaj,
    tur: AktiviteTuru.manuelMudahale,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SharedPreferencesSensorOkumaRepository', () {
    test('gecmisiTopluKaydet + gecmisiGetir round-trip', () async {
      final depo = SharedPreferencesSensorOkumaRepository();
      final gecmis = [
        _okuma(zone: 2, zaman: DateTime(2026, 9, 10)),
        _okuma(zone: 2, zaman: DateTime(2026, 9, 9)),
      ];

      await depo.gecmisiTopluKaydet(2, gecmis);

      expect((await depo.gecmisiGetir(2)).length, 2);
      expect(await depo.gecmisiGetir(3), isEmpty);
    });

    test('gecmiseEkle mevcut gecmisin BASINA ekler', () async {
      final depo = SharedPreferencesSensorOkumaRepository();
      await depo.gecmisiTopluKaydet(1, [
        _okuma(zone: 1, zaman: DateTime(2026, 9, 9)),
      ]);

      final yeni = _okuma(zone: 1, zaman: DateTime(2026, 9, 10));
      await depo.gecmiseEkle(yeni);

      final gecmis = await depo.gecmisiGetir(1);
      expect(gecmis.length, 2);
      expect(gecmis.first.zaman, yeni.zaman);
    });

    test('sonOkumayiKaydet + sonOkumayiGetir round-trip', () async {
      final depo = SharedPreferencesSensorOkumaRepository();
      final okuma = _okuma(zone: 4, zaman: DateTime(2026, 9, 10));

      await depo.sonOkumayiKaydet(okuma);

      expect((await depo.sonOkumayiGetir(4))?.zaman, okuma.zaman);
      expect(await depo.sonOkumayiGetir(5), isNull);
    });

    test('zonVerisiniTemizle hem gecmisi hem son okumayi siler', () async {
      final depo = SharedPreferencesSensorOkumaRepository();
      final okuma = _okuma(zone: 1, zaman: DateTime(2026, 9, 10));
      await depo.gecmisiTopluKaydet(1, [okuma]);
      await depo.sonOkumayiKaydet(okuma);

      await depo.zonVerisiniTemizle(1);

      expect(await depo.gecmisiGetir(1), isEmpty);
      expect(await depo.sonOkumayiGetir(1), isNull);
    });
  });

  group('SharedPreferencesAktiviteBildirimRepository', () {
    test('aktiviteGecmisiniKaydet + aktiviteGecmisiGetir round-trip', () async {
      final depo = SharedPreferencesAktiviteBildirimRepository();
      final gecmis = [_aktivite(zaman: DateTime(2026, 9, 10), mesaj: 'A')];

      await depo.aktiviteGecmisiniKaydet(gecmis);

      expect((await depo.aktiviteGecmisiGetir()).single.mesaj, 'A');
    });

    test('bildirimGecmisiniKaydet + bildirimGecmisiGetir round-trip', () async {
      final depo = SharedPreferencesAktiviteBildirimRepository();
      final gecmis = [_aktivite(zaman: DateTime(2026, 9, 10), mesaj: 'B')];

      await depo.bildirimGecmisiniKaydet(gecmis);

      expect((await depo.bildirimGecmisiGetir()).single.mesaj, 'B');
    });

    test(
      'okunmusBildirimIdleriniKaydet + okunmusBildirimIdleriGetir round-trip',
      () async {
        final depo = SharedPreferencesAktiviteBildirimRepository();

        await depo.okunmusBildirimIdleriniKaydet({1, 2, 3});

        expect(await depo.okunmusBildirimIdleriGetir(), {1, 2, 3});
      },
    );
  });

  group('SharedPreferencesTarlaNotuRepository', () {
    test('tarlaNotlariniKaydet + tarlaNotlariGetir round-trip', () async {
      final depo = SharedPreferencesTarlaNotuRepository();
      final notlar = [
        TarlaNotu(
          id: 'not-1',
          tarlaId: 'tarla-1',
          metin: 'Test notu',
          zaman: DateTime(2026, 9, 10),
        ),
      ];

      await depo.tarlaNotlariniKaydet(notlar);

      expect((await depo.tarlaNotlariGetir()).single.metin, 'Test notu');
    });
  });
}
