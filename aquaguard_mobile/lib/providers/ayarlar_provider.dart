/// AquaGuard - Ayarlar Provider (Mimari Bolunme, Faz 12)
/// ============================================================
///
/// Amac:
///   Eskiden tek bir "God Object" olan UygulamaDurumu'nun (1300+ satir)
///   SADECE goruntu/tercih tarafini tasir: tema, aksan rengi, saha modu,
///   kullanici profili, maliyet parametreleri, uygulama dili, bildirim
///   tercihleri, onboarding durumu. Bilerek CIHAZ ILETISIMINDEN (MQTT/
///   Demo Modu, bkz. cihaz_iletisim_provider.dart) AYRIDIR -- demo modu/
///   MQTT ayarlari OPERASYONEL olarak baglanti yasam dongusune sikica
///   bagli olduğu icin orada kalir, burada DEGIL (bkz. o dosyanin dosya
///   basi notu, bu ayrimin gerekcesi).
///
///   Bu provider degisince SADECE Ayarlar/Genel Bakis gibi bu veriyi
///   gosteren widget'lar yeniden cizilir -- eskiden PIN ayari degistiginde
///   bile TUM sensor dashboard'u yeniden ciziliyordu (tek buyuk
///   ChangeNotifier), bu artik olmuyor.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/foundation.dart';

import '../models/aksan_rengi.dart';
import '../models/bildirim_tercihleri.dart';
import '../models/kullanici_profili.dart';
import '../models/maliyet_parametreleri.dart';
import '../models/tema_modu.dart';
import '../models/uygulama_dili.dart';
import '../services/depolama_servisi.dart';

class AyarlarProvider extends ChangeNotifier {
  final DepolamaServisi _depolama;

  AyarlarProvider({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  bool _onboardingGoruldu = false;
  TemaModu _temaModu = TemaModu.koyu;
  AksanRengi _aksanRengi = AksanRengi.teal;
  bool _sahaModuAktif = false;
  bool _titresimAktif = true;
  KullaniciProfili _kullaniciProfili = const KullaniciProfili();
  MaliyetParametreleri _maliyetParametreleri = const MaliyetParametreleri();
  UygulamaDili _uygulamaDili = UygulamaDili.turkce;
  BildirimTercihleri _bildirimTercihleri = const BildirimTercihleri();

  bool get onboardingGoruldu => _onboardingGoruldu;
  TemaModu get temaModu => _temaModu;
  AksanRengi get aksanRengi => _aksanRengi;
  bool get sahaModuAktif => _sahaModuAktif;
  bool get titresimAktif => _titresimAktif;
  KullaniciProfili get kullaniciProfili => _kullaniciProfili;
  MaliyetParametreleri get maliyetParametreleri => _maliyetParametreleri;
  UygulamaDili get uygulamaDili => _uygulamaDili;
  BildirimTercihleri get bildirimTercihleri => _bildirimTercihleri;

  Future<void> baslat() async {
    _onboardingGoruldu = await _depolama.onboardingGorulduMu();
    _temaModu = await _depolama.temaModuGetir();
    _aksanRengi = await _depolama.aksanRengiGetir();
    _sahaModuAktif = await _depolama.sahaModuGetir();
    _titresimAktif = await _depolama.titresimAktifMi();
    _maliyetParametreleri = await _depolama.maliyetParametreleriGetir();
    _uygulamaDili = await _depolama.uygulamaDiliGetir();
    _kullaniciProfili = await _depolama.kullaniciProfiliGetir();
    _bildirimTercihleri = await _depolama.bildirimTercihleriniGetir();
    notifyListeners();
  }

  Future<void> onboardingiTamamla() async {
    if (_onboardingGoruldu) return;
    _onboardingGoruldu = true;
    await _depolama.onboardingGorulduOlarakIsaretle();
    notifyListeners();
  }

  Future<void> temaModuAyarla(TemaModu modu) async {
    _temaModu = modu;
    await _depolama.temaModuKaydet(modu);
    notifyListeners();
  }

  Future<void> aksanRengiAyarla(AksanRengi aksan) async {
    _aksanRengi = aksan;
    await _depolama.aksanRengiKaydet(aksan);
    notifyListeners();
  }

  Future<void> sahaModuAyarla(bool acik) async {
    _sahaModuAktif = acik;
    await _depolama.sahaModuKaydet(acik);
    notifyListeners();
  }

  Future<void> titresimGeriBildirimiAyarla(bool acik) async {
    _titresimAktif = acik;
    await _depolama.titresimAyarlaKaydet(acik);
    notifyListeners();
  }

  Future<void> maliyetParametreleriniGuncelle(
    MaliyetParametreleri parametreler,
  ) async {
    _maliyetParametreleri = parametreler;
    await _depolama.maliyetParametreleriKaydet(parametreler);
    notifyListeners();
  }

  Future<void> uygulamaDiliniAyarla(UygulamaDili dil) async {
    _uygulamaDili = dil;
    await _depolama.uygulamaDiliKaydet(dil);
    notifyListeners();
  }

  Future<void> kullaniciProfiliniGuncelle(KullaniciProfili profil) async {
    _kullaniciProfili = profil;
    await _depolama.kullaniciProfiliniKaydet(profil);
    notifyListeners();
  }

  Future<void> bildirimTercihleriniGuncelle(BildirimTercihleri yeni) async {
    _bildirimTercihleri = yeni;
    await _depolama.bildirimTercihleriniKaydet(yeni);
    notifyListeners();
  }
}
