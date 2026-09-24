// AquaGuard - Sulama Kontrolu (Ana Vana) Testleri
//
// Operatorun bir zonun ana vanasini teshis akisindan BAGIMSIZ olarak manuel
// durdurup baslatabildigini dogrular (bkz. providers/uygulama_durumu.dart
// sulamayiDurdur/sulamayiBaslat, services/simulasyon_servisi.dart
// sulamayiDuraklat/sulamayiDevamEttir).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/config/ayarlar_sabitleri.dart';
import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/services/simulasyon_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulasyonServisi sulama duraklatma', () {
    test('duraklatilan zon icin yeni veri uretilmez, digerleri devam eder', () async {
      final uretilenZonlar = <int>[];
      final servis = SimulasyonServisi(
        zonlar: [1, 2],
        veriUretildiginde: (okuma) => uretilenZonlar.add(okuma.zone),
      );
      servis.baslat(aralik: const Duration(milliseconds: 20));
      uretilenZonlar.clear();

      servis.sulamayiDuraklat(1);
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(uretilenZonlar, isNot(contains(1)));
      expect(uretilenZonlar, contains(2));

      servis.durdur();
    });

    test('devam ettirilen zon tekrar veri uretmeye baslar', () async {
      final uretilenZonlar = <int>[];
      final servis = SimulasyonServisi(
        zonlar: [1],
        veriUretildiginde: (okuma) => uretilenZonlar.add(okuma.zone),
      );
      servis.baslat(aralik: const Duration(milliseconds: 20));

      servis.sulamayiDuraklat(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      uretilenZonlar.clear();

      servis.sulamayiDevamEttir(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(uretilenZonlar, contains(1));
      servis.durdur();
    });

    test('sulamaDuraklatilmisMi durumu dogru raporlar', () {
      final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
      servis.baslat(aralik: const Duration(minutes: 5));

      expect(servis.sulamaDuraklatilmisMi(1), isFalse);
      servis.sulamayiDuraklat(1);
      expect(servis.sulamaDuraklatilmisMi(1), isTrue);
      servis.sulamayiDevamEttir(1);
      expect(servis.sulamaDuraklatilmisMi(1), isFalse);

      servis.durdur();
    });
  });

  group('UygulamaDurumu sulama kontrolu (entegrasyon)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('sulamayiDurdur: sulamasiDurduruldu true doner ve aktivite kaydi ekler', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      expect(durum.sulamasiDurduruldu(1), isFalse);
      await durum.sulamayiDurdur(1);

      expect(durum.sulamasiDurduruldu(1), isTrue);
      expect(durum.aktiviteGecmisi.first.tur, AktiviteTuru.manuelMudahale);
      expect(durum.aktiviteGecmisi.first.mesaj, contains('ana vana'));

      durum.dispose();
    });

    test('sulamayiBaslat: sulamasiDurduruldu tekrar false olur', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await durum.sulamayiDurdur(1);
      await durum.sulamayiBaslat(1);

      expect(durum.sulamasiDurduruldu(1), isFalse);

      durum.dispose();
    });

    test('zaten durdurulmus bir zonu tekrar durdurmak ikinci bir kayit eklemez', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await durum.sulamayiDurdur(1);
      final uzunlukIlkDurdurmadanSonra = durum.aktiviteGecmisi.length;
      await durum.sulamayiDurdur(1); // zaten durdurulmus -- no-op olmali

      expect(durum.aktiviteGecmisi.length, uzunlukIlkDurdurmadanSonra);

      durum.dispose();
    });

    test('durdurulmus zonda demo verisi dondurulur (yeni okuma gelmez)', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await durum.sulamayiDurdur(1);
      final durdurulduAndakiOkuma = durum.sonOkuma(1);

      await Future<void>.delayed(const Duration(milliseconds: 3500));

      expect(durum.sonOkuma(1), same(durdurulduAndakiOkuma));

      durum.dispose();
    });

    test('sulama durumu, baslat() sonrasi kalici depodan geri yuklenir', () async {
      final durum1 = UygulamaDurumu();
      await durum1.baslat();
      await durum1.sulamayiDurdur(3);
      durum1.dispose();

      final durum2 = UygulamaDurumu();
      await durum2.baslat();
      expect(durum2.sulamasiDurduruldu(3), isTrue);
      durum2.dispose();
    });
  });

  group(
    'UygulamaDurumu sulamayiSureliBaslat (uzaktan/sureli sulama, 2026-09-24)',
    () {
      setUp(() => SharedPreferences.setMockInitialValues({}));

      test('durdurulmus bir zonu sureyle baslatir, aktivite kaydi dakikayi icerir', () async {
        final durum = UygulamaDurumu();
        await durum.baslat();
        await durum.sulamayiDurdur(2);

        final basarili = await durum.sulamayiSureliBaslat(2, 20);

        expect(basarili, isTrue);
        expect(durum.sulamasiDurduruldu(2), isFalse);
        expect(durum.aktiviteGecmisi.first.tur, AktiviteTuru.manuelMudahale);
        expect(durum.aktiviteGecmisi.first.mesaj, contains('20 dakika'));

        durum.dispose();
      });

      test(
        'sulamayiBaslat\'tan farkli olarak, zon ONCEDEN durdurulmamis '
        'olsa BILE calisir (yeni bir baslatma eylemidir)',
        () async {
          final durum = UygulamaDurumu();
          await durum.baslat();
          // Zon 1 zaten acik (varsayilan) -- sulamayiBaslat() bu durumda
          // no-op olurdu, ama sulamayiSureliBaslat calismali.
          expect(durum.sulamasiDurduruldu(1), isFalse);

          final basarili = await durum.sulamayiSureliBaslat(1, 15);

          expect(basarili, isTrue);
          expect(durum.aktiviteGecmisi.first.mesaj, contains('15 dakika'));

          durum.dispose();
        },
      );

      test('0 veya negatif dakika suresiz baslatma olarak islenir', () async {
        final durum = UygulamaDurumu();
        await durum.baslat();

        await durum.sulamayiSureliBaslat(1, 0);

        expect(
          durum.aktiviteGecmisi.first.mesaj,
          contains('yeniden başlattı'),
        );
        expect(durum.aktiviteGecmisi.first.mesaj, isNot(contains('dakika süreli')));

        durum.dispose();
      });

      test(
        'asiri uzun sure (SULAMA_MAKS_SURE_DK ustu) kirpilir, aktivite '
        'kaydinda KIRPILMIS deger gorunur',
        () async {
          final durum = UygulamaDurumu();
          await durum.baslat();

          await durum.sulamayiSureliBaslat(1, 5000);

          expect(
            durum.aktiviteGecmisi.first.mesaj,
            contains('${AyarlarSabitleri.sulamaMaksSureDakika} dakika'),
          );

          durum.dispose();
        },
      );
    },
  );
}
