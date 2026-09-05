// AquaGuard - PIN Korumasi Testleri (Oncelik 10)
//
// UygulamaDurumu'nun PIN acma/kapama, dogru/yanlis deneme ve 3 basarisiz
// denemeden sonraki 30 saniyelik giris kilidi mantigini dogrular.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('varsayilan olarak PIN korumasi kapali ve oturum kilitli DEGIL', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.pinKorumasiAktif, isFalse);
    expect(durum.pinKilitliSuAn, isFalse);

    durum.dispose();
  });

  test(
    'pinKorumasiniAc sonrasi PIN kaydedilir ve kalici olarak korunur (yeniden acilista)',
    () async {
      final durum1 = UygulamaDurumu();
      await durum1.baslat();
      await durum1.pinKorumasiniAc('1234');
      expect(durum1.pinKorumasiAktif, isTrue);
      durum1.dispose();

      final durum2 = UygulamaDurumu();
      await durum2.baslat();
      expect(durum2.pinKorumasiAktif, isTrue);
      // Yeni acilista oturum yeniden kilitli olmali.
      expect(durum2.pinKilitliSuAn, isTrue);

      durum2.dispose();
    },
  );

  // NOT: pinKorumasiniAc() CANLI bir oturumda cagrildiginda oturumu ANINDA
  // KILITLEMEZ (kotu UX olurdu -- PIN'i az once belirleyen kullanici
  // kendini disari atilmis bulmamali). Kilit sadece bir SONRAKI SOGUK
  // acilista devreye girer (bkz. baslat()'ta _pinKilitliSuAn = _pinKorumasiAktif).
  // Bu yuzden asagidaki testler PIN'i BIR ONCEKI oturumda acip, IKINCI
  // (yeni) bir UygulamaDurumu ornegiyle soguk acilisi simule eder.
  test('dogru PIN denemesi oturum kilidini acar', () async {
    final oncekiOturum = UygulamaDurumu();
    await oncekiOturum.baslat();
    await oncekiOturum.pinKorumasiniAc('1234');
    oncekiOturum.dispose();

    final durum = UygulamaDurumu();
    await durum.baslat();
    expect(durum.pinKilitliSuAn, isTrue);

    final basarili = await durum.pinDenemesiYap('1234');

    expect(basarili, isTrue);
    expect(durum.pinKilitliSuAn, isFalse);

    durum.dispose();
  });

  test('yanlis PIN denemesi oturumu kilitli birakir', () async {
    final oncekiOturum = UygulamaDurumu();
    await oncekiOturum.baslat();
    await oncekiOturum.pinKorumasiniAc('1234');
    oncekiOturum.dispose();

    final durum = UygulamaDurumu();
    await durum.baslat();

    final basarili = await durum.pinDenemesiYap('9999');

    expect(basarili, isFalse);
    expect(durum.pinKilitliSuAn, isTrue);

    durum.dispose();
  });

  test(
    '3 basarisiz denemeden sonra 30 saniyelik giris kilidi baslar, 4. deneme reddedilir',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      await durum.pinKorumasiniAc('1234');

      expect(durum.pinGirisiKilitliMi, isFalse);
      await durum.pinDenemesiYap('0000');
      await durum.pinDenemesiYap('0000');
      await durum.pinDenemesiYap('0000');

      expect(durum.pinGirisiKilitliMi, isTrue);
      expect(durum.pinKilidiKalanSure, isNotNull);
      expect(durum.pinKilidiKalanSure!.inSeconds, greaterThan(0));
      expect(durum.pinKilidiKalanSure!.inSeconds, lessThanOrEqualTo(30));

      // Giris kilitliyken DOGRU PIN bile kabul edilmemeli.
      final dogruAmaKilitli = await durum.pinDenemesiYap('1234');
      expect(dogruAmaKilitli, isFalse);

      durum.dispose();
    },
  );

  test('pinKorumasiniKapat PIN korumasini kalici olarak kapatir', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.pinKorumasiniAc('1234');
    await durum1.pinKorumasiniKapat();
    expect(durum1.pinKorumasiAktif, isFalse);
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.pinKorumasiAktif, isFalse);
    expect(durum2.pinKilitliSuAn, isFalse);
    durum2.dispose();
  });

  test('pinKilidiniBiyometrikIleAc oturum kilidini acar', () async {
    final oncekiOturum = UygulamaDurumu();
    await oncekiOturum.baslat();
    await oncekiOturum.pinKorumasiniAc('1234');
    oncekiOturum.dispose();

    final durum = UygulamaDurumu();
    await durum.baslat();
    expect(durum.pinKilitliSuAn, isTrue);

    durum.pinKilidiniBiyometrikIleAc();

    expect(durum.pinKilitliSuAn, isFalse);

    durum.dispose();
  });
}
