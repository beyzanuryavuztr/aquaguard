// AquaGuard - DriftSensorOkumaRepository Sinir (limit) Testleri
//
// SQLite gecisinin (Faz 13) gercek amaci olan "SharedPreferences'in 200
// kayitlik sinirindan kurtulma" hedefini dogrular: sayi sinirinin artik
// 10.000 oldugunu, 7 gunden eski kayitlarin CANLI buyume yolunda
// (gecmiseEkle) budandigini, ama ILK KURULUM tohumunun (gecmisiTopluKaydet --
// GecmisVeriUreticisi'nin 12 GUNLUK gecmise donuk sentetik verisi) bu zaman
// sinirindan BILEREK MUAF oldugunu kilitler.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/repositories/drift_sensor_okuma_repository.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AquaGuardVeritabani db;
  late DriftSensorOkumaRepository depo;

  setUp(() {
    db = AquaGuardVeritabani.test(NativeDatabase.memory());
    depo = DriftSensorOkumaRepository(db);
  });

  tearDown(() => db.close());

  test(
    'gecmisiTopluKaydet (ilk kurulum tohumu) 7 gunden eski kayitlari BUDAMAZ',
    () async {
      final simdi = DateTime.now();
      final onGunOncekiKayit = _okuma(
        zone: 1,
        zaman: simdi.subtract(const Duration(days: 10)),
      );

      await depo.gecmisiTopluKaydet(1, [onGunOncekiKayit]);

      final gecmis = await depo.gecmisiGetir(1);
      expect(
        gecmis,
        hasLength(1),
        reason:
            'Sentetik demo gecmisi (GecmisVeriUreticisi, 12 gunluk) toplu '
            'yazimda zaman sinirindan MUAF olmali',
      );
    },
  );

  test(
    'gecmiseEkle (canli buyume) 7 gunden eski kayitlari BUDAR',
    () async {
      final simdi = DateTime.now();
      final onGunOncekiKayit = _okuma(
        zone: 2,
        zaman: simdi.subtract(const Duration(days: 10)),
      );
      // Eski kaydi ONCE toplu-yazim yoluyla (zaman sinirindan muaf) sokariz --
      // amac: canli ekleme (gecmiseEkle) tetiklendiğinde bu kaydin
      // BUDANDIGINI gormek.
      await depo.gecmisiTopluKaydet(2, [onGunOncekiKayit]);
      expect(await depo.gecmisiGetir(2), hasLength(1));

      await depo.gecmiseEkle(_okuma(zone: 2, zaman: simdi));

      final gecmis = await depo.gecmisiGetir(2);
      expect(gecmis, hasLength(1));
      expect(
        gecmis.single.zaman.difference(simdi).inSeconds.abs(),
        lessThan(2),
        reason: '10 gunluk eski kayit silinmis, sadece yeni kayit kalmali',
      );
    },
  );

  test(
    'gecmiseEkle sayi siniri 10.000 -- asan EN ESKI kayitlar budanir',
    () async {
      final simdi = DateTime.now();
      // 10.000 kayidi (hepsi son birkac saat icinde, zaman siniri
      // TETIKLENMESIN diye) TOPLU yazimla hizlica sokariz.
      final tabanGecmis = List.generate(
        10000,
        (i) => _okuma(
          zone: 3,
          zaman: simdi.subtract(Duration(seconds: 10000 - i)),
        ),
      );
      await depo.gecmisiTopluKaydet(3, tabanGecmis);
      expect(await depo.gecmisiGetir(3), hasLength(10000));

      // 10.001'inci kaydi CANLI yoldan (gecmiseEkle) ekle -- sayi siniri
      // simdi tetiklenmeli, EN ESKI kayit budanmali.
      final enYeniOkuma = _okuma(zone: 3, zaman: simdi);
      await depo.gecmiseEkle(enYeniOkuma);

      final gecmis = await depo.gecmisiGetir(3);
      expect(gecmis, hasLength(10000));
      expect(gecmis.first.zaman, enYeniOkuma.zaman);
      expect(
        gecmis.any((o) => o.zaman == tabanGecmis.first.zaman),
        isFalse,
        reason: 'En eski (tabanGecmis.first) kayit sayi siniri asilinca silinmis olmali',
      );
    },
  );

  test('zonVerisiniTemizle hem gecmisi hem son okumayi siler', () async {
    final okuma = _okuma(zone: 4, zaman: DateTime.now());
    await depo.gecmisiTopluKaydet(4, [okuma]);
    await depo.sonOkumayiKaydet(okuma);

    await depo.zonVerisiniTemizle(4);

    expect(await depo.gecmisiGetir(4), isEmpty);
    expect(await depo.sonOkumayiGetir(4), isNull);
  });
}
