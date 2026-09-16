/// AquaGuard - Tarla Notu Repository (Mimari Bolunme, Faz 12b)
/// ================================================================
///
/// Amac:
///   TarlaProvider'in tarla notlarina erisimini SOMUT depolama
///   teknolojisinden soyutlar -- bkz. sensor_okuma_repository.dart'in
///   dosya basi notu, AYNI gerekce burada da gecerlidir. (Tarla/zon
///   LISTESI'nin kendisi kucuk veri oldugu icin SharedPreferences'ta
///   KALIR, bkz. proje yol haritasi Faz 13 notu -- sadece potansiyel
///   olarak buyuyen NOTLAR listesi buraya tasindi.)
///
/// Tarih:  2026-09-17
library;

import '../models/tarla_notu.dart';
import '../services/depolama_servisi.dart';

abstract class TarlaNotuRepository {
  Future<List<TarlaNotu>> tarlaNotlariGetir();
  Future<void> tarlaNotlariniKaydet(List<TarlaNotu> notlar);
}

class SharedPreferencesTarlaNotuRepository implements TarlaNotuRepository {
  final DepolamaServisi _depolama;

  SharedPreferencesTarlaNotuRepository({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  @override
  Future<List<TarlaNotu>> tarlaNotlariGetir() => _depolama.tarlaNotlariGetir();

  @override
  Future<void> tarlaNotlariniKaydet(List<TarlaNotu> notlar) =>
      _depolama.tarlaNotlariniKaydet(notlar);
}
