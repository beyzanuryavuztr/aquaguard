/// AquaGuard - Bakim Provider (Mimari Bolunme, Faz 12)
/// ==========================================================
///
/// Amac:
///   Periyodik bakim gorevlerini (filtre temizligi, vana kontrolu, sensor
///   kalibrasyonu, genel denetim) tasir. Diger provider'lardan bagimsiz,
///   kucuk/izole bir dilim -- eskiden tek bir "Yapıldı" tiklamasi bile tum
///   uygulamanin yeniden cizilmesine sebep oluyordu.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/foundation.dart';

import '../models/bakim_gorevi.dart';
import '../services/depolama_servisi.dart';

class BakimProvider extends ChangeNotifier {
  final DepolamaServisi _depolama;

  BakimProvider({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  List<BakimGorevi> _bakimGorevleri = [];

  List<BakimGorevi> get bakimGorevleri => List.unmodifiable(_bakimGorevleri);

  /// Gecikmis VEYA yaklasan (bkz. BakimGorevi.durumu) en az bir gorev var mi
  /// -- Genel Bakış'taki uyari kartinin gosterilip gosterilmeyecegine karar
  /// verir.
  bool get bakimUyarisiVarMi =>
      _bakimGorevleri.any((g) => g.durumu() != BakimDurumu.normal);

  Future<void> baslat() async {
    final kayitliBakimGorevleri = await _depolama.bakimGorevleriGetir();
    if (kayitliBakimGorevleri == null) {
      _bakimGorevleri = varsayilanBakimGorevleri();
      await _depolama.bakimGorevleriniKaydet(_bakimGorevleri);
    } else {
      _bakimGorevleri = kayitliBakimGorevleri;
    }
    notifyListeners();
  }

  /// [gorevId] ile eslesen bakim gorevini "bugun yapildi" olarak isaretler
  /// -- sonraki tarihi periyoduna gore ileri atar.
  Future<void> bakimGoreviTamamlandiIsaretle(String gorevId) async {
    _bakimGorevleri = [
      for (final g in _bakimGorevleri)
        if (g.id == gorevId) g.tamamlandiOlarakIsaretle() else g,
    ];
    await _depolama.bakimGorevleriniKaydet(_bakimGorevleri);
    notifyListeners();
  }
}
