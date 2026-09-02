/// AquaGuard - CSV Kaydetme (dart:io -- Android/Windows/macOS/Linux)
/// =====================================================================
///
/// Amac:
///   CSV icerigini cihazin "Indirilenler"/belgeler dizinine gercek bir
///   dosya olarak yazar. Web'de dart:io olmadigi icin bu dosya sadece
///   dart.library.io mevcut platformlarda derlenir (bkz.
///   disa_aktarma_factory.dart kosullu ithalati).
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'disa_aktarma_servisi.dart';

/// CSV'yi diske yazar, kaydedilen tam dosya yolunu doner (SnackBar'da
/// kullaniciya gosterilmek uzere).
Future<String> csvKaydet(String dosyaAdi, String icerik) async {
  final dizin =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final dosya = File('${dizin.path}/$dosyaAdi');
  await dosya.writeAsString(
    DisaAktarmaServisi.utf8Bom + icerik,
    encoding: utf8,
  );
  return dosya.path;
}
