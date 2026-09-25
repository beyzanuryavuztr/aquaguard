/// AquaGuard - Kimlik Doğrulama Servisi (E-posta/Şifre Hesapları)
/// ====================================================================
///
/// Amaç:
///   `KimlikDogrulamaServisi` soyut arayüzü + gerçek Firebase Auth
///   uygulaması. Provider (`KimlikDogrulamaProvider`) bu arayüze bağımlı
///   olduğu için testler gerçek Firebase'e hiç çıkmadan, sahte bir
///   uygulama enjekte ederek çalışır -- `services/hava_durumu_servisi.dart`
///   `testIstemci` deseniyle AYNI disiplin (bkz. dosya başı notu orada).
///
///   DÜRÜSTLÜK NOTU: bu hesap sistemi sadece GİRİŞ/ÇIKIŞ'ı yönetir.
///   Uygulamanın geri kalanı (çiftlikler, sensör geçmişi, ayarlar) hâlâ
///   cihaz-yerel SharedPreferences/SQLite'ta tutulur -- hesaplar arası
///   veri AYRIMI veya bulut senkronizasyonu YOKTUR. Bu bilinçli bir
///   kapsam sınırı (bkz. CHANGELOG.md), UI'da da açıkça belirtilir.
///
/// Tarih:  2026-09-25
library;

import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Sağlayıcıdan (Firebase) bağımsız, uygulama-içi minimal kullanıcı temsili.
class KullaniciBilgisi {
  final String uid;
  final String? eposta;

  const KullaniciBilgisi({required this.uid, this.eposta});
}

/// Başarısız bir giriş/kayıt denemesinde fırlatılır -- [turkceMesaj] her
/// zaman kullanıcıya doğrudan gösterilebilir, teknik olmayan bir metindir.
class KimlikDogrulamaHatasi implements Exception {
  final String turkceMesaj;
  const KimlikDogrulamaHatasi(this.turkceMesaj);

  @override
  String toString() => turkceMesaj;
}

abstract class KimlikDogrulamaServisi {
  /// Oturum durumu değiştikçe (giriş/çıkış) yayın yapar; null = oturum yok.
  Stream<KullaniciBilgisi?> get kullaniciDegisiklikleri;
  KullaniciBilgisi? get mevcutKullanici;

  Future<KullaniciBilgisi> kayitOl(String eposta, String sifre);
  Future<KullaniciBilgisi> girisYap(String eposta, String sifre);
  Future<void> cikisYap();
}

class FirebaseKimlikDogrulamaServisi implements KimlikDogrulamaServisi {
  final fb.FirebaseAuth _auth;

  FirebaseKimlikDogrulamaServisi({fb.FirebaseAuth? auth})
    : _auth = auth ?? fb.FirebaseAuth.instance;

  KullaniciBilgisi? _donustur(fb.User? kullanici) => kullanici == null
      ? null
      : KullaniciBilgisi(uid: kullanici.uid, eposta: kullanici.email);

  @override
  Stream<KullaniciBilgisi?> get kullaniciDegisiklikleri =>
      _auth.authStateChanges().map(_donustur);

  @override
  KullaniciBilgisi? get mevcutKullanici => _donustur(_auth.currentUser);

  @override
  Future<KullaniciBilgisi> kayitOl(String eposta, String sifre) async {
    try {
      final sonuc = await _auth.createUserWithEmailAndPassword(
        email: eposta,
        password: sifre,
      );
      return _donustur(sonuc.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw KimlikDogrulamaHatasi(_hataMesajiCevir(e.code));
    }
  }

  @override
  Future<KullaniciBilgisi> girisYap(String eposta, String sifre) async {
    try {
      final sonuc = await _auth.signInWithEmailAndPassword(
        email: eposta,
        password: sifre,
      );
      return _donustur(sonuc.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw KimlikDogrulamaHatasi(_hataMesajiCevir(e.code));
    }
  }

  @override
  Future<void> cikisYap() => _auth.signOut();

  /// Firebase Auth'un İngilizce hata kodlarını, operatörün doğrudan
  /// okuyabileceği Türkçe mesajlara çevirir -- en sık karşılaşılanlar
  /// (bkz. https://firebase.google.com/docs/auth/admin/errors), tanınmayan
  /// bir kod için genel ama dürüst bir mesaj döner (teknik kodu YUTMAZ,
  /// tanınmayan durumları sessizce "bilinmeyen hata" gibi göstermez).
  String _hataMesajiCevir(String kod) {
    switch (kod) {
      case 'email-already-in-use':
        return 'Bu e-posta adresiyle zaten bir hesap var. Giriş yapmayı deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf — en az 6 karakter olmalı.';
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı bir hesap bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen biraz sonra tekrar deneyin.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası — internet bağlantınızı kontrol edin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      default:
        return 'Bir hata oluştu ($kod). Lütfen tekrar deneyin.';
    }
  }
}
