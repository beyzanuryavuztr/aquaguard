/// AquaGuard - Sensor Okuma Repository (SQLite/drift Uygulamasi, Faz 13)
/// ==========================================================================
///
/// Amac:
///   [SensorOkumaRepository] arayuzunun SQLite/drift uzerinden calisan
///   somut uygulamasi -- bkz. sensor_okuma_repository.dart dosya basi
///   notu (soyutlamanin gerekcesi) ve veritabani.dart (tablo semasi,
///   `SensorOkumalari` gecmis icin, `SonOkumalar` ayri/tekil son deger
///   icin -- BIREBIR AYNI cift-yazim davranisini SharedPreferences
///   uygulamasindan devralir, bkz. o dosyanin dosya basi notu).
///
/// Tarih:  2026-09-17
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/sensor_okuma.dart';
import '../services/veritabani.dart';
import 'sensor_okuma_repository.dart';

class DriftSensorOkumaRepository implements SensorOkumaRepository {
  final AquaGuardVeritabani _db;

  // SQLite'a gecisin (Faz 13) asil amaci SharedPreferences'in 200 kayitlik
  // pratik sinirindan kurtulmakti -- bu sinir SQLite'ta artik yapay,
  // kaldirildi. Yerine iki BAGIMSIZ sinir konur, HANGISI ONCE DOLARSA
  // devreye girer: 10.000 kayit (disk/bellek sisirilmesin) VE 7 gun
  // (eski veri analitik acidan giderek daha az anlamli olur).
  //
  // NOT: zaman siniri SADECE gecmiseEkle()'de (canli/surekli buyuyen
  // veri) uygulanir -- gecmisiTopluKaydet() (ilk kurulumda GEREYE DONUK
  // uretilen 12 GUNLUK sentetik demo gecmisi, bkz. GecmisVeriUreticisi)
  // BILEREK bu sinirdan MUAF: aksi halde taze uretilen demo gecmisinin
  // en eski 5 gunu, kaydedildigi ANDA silinirdi.
  static const _gecmisMaksimumUzunluk = 10000;
  static const _gecmisMaksimumSure = Duration(days: 7);

  DriftSensorOkumaRepository(this._db);

  static String _encode(Map<String, dynamic> json) => jsonEncode(json);
  static Map<String, dynamic> _decode(String ham) =>
      jsonDecode(ham) as Map<String, dynamic>;

  @override
  Future<List<SensorOkuma>> gecmisiGetir(int zone) async {
    final satirlar =
        await (_db.select(_db.sensorOkumalari)
              ..where((t) => t.zone.equals(zone))
              ..orderBy([(t) => OrderingTerm.desc(t.zamanMillis)]))
            .get();
    return satirlar
        .map((s) => SensorOkuma.fromCacheJson(_decode(s.jsonVeri)))
        .toList();
  }

  @override
  Future<void> gecmisiTopluKaydet(int zone, List<SensorOkuma> gecmis) async {
    final sinirli = gecmis.take(_gecmisMaksimumUzunluk).toList();
    await _db.transaction(() async {
      await (_db.delete(
        _db.sensorOkumalari,
      )..where((t) => t.zone.equals(zone))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.sensorOkumalari,
          sinirli.map(
            (o) => SensorOkumalariCompanion.insert(
              zone: zone,
              zamanMillis: o.zaman.millisecondsSinceEpoch,
              jsonVeri: _encode(o.toJson()),
            ),
          ),
        );
      });
    });
  }

  @override
  Future<void> gecmiseEkle(SensorOkuma okuma) async {
    await _db.transaction(() async {
      await _db
          .into(_db.sensorOkumalari)
          .insert(
            SensorOkumalariCompanion.insert(
              zone: okuma.zone,
              zamanMillis: okuma.zaman.millisecondsSinceEpoch,
              jsonVeri: _encode(okuma.toJson()),
            ),
          );

      // 1) _gecmisMaksimumSure'den ESKI satirlari sil -- zon bazinda,
      // dogrudan bir WHERE ile (ayri bir ID sorgusuna gerek yok).
      final zamanEsigiMillis = DateTime.now()
          .subtract(_gecmisMaksimumSure)
          .millisecondsSinceEpoch;
      await (_db.delete(_db.sensorOkumalari)..where(
            (t) =>
                t.zone.equals(okuma.zone) &
                t.zamanMillis.isSmallerThanValue(zamanEsigiMillis),
          ))
          .go();

      // 2) Zaman sinirindan sonra KALAN satirlar hala _gecmisMaksimumUzunluk'u
      // asiyorsa, EN ESKI fazlaligi sil -- SharedPreferences uygulamasinin
      // "yeni ekle, en yeni N'i tut" davranisiyla AYNI, sadece N artik cok
      // daha buyuk.
      final fazlalikIdler =
          await (_db.select(_db.sensorOkumalari)
                ..where((t) => t.zone.equals(okuma.zone))
                ..orderBy([(t) => OrderingTerm.desc(t.zamanMillis)])
                ..limit(1 << 30, offset: _gecmisMaksimumUzunluk))
              .map((s) => s.id)
              .get();
      if (fazlalikIdler.isNotEmpty) {
        await (_db.delete(
          _db.sensorOkumalari,
        )..where((t) => t.id.isIn(fazlalikIdler))).go();
      }
    });
  }

  @override
  Future<SensorOkuma?> sonOkumayiGetir(int zone) async {
    final satir = await (_db.select(
      _db.sonOkumalar,
    )..where((t) => t.zone.equals(zone))).getSingleOrNull();
    if (satir == null) return null;
    return SensorOkuma.fromCacheJson(_decode(satir.jsonVeri));
  }

  @override
  Future<void> sonOkumayiKaydet(SensorOkuma okuma) async {
    await _db
        .into(_db.sonOkumalar)
        .insertOnConflictUpdate(
          SonOkumalarCompanion.insert(
            zone: Value(okuma.zone),
            jsonVeri: _encode(okuma.toJson()),
          ),
        );
  }

  @override
  Future<void> zonVerisiniTemizle(int zone) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.sensorOkumalari,
      )..where((t) => t.zone.equals(zone))).go();
      await (_db.delete(
        _db.sonOkumalar,
      )..where((t) => t.zone.equals(zone))).go();
    });
  }
}
