/// AquaGuard - Yerel Depolama Servisi (SharedPreferences)
/// ===========================================================
///
/// Amac:
///   Uygulamanin cevrimdisi calisabilmesi icin gereken tum bilgileri
///   cihazda yerel olarak saklar:
///     - Tarla/zon listesi (kullanicinin olusturdugu)
///     - MQTT baglanti ayarlari (broker adresi/portu)
///     - Her zon icin SON BILINEN OKUMA (GSM/internet kesilirse gosterilir)
///     - Her zon icin GECMIS KAYITLAR (sinirli sayida, en yeni once)
///     - Bildirim tercihleri (4 kategori) ve zon takma adlari
///
///   SharedPreferences basit anahtar-deger deposu oldugu icin, karmasik
///   veriler (Tarla listesi, SensorOkuma gecmisi) JSON metne cevrilip
///   String olarak saklanir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/ayarlar_sabitleri.dart';
import '../models/aktivite_kaydi.dart';
import '../models/bildirim_tercihleri.dart';
import '../models/sensor_okuma.dart';
import '../models/tarla.dart';
import '../models/tarla_notu.dart';

class DepolamaServisi {
  static const _tarlalarAnahtari = 'aquaguard_tarlalar';
  static const _mqttHostAnahtari = 'aquaguard_mqtt_host';
  static const _mqttPortAnahtari = 'aquaguard_mqtt_port';
  static const _bildirimTercihleriAnahtari = 'aquaguard_bildirim_tercihleri';
  static const _demoModuAnahtari = 'aquaguard_demo_modu_acik';
  static const _aktiviteGecmisiAnahtari = 'aquaguard_aktivite_gecmisi';
  static const _sulamaKapaliZonlarAnahtari = 'aquaguard_sulama_kapali_zonlar';
  static const _tarlaNotlariAnahtari = 'aquaguard_tarla_notlari';
  static const _zonTakmaAdlariAnahtari = 'aquaguard_zon_takma_adlari';
  static const _gecmisMaksimumUzunluk = 200;

  Future<SharedPreferences> get _tercihler async =>
      SharedPreferences.getInstance();

  // ==========================================================================
  // TARLALAR
  // ==========================================================================

