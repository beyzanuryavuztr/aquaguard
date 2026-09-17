// AquaGuard - HataGunluguServisi Testleri
//
// Global hata yakalamanin (main.dart -- runZonedGuarded + FlutterError.onError)
// dayandigi servisi dogrudan test eder: hatalarin bellek-ici gunluge dogru
// eklendigini, yigin izinin kirpildigini ve disa aktarim metninin dogru
// birlestirildigini dogrular. Kalici (dosya/localStorage) yazma kismi bu
// ortamda platform kanali gerektirdigi icin (bkz. kaliciYaziciyiHazirla'daki
// try/catch notu) dogrudan test edilmez -- sessizce devre disi kalmasi
// BEKLENEN davranistir, testler bunu dolayli olarak (hata firlatmadan
// calismasi) zaten dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/services/hata_gunlugu_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => HataGunluguServisi.sifirla());

  test('baslat() platform kanali olmadan bile hata firlatmaz', () async {
    await HataGunluguServisi.baslat();
    expect(HataGunluguServisi.girdiler, isEmpty);
  });

  test('logla() bellek-ici gunluge ekler', () {
    HataGunluguServisi.logla('test hatasi', null, baglam: 'Test');

    expect(HataGunluguServisi.girdiler, hasLength(1));
    expect(HataGunluguServisi.girdiler.single, contains('test hatasi'));
    expect(HataGunluguServisi.girdiler.single, contains('[Test]'));
  });

  test('logla() yigin izi verilince ozet olarak ikinci bir satir ekler', () {
    HataGunluguServisi.logla(
      'hata',
      StackTrace.fromString('satir1\nsatir2\nsatir3'),
    );

    expect(HataGunluguServisi.girdiler, hasLength(2));
    expect(HataGunluguServisi.girdiler[1], contains('satir1'));
  });

  test('bellekteki gunluk maksimum 500 girdiyle sinirlanir', () {
    for (var i = 0; i < 600; i++) {
      HataGunluguServisi.logla('hata $i', null);
    }

    expect(HataGunluguServisi.girdiler.length, lessThanOrEqualTo(500));
    // En eskiler dusurulmus, en yeniler kalmis olmali.
    expect(HataGunluguServisi.girdiler.last, contains('hata 599'));
  });

  test('metinOlarakBirlestir tum girdileri satir satir birlestirir', () {
    HataGunluguServisi.logla('birinci', null);
    HataGunluguServisi.logla('ikinci', null);

    final metin = HataGunluguServisi.metinOlarakBirlestir();

    expect(metin, contains('birinci'));
    expect(metin, contains('ikinci'));
    expect(metin.split('\n'), hasLength(2));
  });

  test('bos gunlukte metinOlarakBirlestir bos string doner', () {
    expect(HataGunluguServisi.metinOlarakBirlestir(), isEmpty);
  });
}
