// AquaGuard - Bildirim Gecmisi Testleri (Faz 2)
//
// UygulamaDurumu._aktiviteKaydiEkle() -- kategori acikken hem kuyruga hem
// KALICI bildirimGecmisi'ne eklendigini, bildirimDegerlendir:false ile
// cagrilan kayitlarin (mutex red detay logu gibi) bildirimGecmisi'ne HIC
// girmedigini, bildirimleriOkunduIsaretle()'nin okunmamis sayacini
// sifirladigini ve DepolamaServisi araciligiyla kalicilik round-trip'inin
// calistigini dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/services/depolama_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'operator eylemi (manuelMudahale) hem aktiviteGecmisi hem bildirimGecmisi\'ne girer',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      durum.bildirimleriAlVeTemizle();

      final aktiviteOncesi = durum.aktiviteGecmisi.length;
      final bildirimOncesi = durum.bildirimGecmisi.length;

      await durum.manuelNormaleDondur(1);

      expect(durum.aktiviteGecmisi.length, aktiviteOncesi + 1);
      expect(durum.bildirimGecmisi.length, bildirimOncesi + 1);
      expect(durum.bildirimGecmisi.first.mesaj, contains('yanlış alarm'));
      expect(durum.okunmamisBildirimSayisi, greaterThanOrEqualTo(1));

      durum.dispose();
    },
  );

  test(
    'mutex red detay kaydi (bildirimDegerlendir:false) aktiviteGecmisi\'ne girer ama bildirimGecmisi\'ne GIRMEZ',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      durum.bildirimleriAlVeTemizle();

      final aktiviteOncesi = durum.aktiviteGecmisi.length;
      final bildirimOncesi = durum.bildirimGecmisi.length;

      await durum.demoSenaryosuTetikle(DemoSenaryosu.mutexKilidi);

      // Mutex senaryosu 2 yeni aktivite kaydi uretir: red detay logu
      // (bildirim DEGIL) + senaryo ozeti (bildirim -- manuelMudahale).
      expect(durum.aktiviteGecmisi.length, aktiviteOncesi + 2);
      expect(durum.bildirimGecmisi.length, bildirimOncesi + 1);
      expect(
        durum.bildirimGecmisi.first.mesaj,
        isNot(contains('REDDEDİLDİ')),
      );
      expect(
        durum.aktiviteGecmisi.any((k) => k.mesaj.contains('REDDEDİLDİ')),
        isTrue,
      );

      durum.dispose();
    },
  );

  test(
    'bildirimleriOkunduIsaretle() okunmamis sayacini sifirlar',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      durum.bildirimleriAlVeTemizle();

      await durum.manuelNormaleDondur(1);
      expect(durum.okunmamisBildirimSayisi, greaterThan(0));

      await durum.bildirimleriOkunduIsaretle();
      expect(durum.okunmamisBildirimSayisi, 0);
      expect(durum.bildirimOkunmusMu(durum.bildirimGecmisi.first), isTrue);

      durum.dispose();
    },
  );

  test(
    'yeni bir bildirim, oncekiler okundu isaretlendikten SONRA bile tekrar okunmamis sayilir',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      durum.bildirimleriAlVeTemizle();

      await durum.manuelNormaleDondur(1);
      await durum.bildirimleriOkunduIsaretle();
      expect(durum.okunmamisBildirimSayisi, 0);

      await durum.manuelNormaleDondur(2);
      expect(durum.okunmamisBildirimSayisi, 1);

      durum.dispose();
    },
  );

  test(
    'bildirim gecmisi ve okunmus ID kumesi kalici depodan geri yuklenir',
    () async {
      final ilkOturum = UygulamaDurumu();
      await ilkOturum.baslat();
      ilkOturum.bildirimleriAlVeTemizle();
      await ilkOturum.manuelNormaleDondur(1);
      await ilkOturum.bildirimleriOkunduIsaretle();
      final oncekiMesaj = ilkOturum.bildirimGecmisi.first.mesaj;
      ilkOturum.dispose();

      final ikinciOturum = UygulamaDurumu();
      await ikinciOturum.baslat();

      expect(ikinciOturum.bildirimGecmisi, isNotEmpty);
      expect(ikinciOturum.bildirimGecmisi.first.mesaj, oncekiMesaj);
      expect(
        ikinciOturum.bildirimOkunmusMu(ikinciOturum.bildirimGecmisi.first),
        isTrue,
      );

      ikinciOturum.dispose();
    },
  );

  group('DepolamaServisi (dogrudan servis seviyesi round-trip)', () {
    test('bildirimGecmisiGetir/Kaydet round-trip', () async {
      final depolama = DepolamaServisi();
      final kayit = AktiviteKaydi(
        zaman: DateTime(2026, 9, 8, 10, 0),
        zone: 3,
        mesaj: 'Test bildirimi',
        tur: AktiviteTuru.tespit,
      );

      expect(await depolama.bildirimGecmisiGetir(), isEmpty);

      await depolama.bildirimGecmisiniKaydet([kayit]);
      final geriYuklenen = await depolama.bildirimGecmisiGetir();

      expect(geriYuklenen, hasLength(1));
      expect(geriYuklenen.first.mesaj, 'Test bildirimi');
      expect(geriYuklenen.first.zone, 3);
    });

    test('okunmusBildirimIdleriGetir/Kaydet round-trip', () async {
      final depolama = DepolamaServisi();

      expect(await depolama.okunmusBildirimIdleriGetir(), isEmpty);

      await depolama.okunmusBildirimIdleriniKaydet({1, 2, 12345});
      final geriYuklenen = await depolama.okunmusBildirimIdleriGetir();

      expect(geriYuklenen, {1, 2, 12345});
    });
  });
}
