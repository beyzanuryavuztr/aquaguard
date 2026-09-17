/// AquaGuard - Aktivite/Bildirim Repository (SQLite/drift Uygulamasi, Faz 13)
/// ================================================================================
///
/// Amac:
///   [AktiviteBildirimRepository] arayuzunun SQLite/drift uzerinden calisan
///   somut uygulamasi -- bkz. aktivite_bildirim_repository.dart dosya basi
///   notu ve veritabani.dart (tablo semasi).
///
///   Okunmus bildirim ID kumesi (`okunmusBildirimIdleri`) KUCUK/BASIT bir
///   int kumesi oldugu icin (bkz. AktiviteBildirimProvider -- bildirim
///   gecmisiyle KESISTIRILEREK sinirlanir, sinirsiz BUYUMEZ) SQLite'a
///   tasinmadi; bu tek metod cifti HALA DepolamaServisi/SharedPreferences
///   uzerinden calisir -- gercek bir ihtiyaca gore degil, asiri
///   mühendislige hizmet ederdi.
///
/// Tarih:  2026-09-17
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/aktivite_kaydi.dart';
import '../services/depolama_servisi.dart';
import '../services/veritabani.dart';
import 'aktivite_bildirim_repository.dart';

class DriftAktiviteBildirimRepository implements AktiviteBildirimRepository {
  final AquaGuardVeritabani _db;
  final DepolamaServisi _depolama;

  DriftAktiviteBildirimRepository(this._db, {DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  static String _encode(Map<String, dynamic> json) => jsonEncode(json);
  static Map<String, dynamic> _decode(String ham) =>
      jsonDecode(ham) as Map<String, dynamic>;

  @override
  Future<List<AktiviteKaydi>> aktiviteGecmisiGetir() async {
    final satirlar =
        await (_db.select(_db.aktiviteKayitlari)
              ..orderBy([(t) => OrderingTerm.desc(t.zamanMillis)]))
            .get();
    return satirlar
        .map((s) => AktiviteKaydi.fromJson(_decode(s.jsonVeri)))
        .toList();
  }

  @override
  Future<void> aktiviteGecmisiniKaydet(List<AktiviteKaydi> gecmis) async {
    await _db.transaction(() async {
      await _db.delete(_db.aktiviteKayitlari).go();
      if (gecmis.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.aktiviteKayitlari,
          gecmis.map(
            (k) => AktiviteKayitlariCompanion.insert(
              zamanMillis: k.zaman.millisecondsSinceEpoch,
              jsonVeri: _encode(k.toJson()),
            ),
          ),
        );
      });
    });
  }

  @override
  Future<List<AktiviteKaydi>> bildirimGecmisiGetir() async {
    final satirlar =
        await (_db.select(_db.bildirimGecmisi)
              ..orderBy([(t) => OrderingTerm.desc(t.zamanMillis)]))
            .get();
    return satirlar
        .map((s) => AktiviteKaydi.fromJson(_decode(s.jsonVeri)))
        .toList();
  }

  // [AktiviteBildirimProvider] her degisiklikte TUM listeyi (zaten kendi
  // icinde 200 ile sinirlanmis) yeniden yazar -- bu yuzden burada da EN
  // BASIT ve HATASIZ yol, tabloyu TAMAMEN degistirmektir (sil + toplu ekle),
  // tek tek fark hesaplamaya (diffing) GEREK YOK.
  @override
  Future<void> bildirimGecmisiniKaydet(List<AktiviteKaydi> gecmis) async {
    await _db.transaction(() async {
      await _db.delete(_db.bildirimGecmisi).go();
      if (gecmis.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.bildirimGecmisi,
          gecmis.map(
            (k) => BildirimGecmisiCompanion.insert(
              zamanMillis: k.zaman.millisecondsSinceEpoch,
              jsonVeri: _encode(k.toJson()),
            ),
          ),
        );
      });
    });
  }

  @override
  Future<Set<int>> okunmusBildirimIdleriGetir() =>
      _depolama.okunmusBildirimIdleriGetir();

  @override
  Future<void> okunmusBildirimIdleriniKaydet(Set<int> idler) =>
      _depolama.okunmusBildirimIdleriniKaydet(idler);
}
