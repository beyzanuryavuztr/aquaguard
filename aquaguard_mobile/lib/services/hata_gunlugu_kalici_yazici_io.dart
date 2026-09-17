/// AquaGuard - Hata Gunlugu Kalici Yazici (dart:io -- Android/Windows/macOS/Linux)
/// =====================================================================================
///
/// Amac:
///   Hata gunlugu satirlarini gercek bir dosyaya (uygulama belgeler
///   dizininde) yazar. disa_aktarma_io.dart/web.dart ile AYNI kosullu
///   ithalat deseni (bkz. hata_gunlugu_kalici_yazici_factory.dart).
///
///   SENKRON yazilir (`writeAsStringSync`) -- bu servisin asil amaci COKME
///   ANINDA (FlutterError.onError/runZonedGuarded) son satiri bile
///   kaybetmemek; Dart'in normal `async`/`await` yazma yollari cokme
///   sirasinda tamamlanmadan surec sonlanabilir.
///
/// Tarih:  2026-09-18
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

String? _dosyaYolu;

/// Uygulama baslarken (normal, cokme DISINDA) BIR KEZ cagrilir -- dosya
/// yolunu ONCEDEN cozer, boylece sonraki `kaliciYaz` cagrilari (cokme
/// anindakiler dahil) TAMAMEN senkron kalabilir.
Future<void> kaliciYaziciyiHazirla() async {
  try {
    final dizin = await getApplicationDocumentsDirectory();
    _dosyaYolu = '${dizin.path}/aquaguard_hata_gunlugu.log';
  } catch (_) {
    // path_provider bazi ortamlarda (orn. flutter test host'u --
    // connectivity_plus icin de ayni durum, bkz.
    // CihazIletisimProvider._cihazAgDurumunuIzlemeyeBasla) platform
    // kanali saglamayabilir. Bu KRITIK bir yol degil -- kalici yazma
    // devre disi kalir (kaliciYaz/kaliciGunlugunuOku zaten `_dosyaYolu
    // == null` durumunu sessizce ele alir), bellek-ici gunluk yine calisir.
  }
}

List<String> kaliciGunlugunuOku() {
  final yol = _dosyaYolu;
  if (yol == null) return [];
  final dosya = File(yol);
  if (!dosya.existsSync()) return [];
  try {
    return dosya
        .readAsLinesSync()
        .where((satir) => satir.trim().isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

void kaliciYaz(String satir) {
  final yol = _dosyaYolu;
  if (yol == null) return;
  try {
    File(
      yol,
    ).writeAsStringSync('$satir\n', mode: FileMode.append, flush: true);
  } catch (_) {
    // Gunluk yazarken hata olursa SESSIZCE yut -- hata-gunlukleyicinin
    // kendisi yeni bir hataya/sonsuz donguye yol acmamali.
  }
}
