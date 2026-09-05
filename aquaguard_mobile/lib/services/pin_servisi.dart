/// AquaGuard - PIN + Biyometrik Kimlik Dogrulama Servisi
/// =============================================================
///
/// Amac:
///   4 haneli PIN kodunu GUVENLI depoda (`flutter_secure_storage` --
///   Android Keystore/iOS Keychain/Windows Credential Locker/tarayicida
///   IndexedDB tabanli sifreli depo) tutar; PIN korumasinin ACIK/KAPALI
///   anahtari (hassas olmayan) `DepolamaServisi`'nde (SharedPreferences)
///   kalir -- iki farkli hassasiyet seviyesi iki farkli depoda.
///
///   `local_auth` (parmak izi/yuz tanima) SADECE Android/iOS/macOS/Windows'ta
///   desteklenir -- WEB ICIN PLATFORM UYGULAMASI YOK (pub.dev'de dogrulandi:
///   paketin federe listesinde `local_auth_web` yok). Bu yuzden
///   `biyometrikDesteklidMi()` web'de HER ZAMAN false doner -- kilit
///   ekraninda PIN her platformda calisir, biyometrik kisayolu sadece
///   destekleyen platformlarda gorunur.
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class PinServisi {
  PinServisi._();

  static const FlutterSecureStorage _guvenliDepo = FlutterSecureStorage();
  static const _pinAnahtari = 'aquaguard_pin_kodu';
  static final LocalAuthentication _biyometrik = LocalAuthentication();

  static Future<void> pinKaydet(String pin) =>
      _guvenliDepo.write(key: _pinAnahtari, value: pin);

  static Future<void> pinSil() => _guvenliDepo.delete(key: _pinAnahtari);

  static Future<bool> pinTanimliMi() async {
    final kayitli = await _guvenliDepo.read(key: _pinAnahtari);
    return kayitli != null && kayitli.isNotEmpty;
  }

  static Future<bool> pinDogrula(String girilen) async {
    final kayitli = await _guvenliDepo.read(key: _pinAnahtari);
    return kayitli != null && kayitli == girilen;
  }

  static Future<bool> biyometrikDesteklidMi() async {
    if (kIsWeb) return false;
    try {
      final destekli = await _biyometrik.isDeviceSupported();
      final kontrolEdilebilir = await _biyometrik.canCheckBiometrics;
      return destekli && kontrolEdilebilir;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> biyometrikDogrula() async {
    if (kIsWeb) return false;
    try {
      return await _biyometrik.authenticate(
        localizedReason:
            'AquaGuard kontrol paneline erişmek için kimliğinizi doğrulayın',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
