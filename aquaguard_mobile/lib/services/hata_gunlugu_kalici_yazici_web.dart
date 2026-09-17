/// AquaGuard - Hata Gunlugu Kalici Yazici (Web -- localStorage)
/// =================================================================
///
/// Amac:
///   Web'de gercek bir dosya sistemi yoktur; hata gunlugu satirlari
///   `window.localStorage`'a yazilir -- bu da (dart:io'nun senkron dosya
///   yazimi gibi) DOGAL OLARAK senkrondur, cokme aninda bile guvenle
///   kullanilabilir. disa_aktarma_web.dart ile AYNI kosullu ithalat
///   deseni (bkz. hata_gunlugu_kalici_yazici_factory.dart).
///
/// Tarih:  2026-09-18
library;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _anahtar = 'aquaguard_hata_gunlugu';
// localStorage tipik olarak ~5-10MB ile sinirlidir -- sinirsiz buyumeyi
// onlemek icin en fazla bu kadar satir tutulur (en eskiler dusurulur).
const _maksimumSatir = 500;

Future<void> kaliciYaziciyiHazirla() async {
  // Web'de onceden cozulmesi gereken bir dosya yolu yok -- no-op.
}

List<String> kaliciGunlugunuOku() {
  try {
    final ham = html.window.localStorage[_anahtar];
    if (ham == null || ham.isEmpty) return [];
    return ham.split('\n').where((satir) => satir.trim().isNotEmpty).toList();
  } catch (_) {
    return [];
  }
}

void kaliciYaz(String satir) {
  try {
    final guncel = [...kaliciGunlugunuOku(), satir];
    final sinirli = guncel.length > _maksimumSatir
        ? guncel.sublist(guncel.length - _maksimumSatir)
        : guncel;
    html.window.localStorage[_anahtar] = sinirli.join('\n');
  } catch (_) {
    // Gunluk yazarken hata olursa SESSIZCE yut -- bkz. io varyantindaki ayni not.
  }
}
