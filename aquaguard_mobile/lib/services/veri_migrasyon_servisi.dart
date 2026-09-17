/// AquaGuard - SharedPreferences -> SQLite Veri Migrasyonu (Faz 13)
/// =====================================================================
///
/// Amac:
///   Mevcut kullanicilarin cihazinda SharedPreferences'ta biriken
///   verinin (zon basina sensor gecmisi/son okuma, aktivite gecmisi,
///   bildirim gecmisi, tarla notlari) SQLite'a (bkz. veritabani.dart)
///   BIR KEZ tasinmasini saglar -- kullanicinin mevcut verisi (gecmis
///   kayitlari, notlari) yukseltme sirasinda KAYBOLMAZ.
///
///   Zon numaralari, kalici anahtar ISIMLERINDEN cikarilir
///   (`aquaguard_gecmis_zone_<N>` / `aquaguard_son_okuma_zone_<N>`) --
///   TarlaProvider'in zon listesine BAGIMLI DEGILDIR, boylece migrasyon
///   diger provider'lardan bagimsiz, en erken asamada (UygulamaDurumu.
///   baslat()'in EN BASINDA) calisabilir.
///
///   GUVENLI/TEKRAR-CALISTIRILABILIR (idempotent): tum yazimlar "sil +
///   toplu ekle" veya upsert seklindedir (bkz. Drift*Repository siniflari) --
///   uygulama migrasyon ORTASINDA kapatilirsa, bir sonraki acilista
///   YENIDEN denenir, veri COGALMAZ/BOZULMAZ. Eski SharedPreferences
///   anahtarlari ve "tamamlandi" bayragi, SADECE TUM kopyalar basariyla
///   bittikten SONRA silinir/yazilir.
///
/// Tarih:  2026-09-17
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/drift_aktivite_bildirim_repository.dart';
import '../repositories/drift_sensor_okuma_repository.dart';
import '../repositories/drift_tarla_notu_repository.dart';
import 'depolama_servisi.dart';
import 'veritabani.dart';

class VeriMigrasyonServisi {
  static const _tamamlandiAnahtari = 'aquaguard_sqlite_migrasyon_tamamlandi';
  static final _gecmisAnahtarDeseni = RegExp(r'^aquaguard_gecmis_zone_(\d+)$');
  static final _sonOkumaAnahtarDeseni = RegExp(
    r'^aquaguard_son_okuma_zone_(\d+)$',
  );

  final AquaGuardVeritabani _db;
  final DepolamaServisi _depolama;

  VeriMigrasyonServisi(this._db, {DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  Future<void> gerekirseMigrateEt() async {
    final tercihler = await SharedPreferences.getInstance();
    if (tercihler.getBool(_tamamlandiAnahtari) ?? false) return;

    final zonNumaralari = <int>{};
    for (final anahtar in tercihler.getKeys()) {
      final gecmisEslesme = _gecmisAnahtarDeseni.firstMatch(anahtar);
      if (gecmisEslesme != null) {
        zonNumaralari.add(int.parse(gecmisEslesme.group(1)!));
        continue;
      }
      final sonOkumaEslesme = _sonOkumaAnahtarDeseni.firstMatch(anahtar);
      if (sonOkumaEslesme != null) {
        zonNumaralari.add(int.parse(sonOkumaEslesme.group(1)!));
      }
    }

    final sensorDepo = DriftSensorOkumaRepository(_db);
    for (final zon in zonNumaralari) {
      final gecmis = await _depolama.gecmisiGetir(zon);
      if (gecmis.isNotEmpty) {
        await sensorDepo.gecmisiTopluKaydet(zon, gecmis);
      }
      final sonOkuma = await _depolama.sonOkumayiGetir(zon);
      if (sonOkuma != null) {
        await sensorDepo.sonOkumayiKaydet(sonOkuma);
      }
    }

    final aktiviteBildirimDepo = DriftAktiviteBildirimRepository(
      _db,
      depolama: _depolama,
    );
    final aktiviteGecmisi = await _depolama.aktiviteGecmisiGetir();
    if (aktiviteGecmisi.isNotEmpty) {
      await aktiviteBildirimDepo.aktiviteGecmisiniKaydet(aktiviteGecmisi);
    }
    final bildirimGecmisi = await _depolama.bildirimGecmisiGetir();
    if (bildirimGecmisi.isNotEmpty) {
      await aktiviteBildirimDepo.bildirimGecmisiniKaydet(bildirimGecmisi);
    }

    final tarlaNotlari = await _depolama.tarlaNotlariGetir();
    if (tarlaNotlari.isNotEmpty) {
      await DriftTarlaNotuRepository(_db).tarlaNotlariniKaydet(tarlaNotlari);
    }

    for (final zon in zonNumaralari) {
      await tercihler.remove('aquaguard_gecmis_zone_$zon');
      await tercihler.remove('aquaguard_son_okuma_zone_$zon');
    }
    await tercihler.remove('aquaguard_aktivite_gecmisi');
    await tercihler.remove('aquaguard_bildirim_gecmisi');
    await tercihler.remove('aquaguard_tarla_notlari');
    await tercihler.setBool(_tamamlandiAnahtari, true);
  }
}
