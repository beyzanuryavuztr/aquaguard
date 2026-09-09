// AquaGuard - Kullanici Profili Testleri (Faz 3)
//
// KullaniciProfili modelinin serilestirme round-trip'ini ve
// UygulamaDurumu.kullaniciProfiliniGuncelle()'nin gercekten kalici
// depoya yazip bir sonraki baslat()'ta geri yuklendigini dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/kullanici_profili.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('KullaniciProfili model', () {
    test('varsayilan degerler bos string', () {
      const profil = KullaniciProfili();
      expect(profil.isim, isEmpty);
      expect(profil.isletmeAdi, isEmpty);
      expect(profil.telefon, isEmpty);
    });

    test('toJson -> fromJson tum alanlari korur', () {
      const profil = KullaniciProfili(
        isim: 'Beyzanur Yavuz',
        isletmeAdi: 'Ana Çiftlik',
        telefon: '0555 000 00 00',
      );

      final geriYuklenen = KullaniciProfili.fromJson(profil.toJson());

      expect(geriYuklenen.isim, profil.isim);
      expect(geriYuklenen.isletmeAdi, profil.isletmeAdi);
      expect(geriYuklenen.telefon, profil.telefon);
    });

    test('kopyalaVeGuncelle sadece verilen alanlari degistirir', () {
      const profil = KullaniciProfili(isim: 'A', isletmeAdi: 'B', telefon: 'C');
      final guncellenen = profil.kopyalaVeGuncelle(isim: 'Yeni');

      expect(guncellenen.isim, 'Yeni');
      expect(guncellenen.isletmeAdi, 'B');
      expect(guncellenen.telefon, 'C');
    });

    test('eksik alanli JSON icin bos string varsayilana doner', () {
      final profil = KullaniciProfili.fromJson(const {'isim': 'Sadece Isim'});
      expect(profil.isim, 'Sadece Isim');
      expect(profil.isletmeAdi, isEmpty);
      expect(profil.telefon, isEmpty);
    });
  });

  group('UygulamaDurumu entegrasyonu', () {
    test('kullaniciProfiliniGuncelle degeri gunceller ve bildirir', () async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      expect(durum.kullaniciProfili.isim, isEmpty);

      await durum.kullaniciProfiliniGuncelle(
        const KullaniciProfili(isim: 'Beyzanur', isletmeAdi: 'Ana Çiftlik'),
      );

      expect(durum.kullaniciProfili.isim, 'Beyzanur');
      expect(durum.kullaniciProfili.isletmeAdi, 'Ana Çiftlik');

      durum.dispose();
    });

    test('profil kalici depodan yeniden baslatilinca geri yuklenir', () async {
      final ilkOturum = UygulamaDurumu();
      await ilkOturum.baslat();
      await ilkOturum.kullaniciProfiliniGuncelle(
        const KullaniciProfili(
          isim: 'Beyzanur',
          isletmeAdi: 'Ana Çiftlik',
          telefon: '0555 000 00 00',
        ),
      );
      ilkOturum.dispose();

      final ikinciOturum = UygulamaDurumu();
      await ikinciOturum.baslat();

      expect(ikinciOturum.kullaniciProfili.isim, 'Beyzanur');
      expect(ikinciOturum.kullaniciProfili.isletmeAdi, 'Ana Çiftlik');
      expect(ikinciOturum.kullaniciProfili.telefon, '0555 000 00 00');

      ikinciOturum.dispose();
    });
  });
}
