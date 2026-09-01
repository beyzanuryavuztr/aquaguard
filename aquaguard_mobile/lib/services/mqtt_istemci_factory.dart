/// AquaGuard - Platforma Gore Dogru MQTT Istemcisini Secen "Kosullu Ithalat"
/// =============================================================================
///
/// Amac:
///   Flutter Web'de dart:io yoktur (tarayici ham TCP soketi acamaz), bu
///   yuzden derleme zamaninda platforma gore FARKLI bir dosya secilir:
///
///     - dart.library.io MEVCUTSA (Android/iOS/Windows/Linux/macOS)
///       -> mqtt_istemci_io.dart  (dogrudan TCP baglantisi)
///     - dart.library.io YOKSA (Web/Chrome)
///       -> mqtt_istemci_web.dart (WebSocket baglantisi)
///
///   Bu, Dart'in "conditional import/export" ozelligidir; derleyici hangi
///   platform icin derledigini bilir ve dogru dosyayi otomatik secer. Ustte
///   bu dosyayi kullanan kod, hangi implementasyonun secildigini bilmek
///   ZORUNDA DEGILDIR -- ikisi de ayni imzali mqttIstemciOlustur()
///   fonksiyonunu disari acar.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

export 'mqtt_istemci_web.dart' if (dart.library.io) 'mqtt_istemci_io.dart';
