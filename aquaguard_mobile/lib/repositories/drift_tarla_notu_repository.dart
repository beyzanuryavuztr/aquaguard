/// AquaGuard - Tarla Notu Repository (SQLite/drift Uygulamasi, Faz 13)
/// ========================================================================
///
/// Amac:
///   [TarlaNotuRepository] arayuzunun SQLite/drift uzerinden calisan
///   somut uygulamasi -- bkz. tarla_notu_repository.dart dosya basi notu
///   ve veritabani.dart (tablo semasi).
///
/// Tarih:  2026-09-17
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/tarla_notu.dart';
import '../services/veritabani.dart';
import 'tarla_notu_repository.dart';

class DriftTarlaNotuRepository implements TarlaNotuRepository {
  final AquaGuardVeritabani _db;

  DriftTarlaNotuRepository(this._db);

  static String _encode(Map<String, dynamic> json) => jsonEncode(json);
  static Map<String, dynamic> _decode(String ham) =>
      jsonDecode(ham) as Map<String, dynamic>;

  @override
  Future<List<TarlaNotu>> tarlaNotlariGetir() async {
    final satirlar =
        await (_db.select(_db.tarlaNotlari)
              ..orderBy([(t) => OrderingTerm.desc(t.zamanMillis)]))
            .get();
    return satirlar.map((s) => TarlaNotu.fromJson(_decode(s.jsonVeri))).toList();
  }

  /// [TarlaProvider] her degisiklikte TUM notu listesini yeniden yazar --
  /// bkz. DriftAktiviteBildirimRepository'nin AYNI deseni.
  @override
  Future<void> tarlaNotlariniKaydet(List<TarlaNotu> notlar) async {
    await _db.transaction(() async {
      await _db.delete(_db.tarlaNotlari).go();
      if (notlar.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.tarlaNotlari,
          notlar.map(
            (n) => TarlaNotlariCompanion.insert(
              id: n.id,
              tarlaId: n.tarlaId,
              zamanMillis: n.zaman.millisecondsSinceEpoch,
              jsonVeri: _encode(n.toJson()),
            ),
          ),
        );
      });
    });
  }
}
