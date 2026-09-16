/// AquaGuard - Tarla Provider (Mimari Bolunme, Faz 12)
/// ==========================================================
///
/// Amac:
///   Tarla/zon listesi, tarla notlari ve zon takma adlarini tasir.
///   CihazIletisimProvider'dan (bkz. o dosyanin dosya basi notu) BILEREK
///   AYRIDIR -- tarla EKLEME/SILME/DUZENLEME islemleri, cihaz baglantisini
///   (MQTT/Demo Modu) ETKILEMESI GEREKTIGINDE (orn. yeni zon eklenince
///   abonelik acilmasi) bunu bir CALLBACK araciligiyla bildirir, dogrudan
///   CihazIletisimProvider'a BAGIMLI DEGILDIR -- boylece iki provider
///   birbirini import ETMEZ, tek yonlu bir bagimlilik (main.dart'ta
///   kurulur) yeterlidir.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/foundation.dart';

import '../models/tarla.dart';
import '../models/tarla_notu.dart';
import '../repositories/tarla_notu_repository.dart';
import '../services/depolama_servisi.dart';
import 'depolama_unawaited.dart';

class TarlaProvider extends ChangeNotifier {
  final DepolamaServisi _depolama;
  final TarlaNotuRepository _notDepo;

  /// Bir tarla eklendiginde/guncellendiginde YENI zon numaralarini
  /// (aktif baglantiya hemen dahil edilmesi icin) bildirir. Tarla
  /// silindiginde ARTIK HICBIR tarlada kullanilmayan (yetim kalan) zon
  /// numaralarini bildirir -- cagiran taraf (main.dart'ta
  /// CihazIletisimProvider'a baglanir) onbellek/gecmis verisini temizler.
  final void Function(List<int> yeniZonlar)? zonlarEklendiginde;
  final void Function(List<int> yetimZonlar)? zonlarYetimKaldiginda;

  TarlaProvider({
    DepolamaServisi? depolama,
    TarlaNotuRepository? notDepo,
    this.zonlarEklendiginde,
    this.zonlarYetimKaldiginda,
  }) : _depolama = depolama ?? DepolamaServisi(),
       _notDepo = notDepo ?? SharedPreferencesTarlaNotuRepository();

  List<Tarla> _tarlalar = [];
  final List<TarlaNotu> _tarlaNotlari = [];
  final Map<int, String> _zonTakmaAdlari = {};

  List<Tarla> get tarlalar => List.unmodifiable(_tarlalar);

  /// Tum tarlalardaki tum zon numaralarinin tekil (benzersiz) listesi.
  List<int> get tumZonNumaralari {
    final kume = <int>{};
    for (final tarla in _tarlalar) {
      kume.addAll(tarla.zonNumaralari);
    }
    return kume.toList()..sort();
  }

  /// Zonun operator tarafindan verilmis takma adi varsa onu, yoksa
  /// varsayilan "Zon N" bicimini doner -- tum ekranlar zon basligini
  /// GOSTERIRKEN bu fonksiyonu kullanmalidir (tek kaynak).
  String zonAdiGetir(int zone) => _zonTakmaAdlari[zone] ?? 'Zon $zone';

  /// Verilen tarlaya ait notlar, EN YENI ONCE.
  List<TarlaNotu> tarlaNotlari(String tarlaId) {
    final liste = _tarlaNotlari.where((n) => n.tarlaId == tarlaId).toList()
      ..sort((a, b) => b.zaman.compareTo(a.zaman));
    return List.unmodifiable(liste);
  }

  Future<void> baslat() async {
    _tarlalar = await _depolama.tarlalariGetir();
    _tarlaNotlari
      ..clear()
      ..addAll(await _notDepo.tarlaNotlariGetir());
    _zonTakmaAdlari
      ..clear()
      ..addAll(await _depolama.zonTakmaAdlariGetir());
    notifyListeners();
  }

  Future<void> tarlaEkle(Tarla tarla) async {
    _tarlalar = [..._tarlalar, tarla];
    await _depolama.tarlalariKaydet(_tarlalar);
    zonlarEklendiginde?.call(tarla.zonNumaralari);
    notifyListeners();
  }

  Future<void> tarlaSil(String id) async {
    final silinenTarla = _tarlalar.firstWhere((t) => t.id == id);
    _tarlalar = _tarlalar.where((t) => t.id != id).toList();
    await _depolama.tarlalariKaydet(_tarlalar);

    // Silinen tarlanin notlari da yetim kalir -- baska hicbir tarla ID'si
    // asla ayni degeri tekrar kullanmayacagindan (zon numaralarinin aksine),
    // burada temizlemezsek notlar SESSIZCE sonsuza kadar depoda birikir.
    final notSilindiMi = _tarlaNotlari.any((n) => n.tarlaId == id);
    if (notSilindiMi) {
      _tarlaNotlari.removeWhere((n) => n.tarlaId == id);
      unawaited(_notDepo.tarlaNotlariniKaydet(_tarlaNotlari));
    }

    // Silinen tarlanin zonlarindan HALA baska bir tarlada kullanilanlari
    // koru; kalanlari (artik yetim) cagirana bildir (bkz. dosya basi notu).
    final halaKullanilanZonlar = _tarlalar
        .expand((t) => t.zonNumaralari)
        .toSet();
    final yetimZonlar = silinenTarla.zonNumaralari
        .where((z) => !halaKullanilanZonlar.contains(z))
        .toList();
    if (yetimZonlar.isNotEmpty) {
      zonlarYetimKaldiginda?.call(yetimZonlar);
    }

    notifyListeners();
  }

  Future<void> tarlaGuncelle(Tarla guncelTarla) async {
    _tarlalar = _tarlalar
        .map((t) => t.id == guncelTarla.id ? guncelTarla : t)
        .toList();
    await _depolama.tarlalariKaydet(_tarlalar);
    zonlarEklendiginde?.call(guncelTarla.zonNumaralari);
    notifyListeners();
  }

  Future<void> notEkle(String tarlaId, String metin) async {
    final temiz = metin.trim();
    if (temiz.isEmpty) return;
    _tarlaNotlari.insert(
      0,
      TarlaNotu(
        id: 'not-${DateTime.now().microsecondsSinceEpoch}',
        tarlaId: tarlaId,
        metin: temiz,
        zaman: DateTime.now(),
      ),
    );
    await _notDepo.tarlaNotlariniKaydet(_tarlaNotlari);
    notifyListeners();
  }

  Future<void> notSil(String notId) async {
    _tarlaNotlari.removeWhere((n) => n.id == notId);
    await _notDepo.tarlaNotlariniKaydet(_tarlaNotlari);
    notifyListeners();
  }

  Future<void> zonTakmaAdiAyarla(int zone, String? ad) async {
    final temiz = ad?.trim();
    if (temiz == null || temiz.isEmpty) {
      _zonTakmaAdlari.remove(zone);
    } else {
      _zonTakmaAdlari[zone] = temiz;
    }
    await _depolama.zonTakmaAdlariniKaydet(_zonTakmaAdlari);
    notifyListeners();
  }
}
