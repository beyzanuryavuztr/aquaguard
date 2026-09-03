// AquaGuard - AsistanServisi (Akilli Asistan) Testleri
//
// Kural tabanli niyet (intent) eslesmesinin CANLI UygulamaDurumu verisine
// gore dogru yanitlar urettigini dogrular. LLM/harici API kullanilmadigi
// icin (bkz. asistan_servisi.dart dosya basi aciklamasi) bu testler
// tamamen deterministiktir.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/services/asistan_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UygulamaDurumu durum;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    durum = UygulamaDurumu();
    await durum.baslat(); // varsayilan: demo modu, 3 tarla / 6 zon
  });

  tearDown(() => durum.dispose());

  group('selamlama ve yardim', () {
    test('merhaba selamlama yaniti dondurur', () {
      final yanit = AsistanServisi.yanitUret('Merhaba', durum);
      expect(yanit, contains('Merhaba'));
    });

    test('bos soru ornek soru onerir', () {
      final yanit = AsistanServisi.yanitUret('', durum);
      expect(yanit, contains('genel durum'));
    });

    test('"yardım" tum ornek sorulari listeler', () {
      final yanit = AsistanServisi.yanitUret('ne sorabilirim', durum);
      for (final ornek in AsistanServisi.ornekSorular) {
        expect(yanit, contains(ornek));
      }
    });

    test('anlasilmayan soru icin yardimci fallback doner', () {
      final yanit = AsistanServisi.yanitUret('asdkfjhaskdjfh', durum);
      expect(yanit, contains('anlayamadım'));
    });
  });

  group('genel durum sorgusu', () {
    test('"genel durum nasıl" tum zonlarin ozetini verir (6 zon)', () {
      final yanit = AsistanServisi.yanitUret('genel durum nasıl?', durum);
      // Demo modu basladiktan hemen sonra tum zonlar normal olmali.
      expect(yanit, contains('6 zon normal'));
    });

    test('buyuk/kucuk harf ve Turkce karakter farkina duyarli DEGIL', () {
      final y1 = AsistanServisi.yanitUret('GENEL DURUM NASIL', durum);
      final y2 = AsistanServisi.yanitUret('genel durum nasıl', durum);
      expect(y1, y2);
    });
  });

  group('zon sorgusu', () {
    test('"zon 1 nasıl" o zonun durumunu doner', () {
      final yanit = AsistanServisi.yanitUret('zon 1 nasıl?', durum);
      expect(yanit, contains('Zon 1'));
    });

    test('var olmayan zon numarasi icin acik hata mesaji doner', () {
      final yanit = AsistanServisi.yanitUret('zon 999 nasıl?', durum);
      expect(yanit, contains('bulamadım'));
    });

    test('"zon3" (bosluksuz) da eslesir', () {
      final yanit = AsistanServisi.yanitUret('zon3 durumu', durum);
      expect(yanit, contains('Zon 3'));
    });
  });

  group('tedavi sayilari sorgusu', () {
    // NOT: baslat() ilk kurulumda her zon icin 12 gunluk sentetik GECMIS
    // veri ureteceginden (bkz. GecmisVeriUreticisi), "hic tedavi yok"
    // durumu demo modunda pratikte HIC gerceklesmez -- gercek davranisi
    // dogrulariz: toplam sayi tutarli ve turlere gore dokum var.
    test('gecmisten uretilen tedavi sayilarini turlere gore dokerek raporlar', () {
      final yanit = AsistanServisi.yanitUret('kaç tedavi yapıldı?', durum);
      final beklenenToplam = durum.tedaviSayaclari.values.fold(0, (a, b) => a + b);
      expect(beklenenToplam, greaterThan(0));
      expect(yanit, contains('$beklenenToplam tedavi uygulandı'));
      expect(yanit, contains('asit dozlama'));
      expect(yanit, contains('klor enjeksiyonu'));
      expect(yanit, contains('yüksek basınçlı yıkama'));
    });
  });

  group('en yaygin tur sorgusu', () {
    // Ayni sekilde: seed edilmis gecmis veri zaten tespit olaylari icerir.
    test('gecmisten uretilen tespitlerin en yaygin turunu yuzdeyle raporlar', () {
      final yanit = AsistanServisi.yanitUret(
        'en çok hangi tür tıkanma görülüyor?',
        durum,
      );
      expect(yanit, contains('en yaygını'));
      expect(yanit, matches(RegExp(r'%\d+')));
    });
  });

  group('cevrimdisi sorgusu', () {
    test('demo modunda tum zonlar cevrimici, "yok" doner', () {
      final yanit = AsistanServisi.yanitUret('çevrimdışı zon var mı?', durum);
      expect(yanit, contains('çevrimdışı zon yok'));
    });
  });

  group('sulama sorgusu', () {
    test('hicbir zon durdurulmamisken "yok" doner', () {
      final yanit = AsistanServisi.yanitUret('sulama durumu nedir?', durum);
      expect(yanit, contains('manuel olarak durdurulmuş sulama yok'));
    });

    test('bir zon durdurulunca listede gorunur', () async {
      await durum.sulamayiDurdur(2);
      final yanit = AsistanServisi.yanitUret('hangi zonlarda sulama durduruldu?', durum);
      expect(yanit, contains('Zon 2'));
    });

    test('zon detay sorgusunda sulama durdurulmus uyarisi da gorunur', () async {
      await durum.sulamayiDurdur(4);
      final yanit = AsistanServisi.yanitUret('zon 4 nasıl?', durum);
      expect(yanit, contains('sulaması operatör tarafından durduruldu'));
    });
  });

  group('tarla/zon sayisi sorgusu', () {
    test('"kaç tarla var" varsayilan 3 tarla / 6 zonu dogru raporlar', () {
      final yanit = AsistanServisi.yanitUret('kaç tarlam var?', durum);
      expect(yanit, contains('3 tarlanız'));
      expect(yanit, contains('6 izlenen zonunuz'));
    });
  });
}
