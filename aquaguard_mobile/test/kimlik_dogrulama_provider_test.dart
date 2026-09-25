// AquaGuard - KimlikDogrulamaProvider Testleri
//
// Gercek Firebase'e HIC cikmaz -- KimlikDogrulamaServisi arayuzunu
// uygulayan sahte (in-memory) bir servis enjekte edilir (bkz.
// hava_durumu_servisi_test.dart'taki MockClient deseniyle AYNI disiplin).

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/providers/kimlik_dogrulama_provider.dart';
import 'package:aquaguard_mobile/services/kimlik_dogrulama_servisi.dart';

class _SahteKimlikDogrulamaServisi implements KimlikDogrulamaServisi {
  KullaniciBilgisi? _kullanici;
  final bool girisBasarisizMi;

  _SahteKimlikDogrulamaServisi({this.girisBasarisizMi = false});

  @override
  KullaniciBilgisi? get mevcutKullanici => _kullanici;

  @override
  Stream<KullaniciBilgisi?> get kullaniciDegisiklikleri => const Stream.empty();

  @override
  Future<KullaniciBilgisi> kayitOl(String eposta, String sifre) async {
    _kullanici = KullaniciBilgisi(uid: 'sahte-uid', eposta: eposta);
    return _kullanici!;
  }

  @override
  Future<KullaniciBilgisi> girisYap(String eposta, String sifre) async {
    if (girisBasarisizMi) {
      throw const KimlikDogrulamaHatasi('E-posta veya şifre hatalı.');
    }
    _kullanici = KullaniciBilgisi(uid: 'sahte-uid', eposta: eposta);
    return _kullanici!;
  }

  @override
  Future<void> cikisYap() async {
    _kullanici = null;
  }
}

void main() {
  group('KimlikDogrulamaProvider - Firebase yapılandırılmadıysa', () {
    test('girisGerekliMi HER ZAMAN false döner (servis=null)', () {
      final provider = KimlikDogrulamaProvider(servis: null);
      expect(provider.girisGerekliMi, isFalse);
      expect(provider.kullanici, isNull);
    });

    test('kayitOl/girisYap servis yokken sessizce false döner, istisna FIRLATMAZ', () async {
      final provider = KimlikDogrulamaProvider(servis: null);
      expect(await provider.kayitOl('a@b.com', '123456'), isFalse);
      expect(await provider.girisYap('a@b.com', '123456'), isFalse);
    });
  });

  group('KimlikDogrulamaProvider - sahte servisle', () {
    test('basarili girisOl sonrasi kullanici dolar, girisGerekliMi false olur', () async {
      final provider = KimlikDogrulamaProvider(
        servis: _SahteKimlikDogrulamaServisi(),
      );
      expect(provider.girisGerekliMi, isTrue);

      final basarili = await provider.girisYap('test@aquaguard.com', '123456');

      expect(basarili, isTrue);
      expect(provider.kullanici?.eposta, 'test@aquaguard.com');
      expect(provider.girisGerekliMi, isFalse);
      expect(provider.hataMesaji, isNull);
    });

    test('basarisiz giriste hataMesaji dolar, kullanici null kalir', () async {
      final provider = KimlikDogrulamaProvider(
        servis: _SahteKimlikDogrulamaServisi(girisBasarisizMi: true),
      );

      final basarili = await provider.girisYap('test@aquaguard.com', 'yanlis');

      expect(basarili, isFalse);
      expect(provider.kullanici, isNull);
      expect(provider.hataMesaji, 'E-posta veya şifre hatalı.');
    });

    test('kayitOl basarili olunca oturum acilir', () async {
      final provider = KimlikDogrulamaProvider(
        servis: _SahteKimlikDogrulamaServisi(),
      );

      final basarili = await provider.kayitOl('yeni@aquaguard.com', '123456');

      expect(basarili, isTrue);
      expect(provider.kullanici?.eposta, 'yeni@aquaguard.com');
    });

    test('misafirOlarakDevamEt girisGerekliMi\'yi false yapar (oturum acmadan)', () {
      final provider = KimlikDogrulamaProvider(
        servis: _SahteKimlikDogrulamaServisi(),
      );
      expect(provider.girisGerekliMi, isTrue);

      provider.misafirOlarakDevamEt();

      expect(provider.girisGerekliMi, isFalse);
      expect(provider.kullanici, isNull);
    });

    test('cikisYap sonrasi girisGerekliMi tekrar true olur', () async {
      final provider = KimlikDogrulamaProvider(
        servis: _SahteKimlikDogrulamaServisi(),
      );
      await provider.girisYap('test@aquaguard.com', '123456');
      expect(provider.girisGerekliMi, isFalse);

      await provider.cikisYap();

      expect(provider.kullanici, isNull);
      expect(provider.girisGerekliMi, isTrue);
    });
  });
}
