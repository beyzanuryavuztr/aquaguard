// AquaGuard - UygulamaDurumu.durumOzetiHesapla Testleri
//
// Genel Bakış ve Zon Dashboard ekranlarinin ikisinin de dayandigi paylasilan
// ozet mantigi (bkz. feedback: "Schema single source of truth" -- ayni
// mantigin iki yerde kopyalanmasi onceden bir hataya sebep olmustu).
// Bu mantik icin hic testi yoktu.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('durumOzetiHesapla', () {
    test('baslatilmamis (veri gelmemis) zonlar cevrimdisi sayilir', () {
      final durum = UygulamaDurumu();

      final ozet = durum.durumOzetiHesapla([1, 2, 3]);

      expect(ozet.cevrimdisi, 3);
      expect(ozet.normal, 0);
      expect(ozet.belirsiz, 0);
      expect(ozet.tespitEdildi, 0);
      expect(ozet.tedavide, 0);
    });

    test('bos zon listesi icin tum sayaçlar 0 olur', () {
      final durum = UygulamaDurumu();
      final ozet = durum.durumOzetiHesapla(const []);

      expect(ozet.normal + ozet.belirsiz + ozet.tespitEdildi + ozet.tedavide + ozet.cevrimdisi, 0);
    });

    test('demo modu basladiktan sonra her zon TAM OLARAK bir kovaya duser (cift sayim yok)', () async {
      SharedPreferences.setMockInitialValues({});
      final durum = UygulamaDurumu();

      await durum.baslat(); // varsayilan: demo modu acik, 3 tarla / 6 zon

      final ozet = durum.durumOzetiHesapla(durum.tumZonNumaralari);
      final toplam = ozet.normal + ozet.belirsiz + ozet.tespitEdildi + ozet.tedavide + ozet.cevrimdisi;

      expect(durum.tumZonNumaralari.length, 6);
      expect(toplam, 6, reason: 'her zon tam olarak bir durum kovasina dusmeli');
      // Demo modu baslar baslamaz tum zonlari "cevrimici=true" isaretler.
      expect(ozet.cevrimdisi, 0);

      durum.dispose(); // simulasyon zamanlayicisini durdur (pending timer onlemek icin)
    });
  });
}
