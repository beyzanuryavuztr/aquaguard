/// AquaGuard - Mod Ayrimli Repository'ler (K7)
/// ================================================
///
/// Amac:
///   Demo Modu SENTETIK veri uretir (12 gunluk gecmis + canli simulasyon
///   okumalari); gercek MQTT modu ise GERCEK cihaz verisi. Ikisi ayni
///   depoda karisirsa, gercek sahada calisan biri sahte tikanma
///   olaylari/tedaviler/basari oranlariyla karisik istatistik gorurdu ve
///   demoya gecip donmek gercek gecmisi kirletirdi. Bu yuzden iki AYRI
///   veritabani tutulur; bu siniflar, o anki moda gore dogru olana yonlendirir.
///
///   [VeriModu.demo] tek dogruluk kaynagidir: UygulamaDurumu baslarken ve
///   mod degisirken gunceller; depolar HER cagrida bakar.
library;

import '../models/aktivite_kaydi.dart';
import '../models/sensor_okuma.dart';
import 'aktivite_bildirim_repository.dart';
import 'sensor_okuma_repository.dart';

class VeriModu {
  bool demo;
  VeriModu({this.demo = true});
}

class ModluSensorOkumaRepository implements SensorOkumaRepository {
  final SensorOkumaRepository demo;
  final SensorOkumaRepository gercek;
  final VeriModu mod;

  ModluSensorOkumaRepository({
    required this.demo,
    required this.gercek,
    required this.mod,
  });

  SensorOkumaRepository get _aktif => mod.demo ? demo : gercek;

  @override
  Future<List<SensorOkuma>> gecmisiGetir(int zone) => _aktif.gecmisiGetir(zone);

  @override
  Future<void> gecmisiTopluKaydet(int zone, List<SensorOkuma> gecmis) =>
      _aktif.gecmisiTopluKaydet(zone, gecmis);

  @override
  Future<void> gecmiseEkle(SensorOkuma okuma) => _aktif.gecmiseEkle(okuma);

  @override
  Future<SensorOkuma?> sonOkumayiGetir(int zone) =>
      _aktif.sonOkumayiGetir(zone);

  @override
  Future<void> sonOkumayiKaydet(SensorOkuma okuma) =>
      _aktif.sonOkumayiKaydet(okuma);

  /// Zon silindiginde HER IKI modun verisi de temizlenir (zon artik yok).
  @override
  Future<void> zonVerisiniTemizle(int zone) async {
    await demo.zonVerisiniTemizle(zone);
    await gercek.zonVerisiniTemizle(zone);
  }
}

class ModluAktiviteBildirimRepository implements AktiviteBildirimRepository {
  final AktiviteBildirimRepository demo;
  final AktiviteBildirimRepository gercek;
  final VeriModu mod;

  ModluAktiviteBildirimRepository({
    required this.demo,
    required this.gercek,
    required this.mod,
  });

  AktiviteBildirimRepository get _aktif => mod.demo ? demo : gercek;

  @override
  Future<List<AktiviteKaydi>> aktiviteGecmisiGetir() =>
      _aktif.aktiviteGecmisiGetir();

  @override
  Future<void> aktiviteGecmisiniKaydet(List<AktiviteKaydi> gecmis) =>
      _aktif.aktiviteGecmisiniKaydet(gecmis);

  @override
  Future<List<AktiviteKaydi>> bildirimGecmisiGetir() =>
      _aktif.bildirimGecmisiGetir();

  @override
  Future<void> bildirimGecmisiniKaydet(List<AktiviteKaydi> gecmis) =>
      _aktif.bildirimGecmisiniKaydet(gecmis);

  @override
  Future<Set<int>> okunmusBildirimIdleriGetir() =>
      _aktif.okunmusBildirimIdleriGetir();

  @override
  Future<void> okunmusBildirimIdleriniKaydet(Set<int> idler) =>
      _aktif.okunmusBildirimIdleriniKaydet(idler);
}
