// AquaGuard - acilDurdurmaTetikle Testleri (Oncelik 3: Acil Durdurma)
//
// Tum aktif tedavileri durdurdugunu, HENUZ kapali olmayan tum zonlarin
// vanasini kapattigini, ZATEN kapali olan bir zonu "yeni kapatilan"
// listesine EKLEMEDIGINI (Geri Al sadece BU cagriyla kapatilanlari
// acmali) ve tek bir konsolide aktivite kaydi + bildirim urettigini
// dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'tum zonlarin vanasini kapatir, aktivite gecmisine TEK konsolide kayit ekler',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final oncekiUzunluk = durum.aktiviteGecmisi.length;

      final yeniKapatilanlar = await durum.acilDurdurmaTetikle();

      expect(yeniKapatilanlar.toSet(), durum.tumZonNumaralari.toSet());
      for (final zon in durum.tumZonNumaralari) {
        expect(durum.sulamasiDurduruldu(zon), isTrue);
      }
      expect(durum.aktiviteGecmisi.length, oncekiUzunluk + 1);
      expect(durum.aktiviteGecmisi.first.tur, AktiviteTuru.manuelMudahale);
      expect(durum.aktiviteGecmisi.first.mesaj, contains('ACİL DURDURMA'));

      durum.dispose();
    },
  );

  test(
    'zaten kapali olan bir zon "yeni kapatilanlar" listesine dahil edilmez',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      await durum.sulamayiDurdur(1); // 1'i onceden kapat

      final yeniKapatilanlar = await durum.acilDurdurmaTetikle();

      expect(yeniKapatilanlar.contains(1), isFalse);
      expect(yeniKapatilanlar.contains(2), isTrue);

      durum.dispose();
    },
  );

  test(
    'geri al (sulamayiBaslat) ile yeni kapatilan zonlar tekrar acilabilir',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      final yeniKapatilanlar = await durum.acilDurdurmaTetikle();
      for (final zon in yeniKapatilanlar) {
        await durum.sulamayiBaslat(zon);
      }

      for (final zon in yeniKapatilanlar) {
        expect(durum.sulamasiDurduruldu(zon), isFalse);
      }

      durum.dispose();
    },
  );

  test('iki kez ust uste cagirmak hicbir zonu iki kere "yeni kapatilan" saymaz', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.acilDurdurmaTetikle();
    final ikinciCagriYeniKapatilanlar = await durum.acilDurdurmaTetikle();

    expect(ikinciCagriYeniKapatilanlar, isEmpty);

    durum.dispose();
  });
}
