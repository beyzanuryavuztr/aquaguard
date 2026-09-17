/// AquaGuard - Platforma Gore Dogru Hata Gunlugu Yazicisini Secen "Kosullu Ithalat"
/// =======================================================================================
///
/// Amac:
///   disa_aktarma_factory.dart / mqtt_istemci_factory.dart ile AYNI desen:
///   Web'de dart:io yoktur, bu yuzden derleme zamaninda platforma gore
///   FARKLI bir dosya secilir. Ustte bu dosyayi kullanan kod
///   (hata_gunlugu_servisi.dart), hangi implementasyonun secildigini
///   bilmek ZORUNDA DEGILDIR.
///
/// Tarih:  2026-09-18
library;

export 'hata_gunlugu_kalici_yazici_web.dart'
    if (dart.library.io) 'hata_gunlugu_kalici_yazici_io.dart';