  Future<List<Tarla>> tarlalariGetir() async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_tarlalarAnahtari);
    if (ham == null) {
      return Tarla.varsayilanListe();
    }
    final liste = jsonDecode(ham) as List<dynamic>;
    if (liste.isEmpty) {
      return Tarla.varsayilanListe();
    }
    return liste.map((e) => Tarla.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> tarlalariKaydet(List<Tarla> tarlalar) async {
    final tercihler = await _tercihler;
    final ham = jsonEncode(tarlalar.map((t) => t.toJson()).toList());
    await tercihler.setString(_tarlalarAnahtari, ham);
  }

  // ==========================================================================
  // MQTT BAGLANTI AYARLARI
  // ==========================================================================

  Future<({String host, int port})> mqttAyarlariniGetir() async {
    final tercihler = await _tercihler;
    final host =
        tercihler.getString(_mqttHostAnahtari) ??
        AyarlarSabitleri.varsayilanBroker;
    final port =
        tercihler.getInt(_mqttPortAnahtari) ?? AyarlarSabitleri.varsayilanPort;
    return (host: host, port: port);
  }

  Future<void> mqttAyarlariniKaydet({
    required String host,
    required int port,
  }) async {
    final tercihler = await _tercihler;
    await tercihler.setString(_mqttHostAnahtari, host);
    await tercihler.setInt(_mqttPortAnahtari, port);
  }

  // ==========================================================================
  // SON BILINEN OKUMA (cevrimdisi mod icin)
  // ==========================================================================

  String _sonOkumaAnahtari(int zone) => 'aquaguard_son_okuma_zone_$zone';

  Future<void> sonOkumayiKaydet(SensorOkuma okuma) async {
    final tercihler = await _tercihler;
    await tercihler.setString(
      _sonOkumaAnahtari(okuma.zone),
      jsonEncode(okuma.toJson()),
    );
  }

  Future<SensorOkuma?> sonOkumayiGetir(int zone) async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_sonOkumaAnahtari(zone));
    if (ham == null) return null;
    return SensorOkuma.fromCacheJson(jsonDecode(ham) as Map<String, dynamic>);
  }

  /// Bir zonun onbellekteki son okumasini VE gecmisini tamamen siler.
  /// Bir tarla silindiginde, artik hicbir tarlada kullanilmayan (yetim
  /// kalan) zonlar icin cagrilir -- aksi halde biri ayni zon numarasiyla
  /// yeni bir tarla olusturursa eski, alakasiz veriler "hayalet" gibi
  /// hemen gorunur (yeni veri gelene kadar).
  Future<void> zonVerisiniTemizle(int zone) async {
    final tercihler = await _tercihler;
    await tercihler.remove(_sonOkumaAnahtari(zone));
    await tercihler.remove(_gecmisAnahtari(zone));
  }

  // ==========================================================================
  // GECMIS KAYITLAR
  // ==========================================================================

  String _gecmisAnahtari(int zone) => 'aquaguard_gecmis_zone_$zone';

  Future<List<SensorOkuma>> gecmisiGetir(int zone) async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_gecmisAnahtari(zone));
    if (ham == null) return [];
    final liste = jsonDecode(ham) as List<dynamic>;
    return liste
        .map((e) => SensorOkuma.fromCacheJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Bir zonun TUM gecmisini tek seferde yazar (liste EN YENI ONCE
  /// sirali olmali). `gecmiseEkle`'nin aksine mevcut gecmisi OKUMAZ --
  /// GecmisVeriUreticisi gibi toplu (bulk) yazimlar icin, N kez okuma+
  /// yazma yapmaktan cok daha verimlidir.
  Future<void> gecmisiTopluKaydet(int zone, List<SensorOkuma> gecmis) async {
    final tercihler = await _tercihler;
    final sinirli = gecmis.take(_gecmisMaksimumUzunluk).toList();
    await tercihler.setString(
      _gecmisAnahtari(zone),
      jsonEncode(sinirli.map((o) => o.toJson()).toList()),
    );
  }

  /// Yeni bir okumayi gecmisin BASINA ekler (en yeni once) ve listeyi
  /// _gecmisMaksimumUzunluk ile sinirlar (cihaz depolamasi sisirilmesin diye).
  Future<void> gecmiseEkle(SensorOkuma okuma) async {
    final tercihler = await _tercihler;
    final mevcutGecmis = await gecmisiGetir(okuma.zone);
    final guncelGecmis = [
      okuma,
      ...mevcutGecmis,
    ].take(_gecmisMaksimumUzunluk).toList();
    await tercihler.setString(
      _gecmisAnahtari(okuma.zone),
      jsonEncode(guncelGecmis.map((o) => o.toJson()).toList()),
    );
  }

  // ==========================================================================
  // BILDIRIM TERCIHLERI (4 ayrı kategori -- bkz. models/bildirim_tercihleri.dart)
  // ==========================================================================

  Future<BildirimTercihleri> bildirimTercihleriniGetir() async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_bildirimTercihleriAnahtari);
    if (ham == null) return const BildirimTercihleri();
    return BildirimTercihleri.fromJson(jsonDecode(ham) as Map<String, dynamic>);
  }

  Future<void> bildirimTercihleriniKaydet(BildirimTercihleri tercih) async {
    final tercihler = await _tercihler;
    await tercihler.setString(
      _bildirimTercihleriAnahtari,
      jsonEncode(tercih.toJson()),
    );
  }

  // ==========================================================================
  // DEMO MODU TERCIHI
  // ==========================================================================

  /// Varsayilan TRUE'dur: henuz gercek donanim baglanmamisken uygulama ilk
  /// acildiginda bos ekran yerine dogrudan calisan bir demo gostersin diye.
  Future<bool> demoModuAcikMi() async {
    final tercihler = await _tercihler;
    return tercihler.getBool(_demoModuAnahtari) ?? true;
  }

  Future<void> demoModunuAyarla(bool acik) async {
    final tercihler = await _tercihler;
    await tercihler.setBool(_demoModuAnahtari, acik);
  }

  // ==========================================================================
  // AKTIVITE GECMISI (kalici -- uygulama yeniden acildiginda kaybolmasin diye)
  // ==========================================================================

  Future<List<AktiviteKaydi>> aktiviteGecmisiGetir() async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_aktiviteGecmisiAnahtari);
    if (ham == null) return [];
    final liste = jsonDecode(ham) as List<dynamic>;
    return liste
        .map((e) => AktiviteKaydi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> aktiviteGecmisiniKaydet(List<AktiviteKaydi> gecmis) async {
    final tercihler = await _tercihler;
    await tercihler.setString(
      _aktiviteGecmisiAnahtari,
      jsonEncode(gecmis.map((k) => k.toJson()).toList()),
    );
  }

  // ==========================================================================
  // SULAMA KONTROLU (manuel kapatilmis zonlar -- kalici, bkz. yorum yukarida)
  // ==========================================================================

  Future<Set<int>> sulamaKapaliZonlariGetir() async {
    final tercihler = await _tercihler;
    final liste = tercihler.getStringList(_sulamaKapaliZonlarAnahtari);
    if (liste == null) return {};
    return liste.map(int.parse).toSet();
  }

  Future<void> sulamaKapaliZonlariniKaydet(Set<int> zonlar) async {
    final tercihler = await _tercihler;
    await tercihler.setStringList(
      _sulamaKapaliZonlarAnahtari,
      zonlar.map((z) => z.toString()).toList(),
    );
  }

  // ==========================================================================
  // TARLA NOTLARI (operatorun serbest metin notlari, TUM tarlalar icin TEK
  // liste olarak saklanir -- tarlaId alanina gore filtrelenir)
  // ==========================================================================

  Future<List<TarlaNotu>> tarlaNotlariGetir() async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_tarlaNotlariAnahtari);
    if (ham == null) return [];
    final liste = jsonDecode(ham) as List<dynamic>;
    return liste
        .map((e) => TarlaNotu.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tarlaNotlariniKaydet(List<TarlaNotu> notlar) async {
    final tercihler = await _tercihler;
    await tercihler.setString(
      _tarlaNotlariAnahtari,
      jsonEncode(notlar.map((n) => n.toJson()).toList()),
    );
  }

  // ==========================================================================
  // ZON TAKMA ADLARI (operatorun her zona verdigi kisisel isim, opsiyonel)
  // ==========================================================================

  Future<Map<int, String>> zonTakmaAdlariGetir() async {
    final tercihler = await _tercihler;
    final ham = tercihler.getString(_zonTakmaAdlariAnahtari);
    if (ham == null) return {};
    final harita = jsonDecode(ham) as Map<String, dynamic>;
    return harita.map((k, v) => MapEntry(int.parse(k), v as String));
  }

  Future<void> zonTakmaAdlariniKaydet(Map<int, String> takmaAdlar) async {
    final tercihler = await _tercihler;
    final harita = takmaAdlar.map((k, v) => MapEntry(k.toString(), v));
    await tercihler.setString(_zonTakmaAdlariAnahtari, jsonEncode(harita));
  }
}
