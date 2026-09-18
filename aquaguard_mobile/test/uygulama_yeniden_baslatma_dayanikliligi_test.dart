// AquaGuard - Yeniden Baslatma Dayanikliligi Testi (G7)
//
// Bir tedavi surerken uygulama OS tarafindan (bellek baskisi vb.) kapatilip
// yeniden acilirsa, devam eden tedavinin baslangic zamaninin ve son bilinen
// okumanin dogru geri yuklendigini dogrular. Bu, sadece kod var oldugu icin
// "calisiyor" varsayilan bir davranistir -- daha once bunu dogrudan
// dogrulayan bir test YOKTU.
//
// ONEMLI KESIF: bu garanti SADECE gercek MQTT modunda gecerlidir. Demo
// Modu'nda CihazIletisimProvider.baslat(), SimulasyonServisi.baslat()'i
// cagirir -- o da ILK veriyi HEMEN (kullanici beklemesin diye, bkz. o
// dosyanin kendi yorumu) her zon icin YENIDEN, SIFIRDAN bir rastgele
// senaryoyla uretir; bu, HANGI son okuma/tedavi durumu kalici depoda
// olursa olsun ANINDA UZERINE YAZAR. Bu demo modu icin KASITLI/DOGRU bir
// tasarim (her soguk baslangicta temiz bir demo) -- ama bu yuzden test
// demoModuAktif=false ile (gercek donanim senaryosunu temsilen) yazildi;
// aksi halde test, restorasyon mantigini DEGIL, demo modunun sifirlama
// davranisini olcerdi.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/repositories/drift_sensor_okuma_repository.dart';
import 'package:aquaguard_mobile/services/veritabani.dart';

SensorOkuma _okuma({
  required int zone,
  required DateTime zaman,
  required TedaviTuru tedaviAktif,
}) {
  return SensorOkuma(
    zaman: zaman,
    zone: zone,
    ph: 7,
    ec: 1.2,
    orp: 300,
    turbidite: 5,
    debi: 4,
    deltaBasinc: 0.1,
    durum: TeshisDurumu.tespitEdildi,
    tikanmaTuru: TikanmaTuru.biyolojik,
    guven: 100,
    tedaviAktif: tedaviAktif,
    durulamaAktif: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Demo Modu KAPALI -- bkz. dosya basi notu: gercek donanim senaryosunu
  // temsil eder, CihazIletisimProvider.baslat() bu durumda MQTT'ye
  // baglanmayi DENER; zon geri yukleme dongusu bundan ONCE calisir, sonucu
  // ETKILEMEZ. Host/port BILEREK 127.0.0.1:1 (localhost, dinleyen YOK) --
  // varsayilan test.mosquitto.org GERCEK bir ag baglantisi kurardi (bu
  // testte GOZLEMLENDI: baglanti GERCEKTEN basarili oldu) -- bu, ucuncu
  // parti bir servise bagimli, CI'da FLAKY olabilecek bir test riskiydi
  // (bkz. proje gecmisindeki CI krizi). localhost'ta hicbir sey
  // dinlemiyorsa baglanti ANINDA (agdan BAGIMSIZ) reddedilir.
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'aquaguard_demo_modu_acik': false,
      'aquaguard_mqtt_host': '127.0.0.1',
      'aquaguard_mqtt_port': 1,
    }),
  );

  test(
    'tedavi surerken uygulama kapanip acilirsa, tedavi baslangici ve son '
    'okuma dogru geri yuklenir',
    () async {
      final veritabani = AquaGuardVeritabani.test(NativeDatabase.memory());
      final tedaviBaslangici = DateTime(2026, 9, 18, 10, 30);
      final tedaviOkumasi = _okuma(
        zone: 2,
        zaman: tedaviBaslangici,
        tedaviAktif: TedaviTuru.klorEnjeksiyon,
      );

      // "Onceki oturum": zon 2'de bir tedavi surerken uygulama kapanmis --
      // hem gecmis (bos OLMAMALI, aksi halde baslat() bunu "ilk kurulum"
      // sanip sentetik veriyle EZER) hem son okuma kalici depoda.
      final sensorDepo = DriftSensorOkumaRepository(veritabani);
      await sensorDepo.gecmisiTopluKaydet(2, [tedaviOkumasi]);
      await sensorDepo.sonOkumayiKaydet(tedaviOkumasi);

      final durum1 = UygulamaDurumu(veritabani: veritabani);
      await durum1.baslat();

      expect(durum1.tedaviBaslangicZamani(2), tedaviBaslangici);
      expect(durum1.sonOkuma(2)?.tedaviAktif, TedaviTuru.klorEnjeksiyon);

      // Uygulama "kapanir" -- SADECE bellek-ici durum kaybolur, PAYLASILAN
      // veritabani (OS'in dosya sistemi gibi) KALICI kalir.
      durum1.dispose();

      final durum2 = UygulamaDurumu(veritabani: veritabani);
      await durum2.baslat();

      expect(
        durum2.tedaviBaslangicZamani(2),
        tedaviBaslangici,
        reason: 'Yeniden acilista tedavi baslangic zamani AYNEN korunmali',
      );
      expect(durum2.sonOkuma(2)?.tedaviAktif, TedaviTuru.klorEnjeksiyon);

      durum2.dispose();
      await veritabani.close();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'tedavi surmeyen bir zon icin, yeniden acilista tedavi baslangici HALA null olur',
    () async {
      final veritabani = AquaGuardVeritabani.test(NativeDatabase.memory());
      final normalOkuma = _okuma(
        zone: 3,
        zaman: DateTime(2026, 9, 18, 9),
        tedaviAktif: TedaviTuru.yok,
      );

      final sensorDepo = DriftSensorOkumaRepository(veritabani);
      await sensorDepo.gecmisiTopluKaydet(3, [normalOkuma]);
      await sensorDepo.sonOkumayiKaydet(normalOkuma);

      final durum = UygulamaDurumu(veritabani: veritabani);
      await durum.baslat();

      expect(durum.tedaviBaslangicZamani(3), isNull);

      durum.dispose();
      await veritabani.close();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'Demo Modu ACIKKEN yeniden baslatma, tedavi durumunu KORUMAZ (bilinen/kasitli davranis)',
    () async {
      // Bu test, yukaridaki dosya basi "ONEMLI KESIF" notunu KANITLAR --
      // yanlislikla "duzeltilip" demo modunun da kalici olmasi beklenirse
      // (ki bu Demo Modu'nun kendi amacina aykiridir) burada YAKALANIR.
      final veritabaniDemo = AquaGuardVeritabani.test(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({'aquaguard_demo_modu_acik': true});

      final tedaviOkumasi = _okuma(
        zone: 2,
        zaman: DateTime(2026, 9, 18, 10, 30),
        tedaviAktif: TedaviTuru.klorEnjeksiyon,
      );
      final sensorDepo = DriftSensorOkumaRepository(veritabaniDemo);
      await sensorDepo.gecmisiTopluKaydet(2, [tedaviOkumasi]);
      await sensorDepo.sonOkumayiKaydet(tedaviOkumasi);

      final durum = UygulamaDurumu(veritabani: veritabaniDemo);
      await durum.baslat();

      expect(
        durum.tedaviBaslangicZamani(2),
        isNull,
        reason:
            'Demo Modu, ilk veriyi ANINDA (SimulasyonServisi.baslat()) '
            'sifirdan uretir -- bu KASITLI/BEKLENEN bir davranistir',
      );

      durum.dispose();
      await veritabaniDemo.close();
    },
  );
}
