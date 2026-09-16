/// AquaGuard - Bakim Gorevi Repository (Mimari Bolunme, Faz 12b)
/// ==================================================================
///
/// Amac:
///   BakimProvider'in bakim gorevleri listesine erisimini SOMUT depolama
///   teknolojisinden soyutlar -- bkz. sensor_okuma_repository.dart'in
///   dosya basi notu, AYNI gerekce burada da gecerlidir.
///
/// Tarih:  2026-09-17
library;

import '../models/bakim_gorevi.dart';
import '../services/depolama_servisi.dart';

abstract class BakimGoreviRepository {
  /// Kayitli bakim gorevi YOKSA (ilk kurulum) null doner -- cagiran taraf
  /// bu durumda varsayilanBakimGorevleri()'ni seed'ler.
  Future<List<BakimGorevi>?> bakimGorevleriGetir();
  Future<void> bakimGorevleriniKaydet(List<BakimGorevi> gorevler);
}

class SharedPreferencesBakimGoreviRepository implements BakimGoreviRepository {
  final DepolamaServisi _depolama;

  SharedPreferencesBakimGoreviRepository({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  @override
  Future<List<BakimGorevi>?> bakimGorevleriGetir() =>
      _depolama.bakimGorevleriGetir();

  @override
  Future<void> bakimGorevleriniKaydet(List<BakimGorevi> gorevler) =>
      _depolama.bakimGorevleriniKaydet(gorevler);
}
