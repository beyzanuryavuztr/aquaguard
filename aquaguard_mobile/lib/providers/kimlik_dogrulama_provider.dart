/// AquaGuard - Kimlik Doğrulama Provider
/// ==========================================
///
/// Amaç:
///   `KimlikDogrulamaServisi`nin oturum durumunu (kullanıcı/yükleniyor/
///   hata) UI'a taşır. Firebase HENÜZ yapılandırılmadıysa (bkz.
///   config/firebase_secenekleri.dart) servis hiç oluşturulmaz --
///   [girisGerekliMi] her zaman false döner, uygulama Firebase hiç
///   eklenmemiş gibi davranır. Bu sayede Beyzanur gerçek bir Firebase
///   projesi kuruncaya kadar mevcut akış (Onboarding -> Giriş Ekranı)
///   HİÇ değişmez, hiçbir test/derleme kırılmaz.
///
/// Tarih:  2026-09-25
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/firebase_secenekleri.dart';
import '../services/kimlik_dogrulama_servisi.dart';

class KimlikDogrulamaProvider extends ChangeNotifier {
  final KimlikDogrulamaServisi? _servis;
  StreamSubscription<KullaniciBilgisi?>? _abonelik;

  KullaniciBilgisi? _kullanici;
  bool _yukleniyor = false;
  String? _hataMesaji;
  // Operatör "Misafir olarak devam et" derse, oturum kapalı kalsa bile
  // giriş ekranı tekrar gösterilmez (bkz. dosya başı notu -- jüri
  // demosunu saha ağ sorunlarına karşı korur).
  bool _misafirOlarakDevamEdildi = false;

  KimlikDogrulamaProvider({KimlikDogrulamaServisi? servis})
    : _servis = servis ??
          (firebaseYapilandirildiMi ? FirebaseKimlikDogrulamaServisi() : null) {
    if (_servis != null) {
      _kullanici = _servis.mevcutKullanici;
      _abonelik = _servis.kullaniciDegisiklikleri.listen((k) {
        _kullanici = k;
        notifyListeners();
      });
    }
  }

  /// Firebase hiç yapılandırılmadıysa (yer tutucu değerler) DAİMA false --
  /// giriş/kayıt ekranı hiçbir zaman gösterilmez.
  bool get girisGerekliMi =>
      _servis != null && _kullanici == null && !_misafirOlarakDevamEdildi;

  KullaniciBilgisi? get kullanici => _kullanici;
  bool get yukleniyor => _yukleniyor;
  String? get hataMesaji => _hataMesaji;

  Future<bool> kayitOl(String eposta, String sifre) =>
      _islemYap(() => _servis!.kayitOl(eposta, sifre));

  Future<bool> girisYap(String eposta, String sifre) =>
      _islemYap(() => _servis!.girisYap(eposta, sifre));

  Future<bool> _islemYap(Future<KullaniciBilgisi> Function() eylem) async {
    if (_servis == null) return false;
    _yukleniyor = true;
    _hataMesaji = null;
    notifyListeners();
    try {
      _kullanici = await eylem();
      return true;
    } on KimlikDogrulamaHatasi catch (e) {
      _hataMesaji = e.turkceMesaj;
      return false;
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  void misafirOlarakDevamEt() {
    _misafirOlarakDevamEdildi = true;
    notifyListeners();
  }

  Future<void> cikisYap() async {
    await _servis?.cikisYap();
    // _kullaniciDegisiklikleri akışına GÜVENMEDEN doğrudan temizle --
    // gerçek Firebase'de signOut() sonrası akış da null yayınlar ama bu,
    // sahte/test servislerinde (veya akış henüz tetiklenmeden bu getter
    // okunursa) garanti değildir; kayitOl/girisYap ile AYNI disiplin
    // (orada da _kullanici doğrudan atanıyor, akışa bel bağlanmıyor).
    _kullanici = null;
    _misafirOlarakDevamEdildi = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _abonelik?.cancel();
    super.dispose();
  }
}
