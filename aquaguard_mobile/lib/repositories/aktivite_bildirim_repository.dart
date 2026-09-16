/// AquaGuard - Aktivite/Bildirim Repository (Mimari Bolunme, Faz 12b)
/// =======================================================================
///
/// Amac:
///   AktiviteBildirimProvider'in kalici aktivite gecmisi, bildirim
///   gecmisi ve okunmus-bildirim-ID kumesine erisimini SOMUT depolama
///   teknolojisinden soyutlar -- bkz. sensor_okuma_repository.dart'in
///   dosya basi notu, AYNI gerekce burada da gecerlidir.
///
/// Tarih:  2026-09-17
library;

import '../models/aktivite_kaydi.dart';
import '../services/depolama_servisi.dart';

abstract class AktiviteBildirimRepository {
  Future<List<AktiviteKaydi>> aktiviteGecmisiGetir();
  Future<void> aktiviteGecmisiniKaydet(List<AktiviteKaydi> gecmis);

  Future<List<AktiviteKaydi>> bildirimGecmisiGetir();
  Future<void> bildirimGecmisiniKaydet(List<AktiviteKaydi> gecmis);

  Future<Set<int>> okunmusBildirimIdleriGetir();
  Future<void> okunmusBildirimIdleriniKaydet(Set<int> idler);
}

class SharedPreferencesAktiviteBildirimRepository
    implements AktiviteBildirimRepository {
  final DepolamaServisi _depolama;

  SharedPreferencesAktiviteBildirimRepository({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  @override
  Future<List<AktiviteKaydi>> aktiviteGecmisiGetir() =>
      _depolama.aktiviteGecmisiGetir();

  @override
  Future<void> aktiviteGecmisiniKaydet(List<AktiviteKaydi> gecmis) =>
      _depolama.aktiviteGecmisiniKaydet(gecmis);

  @override
  Future<List<AktiviteKaydi>> bildirimGecmisiGetir() =>
      _depolama.bildirimGecmisiGetir();

  @override
  Future<void> bildirimGecmisiniKaydet(List<AktiviteKaydi> gecmis) =>
      _depolama.bildirimGecmisiniKaydet(gecmis);

  @override
  Future<Set<int>> okunmusBildirimIdleriGetir() =>
      _depolama.okunmusBildirimIdleriGetir();

  @override
  Future<void> okunmusBildirimIdleriniKaydet(Set<int> idler) =>
      _depolama.okunmusBildirimIdleriniKaydet(idler);
}
