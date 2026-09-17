// AquaGuard - VeriMigrasyonServisi Testleri (Faz 13)
//
// SharedPreferences'ta bulunan ESKI kullanici verisinin (zon basina sensor
// gecmisi/son okuma, aktivite gecmisi, bildirim gecmisi, tarla notlari)
// SQLite'a DOGRU sekilde, veri KAYBI OLMADAN tasindigini dogrular --
// ayrica migrasyonun IDEMPOTENT (guvenle tekrar calistirilabilir) oldugunu
// ve zaten migrate edilmis bir kurulumda hicbir sey yapmadigini kilitler.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tarla_notu.dart';
import 'package:aquaguard_mobile/repositories/drift_aktivite_bildirim_repository.dart';
import 'package:aquaguard_mobile/repositories/drift_sensor_okuma_repository.dart';
import 'package:aquaguard_mobile/repositories/drift_tarla_notu_repository.dart';
import 'package:aquaguard_mobile/services/depolama_servisi.dart';
import 'package:aquaguard_mobile/services/veri_migrasyon_servisi.dart';
import 'package:aquaguard_mobile/services/veritabani.dart';

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

  late AquaGuardVeritabani db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AquaGuardVeritabani.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'eski SharedPreferences verisi (gecmis/son okuma/aktivite/bildirim/notlar) '
    'SQLite\'a eksiksiz tasinir',
    () async {
      final depolama = DepolamaServisi();

      // Eski (migrasyon oncesi) SharedPreferences duzeninde iki zonluk
      // sensor gecmisi + son okuma yaz.
      final gecmisZon1 = [
        _okuma(zone: 1, zaman: DateTime(2026, 9, 10)),
        _okuma(zone: 1, zaman: DateTime(2026, 9, 9)),
      ];
      final gecmisZon3 = [_okuma(zone: 3, zaman: DateTime(2026, 9, 11))];
      await depolama.gecmisiTopluKaydet(1, gecmisZon1);
      await depolama.gecmisiTopluKaydet(3, gecmisZon3);
      await depolama.sonOkumayiKaydet(gecmisZon1.first);
      await depolama.sonOkumayiKaydet(gecmisZon3.first);

      final aktiviteGecmisi = [
        _aktivite(zaman: DateTime(2026, 9, 10), mesaj: 'Eski aktivite'),
      ];
      await depolama.aktiviteGecmisiniKaydet(aktiviteGecmisi);
      final bildirimGecmisi = [
        _aktivite(zaman: DateTime(2026, 9, 10), mesaj: 'Eski bildirim'),
      ];
      await depolama.bildirimGecmisiniKaydet(bildirimGecmisi);

      final tarlaNotlari = [
        TarlaNotu(
          id: 'not-1',
          tarlaId: 'tarla-1',
          metin: 'Eski not',
          zaman: DateTime(2026, 9, 10),
        ),
      ];
      await depolama.tarlaNotlariniKaydet(tarlaNotlari);

      // Migrasyonu calistir.
      await VeriMigrasyonServisi(db, depolama: depolama).gerekirseMigrateEt();

      // SQLite'ta beklenen veri var mi?
      final sensorDepo = DriftSensorOkumaRepository(db);
      expect((await sensorDepo.gecmisiGetir(1)).length, 2);
      expect((await sensorDepo.gecmisiGetir(3)).length, 1);
      expect((await sensorDepo.sonOkumayiGetir(1))?.zaman, gecmisZon1.first.zaman);
      expect((await sensorDepo.sonOkumayiGetir(3))?.zaman, gecmisZon3.first.zaman);

      final aktiviteBildirimDepo = DriftAktiviteBildirimRepository(
        db,
        depolama: depolama,
      );
      expect(
        (await aktiviteBildirimDepo.aktiviteGecmisiGetir()).single.mesaj,
        'Eski aktivite',
      );
      expect(
        (await aktiviteBildirimDepo.bildirimGecmisiGetir()).single.mesaj,
        'Eski bildirim',
      );

      final tarlaNotuDepo = DriftTarlaNotuRepository(db);
      expect(
        (await tarlaNotuDepo.tarlaNotlariGetir()).single.metin,
        'Eski not',
      );

      // Eski SharedPreferences anahtarlari temizlenmis olmali.
      final tercihler = await SharedPreferences.getInstance();
      expect(await depolama.gecmisiGetir(1), isEmpty);
      expect(await depolama.aktiviteGecmisiGetir(), isEmpty);
      expect(await depolama.tarlaNotlariGetir(), isEmpty);
      expect(
        tercihler.getBool('aquaguard_sqlite_migrasyon_tamamlandi'),
        isTrue,
      );
    },
  );

  test('migrasyon TEKRAR calistirilinca veri cogalmaz (idempotent)', () async {
    final depolama = DepolamaServisi();
    await depolama.gecmisiTopluKaydet(1, [
      _okuma(zone: 1, zaman: DateTime(2026, 9, 10)),
    ]);
    await depolama.aktiviteGecmisiniKaydet([
      _aktivite(zaman: DateTime(2026, 9, 10)),
    ]);

    final migrasyon = VeriMigrasyonServisi(db, depolama: depolama);
    await migrasyon.gerekirseMigrateEt();
    await migrasyon.gerekirseMigrateEt();
    await migrasyon.gerekirseMigrateEt();

    final sensorDepo = DriftSensorOkumaRepository(db);
    expect((await sensorDepo.gecmisiGetir(1)).length, 1);
    final aktiviteBildirimDepo = DriftAktiviteBildirimRepository(
      db,
      depolama: depolama,
    );
    expect((await aktiviteBildirimDepo.aktiviteGecmisiGetir()).length, 1);
  });

  test(
    'migrasyon zaten tamamlanmissa, sonradan SharedPreferences\'a eklenen '
    'veriyi TEKRAR kopyalamaya calismaz',
    () async {
      final tercihler = await SharedPreferences.getInstance();
      await tercihler.setBool('aquaguard_sqlite_migrasyon_tamamlandi', true);

      final depolama = DepolamaServisi();
      await depolama.gecmisiTopluKaydet(1, [
        _okuma(zone: 1, zaman: DateTime(2026, 9, 10)),
      ]);

      await VeriMigrasyonServisi(db, depolama: depolama).gerekirseMigrateEt();

      final sensorDepo = DriftSensorOkumaRepository(db);
      expect(await sensorDepo.gecmisiGetir(1), isEmpty);
    },
  );
}
