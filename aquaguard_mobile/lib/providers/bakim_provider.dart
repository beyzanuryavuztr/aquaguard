/// AquaGuard - Bakim Provider (Mimari Bolunme, Faz 12)
/// ==========================================================
///
/// Amac:
///   Periyodik bakim gorevlerini (filtre temizligi, vana kontrolu, sensor
///   kalibrasyonu, genel denetim) tasir. Diger provider'lardan bagimsiz,
///   kucuk/izole bir dilim -- eskiden tek bir "Yapıldı" tiklamasi bile tum
///   uygulamanin yeniden cizilmesine sebep oluyordu.
///
///   Kalici depolamaya [BakimGoreviRepository] uzerinden erisir (Faz 12b,
///   `DepolamaServisi`'ne DOGRUDAN bagimli degildir) -- bkz. o dosyanin
///   basindaki not, SQLite gecisini (Faz 13) provider kodu degismeden
///   yapabilmek icindir.
///
/// Tarih:  2026-09-16 (ilk yazim) / 2026-09-17 (repository pattern)
library;

import 'package:flutter/foundation.dart';

import '../models/bakim_gorevi.dart';
import '../repositories/bakim_gorevi_repository.dart';

class BakimProvider extends ChangeNotifier {
  final BakimGoreviRepository _depo;

  BakimProvider({BakimGoreviRepository? depo})
    : _depo = depo ?? SharedPreferencesBakimGoreviRepository();

  List<BakimGorevi> _bakimGorevleri = [];

  List<BakimGorevi> get bakimGorevleri => List.unmodifiable(_bakimGorevleri);

  /// Gecikmis VEYA yaklasan (bkz. BakimGorevi.durumu) en az bir gorev var mi
  /// -- Genel Bakış'taki uyari kartinin gosterilip gosterilmeyecegine karar
  /// verir.
  bool get bakimUyarisiVarMi =>
      _bakimGorevleri.any((g) => g.durumu() != BakimDurumu.normal);

  Future<void> baslat() async {
    final kayitliBakimGorevleri = await _depo.bakimGorevleriGetir();
    if (kayitliBakimGorevleri == null) {
      _bakimGorevleri = varsayilanBakimGorevleri();
      await _depo.bakimGorevleriniKaydet(_bakimGorevleri);
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
    await _depo.bakimGorevleriniKaydet(_bakimGorevleri);
    notifyListeners();
  }
}
