/// AquaGuard - MQTT Kimlik Bilgisi Servisi (D1)
/// ================================================
///
/// Amac:
///   MQTT broker kullanici adi/parolasini GUVENLI depoda
///   (`flutter_secure_storage` -- Android Keystore / iOS Keychain / web
///   WebCrypto) saklar. Parola ASLA SharedPreferences'a (duz metin) yazilmaz.
///
///   Test ortaminda platform eklentisi olmayabilir: okuma/yazma hatalari
///   yutulur ve bellek-ici yedege dusulur (uygulama cokmesin diye), boylece
///   kimlik bilgisi yalnizca o oturumda gecerli olur.
library;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef MqttKimligi = ({String kullaniciAdi, String parola});

class MqttKimlikServisi {
  MqttKimlikServisi._();

  static const FlutterSecureStorage _depo = FlutterSecureStorage();
  static const _kullaniciAnahtari = 'aquaguard_mqtt_kullanici';
  static const _parolaAnahtari = 'aquaguard_mqtt_parola';

  static MqttKimligi? _bellekYedegi;

  static Future<MqttKimligi> oku() async {
    try {
      final kullanici = await _depo.read(key: _kullaniciAnahtari) ?? '';
      final parola = await _depo.read(key: _parolaAnahtari) ?? '';
      return (kullaniciAdi: kullanici, parola: parola);
    } catch (hata) {
      debugPrint('AquaGuard MQTT kimlik okuma (bellek yedegi): $hata');
      return _bellekYedegi ?? (kullaniciAdi: '', parola: '');
    }
  }

  /// Bos [kullaniciAdi] kimlik bilgisini TAMAMEN siler (anonim baglanti).
  static Future<void> kaydet({
    required String kullaniciAdi,
    required String parola,
  }) async {
    _bellekYedegi = (kullaniciAdi: kullaniciAdi, parola: parola);
    try {
      if (kullaniciAdi.isEmpty) {
        await _depo.delete(key: _kullaniciAnahtari);
        await _depo.delete(key: _parolaAnahtari);
        return;
      }
      await _depo.write(key: _kullaniciAnahtari, value: kullaniciAdi);
      await _depo.write(key: _parolaAnahtari, value: parola);
    } catch (hata) {
      debugPrint('AquaGuard MQTT kimlik yazma (yalnizca bellek): $hata');
    }
  }
}
