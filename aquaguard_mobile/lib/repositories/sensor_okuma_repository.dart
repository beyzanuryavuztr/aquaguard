/// AquaGuard - Sensor Okuma Repository (Mimari Bolunme, Faz 12b)
/// ===================================================================
///
/// Amac:
///   CihazIletisimProvider'in zon basina buyuyen sensor gecmisine
///   erisimini, SOMUT depolama teknolojisinden (bugun SharedPreferences/
///   JSON, Faz 13'te SQLite/drift) SOYUTLAR. Provider artik
///   `DepolamaServisi`'ne DOGRUDAN bagimli degildir -- bu arayuze
///   bagimlidir. Faz 13'te [DriftSensorOkumaRepository] (veya benzeri)
///   eklenip main.dart'taki TEK satir degistirildiginde, provider kodu
///   HIC DEGISMEDEN yeni depoya gecer.
///
///   Bu, tipik bir "gelecek icin genel soyutlama" DEGIL -- SQLite gecisi
///   ZATEN planlanan, somut bir sonraki adim (bkz. proje yol haritasi
///   Faz 13); soyutlama simdiden, GERCEK bir ihtiyaca gore kuruluyor.
///
/// Tarih:  2026-09-17
library;

import '../models/sensor_okuma.dart';
import '../services/depolama_servisi.dart';

abstract class SensorOkumaRepository {
  Future<List<SensorOkuma>> gecmisiGetir(int zone);

  /// Bir zonun TUM gecmisini tek seferde yazar (liste EN YENI ONCE sirali
  /// olmali) -- toplu (bulk) yazimlar icin.
  Future<void> gecmisiTopluKaydet(int zone, List<SensorOkuma> gecmis);

  /// Yeni bir okumayi gecmisin BASINA ekler (en yeni once).
  Future<void> gecmiseEkle(SensorOkuma okuma);

  Future<SensorOkuma?> sonOkumayiGetir(int zone);
  Future<void> sonOkumayiKaydet(SensorOkuma okuma);

  /// Bir zonun onbellekteki son okumasini VE gecmisini tamamen siler.
  Future<void> zonVerisiniTemizle(int zone);
}

/// [SensorOkumaRepository]'nin bugunku (SharedPreferences/JSON) somut
/// uygulamasi -- mevcut [DepolamaServisi] metodlarina INCE bir sarmalayici
/// (thin wrapper), davranis BIREBIR aynidir.
class SharedPreferencesSensorOkumaRepository implements SensorOkumaRepository {
  final DepolamaServisi _depolama;

  SharedPreferencesSensorOkumaRepository({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  @override
  Future<List<SensorOkuma>> gecmisiGetir(int zone) =>
      _depolama.gecmisiGetir(zone);

  @override
  Future<void> gecmisiTopluKaydet(int zone, List<SensorOkuma> gecmis) =>
      _depolama.gecmisiTopluKaydet(zone, gecmis);

  @override
  Future<void> gecmiseEkle(SensorOkuma okuma) => _depolama.gecmiseEkle(okuma);

  @override
  Future<SensorOkuma?> sonOkumayiGetir(int zone) =>
      _depolama.sonOkumayiGetir(zone);

  @override
  Future<void> sonOkumayiKaydet(SensorOkuma okuma) =>
      _depolama.sonOkumayiKaydet(okuma);

  @override
  Future<void> zonVerisiniTemizle(int zone) =>
      _depolama.zonVerisiniTemizle(zone);
}
