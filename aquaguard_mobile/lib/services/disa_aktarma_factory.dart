/// AquaGuard - Platforma Gore Dogru CSV Kaydedicisini Secen "Kosullu Ithalat"
/// ===============================================================================
///
/// Amac:
///   mqtt_istemci_factory.dart ile AYNI desen: Web'de dart:io yoktur, bu
///   yuzden derleme zamaninda platforma gore FARKLI bir dosya secilir.
///   Ustte bu dosyayi kullanan kod, hangi implementasyonun secildigini
///   bilmek ZORUNDA DEGILDIR -- ikisi de ayni imzali csvKaydet() fonksiyonunu
///   disari acar.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

export 'disa_aktarma_web.dart' if (dart.library.io) 'disa_aktarma_io.dart';
