/// AquaGuard - Uygulama Durumu (GECICI FACADE, Mimari Bolunme Faz 12)
/// ======================================================================
///
/// Amac:
///   Bu sinif ARTIK gercek durumu TUTMUYOR -- eskiden 1300+ satirlik bir
///   "God Object" olan bu provider, 6 kucuk/odakli provider'a bolundu
///   (bkz. ayarlar_provider.dart, tarla_provider.dart, guvenlik_provider.dart,
///   bakim_provider.dart, aktivite_bildirim_provider.dart,
///   cihaz_iletisim_provider.dart -- her birinin dosya basi notu KENDI
///   sorumluluk alanini ve boluunme gerekcesini aciklar).
///
///   Bu facade GECICIDIR: 76 dosya (42 lib + 34 test) hala
///   `context.watch<UygulamaDurumu>()` / `Provider.of<UygulamaDurumu>()`
///   uzerinden calisiyor -- hepsini TEK seferde 6 yeni provider'a tasimak
///   riskli bir "big bang" degisiklik olurdu. Bunun yerine: TUM eski genel
///   API (getter/metod imzalari) BIREBIR korunur, her cagri ilgili yeni
///   provider'a DELEGE edilir. Ekranlar zamanla (en yuksek trafikliden
///   baslanarak) dogrudan ilgili yeni provider'a tasindikca, bu facade'a
///   olan bagimlilik azalir; TUM ekranlar tasindiginda bu dosya kaldirilir.
///
///   ChangeNotifier OLARAK KALIR (Provider'in bekledigi tip), ama kendi
///   durumunu TUTMAZ -- 6 alt provider'dan herhangi biri degisince
///   (`addListener` ile dinlenir) kendi `notifyListeners()`'ini tetikler,
///   boylece hala bu facade'i dinleyen (henuz tasinmamis) ekranlar da
///   dogru zamanda yeniden cizilir.
///
/// Tarih:  2026-09-01 (ilk yazim) / 2026-09-17 (facade'a donusturuldu)
library;

import 'package:flutter/foundation.dart';

import '../models/aksan_rengi.dart';
import '../models/aktivite_kaydi.dart';
import '../models/bakim_gorevi.dart';
import '../models/bekleyen_komut.dart';
import '../models/bildirim_tercihleri.dart';
import '../models/demo_hizi.dart';
import '../models/kullanici_profili.dart';
import '../models/maliyet_parametreleri.dart';
import '../models/sensor_okuma.dart';
import '../models/tarla.dart';
import '../models/tarla_notu.dart';
import '../models/tema_modu.dart';
import '../models/uygulama_dili.dart';
import '../repositories/drift_aktivite_bildirim_repository.dart';
import '../repositories/drift_sensor_okuma_repository.dart';
import '../repositories/drift_tarla_notu_repository.dart';
import '../services/mqtt_servisi.dart';
import '../services/veri_migrasyon_servisi.dart';
import '../services/veritabani.dart';
import 'aktivite_bildirim_provider.dart';
import 'ayarlar_provider.dart';
import 'bakim_provider.dart';
import 'cihaz_iletisim_provider.dart';
import 'depolama_unawaited.dart';
import 'guvenlik_provider.dart';
import 'tarla_provider.dart';

export '../services/mqtt_servisi.dart' show MqttBaglantiDurumu;
export 'cihaz_iletisim_provider.dart' show DemoSenaryosu, ZonDurumOzeti;

class UygulamaDurumu extends ChangeNotifier {
  // Alt provider'lar disaridan enjekte EDILMEZ -- bu facade'in TEK
  // gorevi, eski `UygulamaDurumu()` (parametresiz) genel API'sini 76
  // tuketici dosya (42 lib + 34 test) icin DEGISTIRMEDEN korumaktir.
  // TarlaProvider'in callback'leri (bkz. o dosyanin dosya basi notu)
  // CihazIletisimProvider'a `late final` araciligiyla GECIKMELI referans
  // verir -- callback'ler ancak tarlaEkle/tarlaSil cagrildiginda (yani
  // baslat() TAMAMLANDIKTAN sonra) TETIKLENDIGI icin bu guvenlidir,
  // gercek bir dongusel bagimlilik OLUSTURMAZ.
  // SQLite (drift, Faz 13): surekli buyuyen 4 koleksiyon (sensor gecmisi,
  // aktivite/bildirim gecmisi, tarla notlari) icin TEK veritabani baglantisi --
  // bkz. veritabani.dart dosya basi notu. Ilgili 3 provider'a Drift tabanli
  // repository'ler olarak enjekte edilir (bkz. asagisi). Opsiyonel olarak
  // DISARIDAN enjekte edilebilir -- SADECE testlerin "uygulamayi kapat/
  // yeniden ac" senaryosunu (iki ayri UygulamaDurumu ornegi, AYNI kalici
  // depoyu paylasmali) simule edebilmesi icin; 74/76 cagiran dosya bunu
  // KULLANMAZ, parametresiz `UygulamaDurumu()` DEGISMEDEN calismaya devam eder.
  final AquaGuardVeritabani _veritabani;
  final bool _veritabaniSahibi;

  final AyarlarProvider _ayarlar = AyarlarProvider();
  late final TarlaProvider _tarla = TarlaProvider(
    notDepo: DriftTarlaNotuRepository(_veritabani),
    zonlarEklendiginde: (zonlar) => _cihaz.zonlarEklendi(zonlar),
    zonlarYetimKaldiginda: (zonlar) => _cihaz.zonlarYetimKaldi(zonlar),
  );
  final GuvenlikProvider _guvenlik = GuvenlikProvider();
  final BakimProvider _bakim = BakimProvider();
  late final AktiviteBildirimProvider _aktivite = AktiviteBildirimProvider(
    ayarlar: _ayarlar,
    depo: DriftAktiviteBildirimRepository(_veritabani),
  );
  late final CihazIletisimProvider _cihaz = CihazIletisimProvider(
    tarla: _tarla,
    aktivite: _aktivite,
    sensorDepo: DriftSensorOkumaRepository(_veritabani),
  );

  UygulamaDurumu({AquaGuardVeritabani? veritabani})
    : _veritabani = veritabani ?? AquaGuardVeritabani(),
      _veritabaniSahibi = veritabani == null {
    _ayarlar.addListener(notifyListeners);
    _tarla.addListener(notifyListeners);
    _guvenlik.addListener(notifyListeners);
    _bakim.addListener(notifyListeners);
    _aktivite.addListener(notifyListeners);
    _cihaz.addListener(notifyListeners);
  }

  // ============================================================================
  // ALT PROVIDER ERISIMI (Faz 14 -- performans/context.select gecisi)
  // ============================================================================
  //
  // main.dart, bunlari MultiProvider ile AYRICA agaca ekler -- boylece
  // SADECE dar bir alani ilgilendiren ekranlar (orn. PinKilitEkrani sadece
  // PIN'i ilgilendirir, TarlaNotlariEkrani sadece tarla notlarini) artik
  // TUM facade'i (`context.watch<UygulamaDurumu>()`) DEGIL, dogrudan
  // ilgili tek provider'i izleyebilir -- boylece CihazIletisimProvider'in
  // her ~1.5 saniyede bir tetikledigi sensor guncellemesi (Demo Modu),
  // bu ekranlarin GEREKSIZ YERE yeniden cizilmesine artik sebep OLMAZ.
  AyarlarProvider get ayarlarProvider => _ayarlar;
  TarlaProvider get tarlaProvider => _tarla;
  GuvenlikProvider get guvenlikProvider => _guvenlik;
  BakimProvider get bakimProvider => _bakim;
  AktiviteBildirimProvider get aktiviteProvider => _aktivite;
  CihazIletisimProvider get cihazProvider => _cihaz;

  /// Once (SharedPreferences'tan SQLite'a) tek seferlik veri migrasyonunu,
  /// SONRA alti alt provider'i dogru bagimlilik sirasiyla baslatir
  /// (main.dart'ta tek tek cagirmak yerine, gecis suresince tek bir giris
  /// noktasi).
  Future<void> baslat() async {
    await VeriMigrasyonServisi(_veritabani).gerekirseMigrateEt();
    await _ayarlar.baslat();
    await _tarla.baslat();
    await _guvenlik.baslat();
    await _bakim.baslat();
    await _aktivite.baslat();
    await _cihaz.baslat();
  }

  // ============================================================================
  // AYARLAR PROVIDER
  // ============================================================================

  bool get onboardingGoruldu => _ayarlar.onboardingGoruldu;
  Future<void> onboardingiTamamla() => _ayarlar.onboardingiTamamla();

  TemaModu get temaModu => _ayarlar.temaModu;
  Future<void> temaModuAyarla(TemaModu modu) => _ayarlar.temaModuAyarla(modu);

  AksanRengi get aksanRengi => _ayarlar.aksanRengi;
  Future<void> aksanRengiAyarla(AksanRengi aksan) =>
      _ayarlar.aksanRengiAyarla(aksan);

  bool get sahaModuAktif => _ayarlar.sahaModuAktif;
  Future<void> sahaModuAyarla(bool acik) => _ayarlar.sahaModuAyarla(acik);

  KullaniciProfili get kullaniciProfili => _ayarlar.kullaniciProfili;
  Future<void> kullaniciProfiliniGuncelle(KullaniciProfili profil) =>
      _ayarlar.kullaniciProfiliniGuncelle(profil);

  MaliyetParametreleri get maliyetParametreleri =>
      _ayarlar.maliyetParametreleri;
  Future<void> maliyetParametreleriniGuncelle(
    MaliyetParametreleri parametreler,
  ) => _ayarlar.maliyetParametreleriniGuncelle(parametreler);

  UygulamaDili get uygulamaDili => _ayarlar.uygulamaDili;
  Future<void> uygulamaDiliniAyarla(UygulamaDili dil) =>
      _ayarlar.uygulamaDiliniAyarla(dil);

  BildirimTercihleri get bildirimTercihleri => _ayarlar.bildirimTercihleri;
  Future<void> bildirimTercihleriniGuncelle(BildirimTercihleri yeni) =>
      _ayarlar.bildirimTercihleriniGuncelle(yeni);

  // ============================================================================
  // TARLA PROVIDER
  // ============================================================================

  List<Tarla> get tarlalar => _tarla.tarlalar;
  List<int> get tumZonNumaralari => _tarla.tumZonNumaralari;
  String zonAdiGetir(int zone) => _tarla.zonAdiGetir(zone);
  List<TarlaNotu> tarlaNotlari(String tarlaId) =>
      _tarla.tarlaNotlari(tarlaId);

  Future<void> tarlaEkle(Tarla tarla) => _tarla.tarlaEkle(tarla);
  Future<void> tarlaSil(String id) => _tarla.tarlaSil(id);
  Future<void> tarlaGuncelle(Tarla guncelTarla) =>
      _tarla.tarlaGuncelle(guncelTarla);
  Future<void> notEkle(String tarlaId, String metin) =>
      _tarla.notEkle(tarlaId, metin);
  Future<void> notSil(String notId) => _tarla.notSil(notId);
  Future<void> zonTakmaAdiAyarla(int zone, String? ad) =>
      _tarla.zonTakmaAdiAyarla(zone, ad);

  // ============================================================================
  // GUVENLIK PROVIDER (PIN)
  // ============================================================================

  bool get pinKorumasiAktif => _guvenlik.pinKorumasiAktif;
  bool get pinKilitliSuAn => _guvenlik.pinKilitliSuAn;
  bool get pinGirisiKilitliMi => _guvenlik.pinGirisiKilitliMi;
  Duration? get pinKilidiKalanSure => _guvenlik.pinKilidiKalanSure;

  Future<void> pinKorumasiniAc(String yeniPin) =>
      _guvenlik.pinKorumasiniAc(yeniPin);
  Future<void> pinKorumasiniKapat() => _guvenlik.pinKorumasiniKapat();
  Future<bool> pinDenemesiYap(String girilen) =>
      _guvenlik.pinDenemesiYap(girilen);
  void pinKilidiniBiyometrikIleAc() => _guvenlik.pinKilidiniBiyometrikIleAc();

  // ============================================================================
  // BAKIM PROVIDER
  // ============================================================================

  List<BakimGorevi> get bakimGorevleri => _bakim.bakimGorevleri;
  bool get bakimUyarisiVarMi => _bakim.bakimUyarisiVarMi;
  Future<void> bakimGoreviTamamlandiIsaretle(String gorevId) =>
      _bakim.bakimGoreviTamamlandiIsaretle(gorevId);

  // ============================================================================
  // AKTIVITE/BILDIRIM PROVIDER
  // ============================================================================

  List<AktiviteKaydi> get aktiviteGecmisi => _aktivite.aktiviteGecmisi;
  List<AktiviteKaydi> get bildirimGecmisi => _aktivite.bildirimGecmisi;
  int get okunmamisBildirimSayisi => _aktivite.okunmamisBildirimSayisi;
  bool bildirimOkunmusMu(AktiviteKaydi kayit) =>
      _aktivite.bildirimOkunmusMu(kayit);
  List<AktiviteKaydi> bildirimleriAlVeTemizle() =>
      _aktivite.bildirimleriAlVeTemizle();
  Future<void> bildirimleriOkunduIsaretle() =>
      _aktivite.bildirimleriOkunduIsaretle();

  // ============================================================================
  // CIHAZ ILETISIM PROVIDER
  // ============================================================================

  bool get hazir => _cihaz.hazir;
  bool get demoModuAktif => _cihaz.demoModuAktif;
  DemoHizi get demoHizi => _cihaz.demoHizi;
  String get mqttHost => _cihaz.mqttHost;
  int get mqttPort => _cihaz.mqttPort;
  bool get mqttGuvenli => _cihaz.mqttGuvenli;
  MqttBaglantiDurumu get baglantiDurumu => _cihaz.baglantiDurumu;
  bool get cihazBagliMi => _cihaz.cihazBagliMi;

  SensorOkuma? sonOkuma(int zone) => _cihaz.sonOkuma(zone);
  bool zonCevrimiciMi(int zone) => _cihaz.zonCevrimiciMi(zone);
  List<SensorOkuma> gecmis(int zone) => _cihaz.gecmis(zone);
  DateTime? tedaviBaslangicZamani(int zone) =>
      _cihaz.tedaviBaslangicZamani(zone);
  bool sulamasiDurduruldu(int zone) => _cihaz.sulamasiDurduruldu(zone);
  List<SensorOkuma> get tumOkumalarBirlesik => _cihaz.tumOkumalarBirlesik;
  Map<TedaviTuru, int> get tedaviSayaclari => _cihaz.tedaviSayaclari;
  ZonDurumOzeti durumOzetiHesapla(List<int> zonlar) =>
      _cihaz.durumOzetiHesapla(zonlar);

  Future<void> demoModunuAc() => _cihaz.demoModunuAc();
  Future<void> demoModunuKapat() => _cihaz.demoModunuKapat();
  Future<void> demoHiziniAyarla(DemoHizi hiz) =>
      _cihaz.demoHiziniAyarla(hiz);
  Future<void> mqttAyarlariniGuncelle({
    required String host,
    required int port,
    required bool guvenli,
  }) => _cihaz.mqttAyarlariniGuncelle(host: host, port: port, guvenli: guvenli);

  Future<KomutSonucu> manuelTedaviBaslat(int zone, TedaviTuru tedavi) =>
      _cihaz.manuelTedaviBaslat(zone, tedavi);
  Future<void> manuelTedaviDurdur(int zone) =>
      _cihaz.manuelTedaviDurdur(zone);
  Future<void> manuelNormaleDondur(int zone) =>
      _cihaz.manuelNormaleDondur(zone);

  Future<void> sulamayiDurdur(int zone) => _cihaz.sulamayiDurdur(zone);
  Future<void> sulamayiBaslat(int zone) => _cihaz.sulamayiBaslat(zone);
  Future<List<int>> acilDurdurmaTetikle() => _cihaz.acilDurdurmaTetikle();

  Future<void> demoSenaryosuTetikle(DemoSenaryosu senaryo) =>
      _cihaz.demoSenaryosuTetikle(senaryo);

  @override
  void dispose() {
    // Facade alt provider'lari SAHIPLENIR (main.dart bunlari ayrica
    // Provider agacina KOYMUYOR) -- bu yuzden burada sadece listener'lari
    // degil, ChangeNotifier.dispose()'lari da cagirmak gerekir. AKSI
    // HALDE CihazIletisimProvider'in MQTT baglantisi/Demo Modu simulasyon
    // Timer'i asla durmaz (ozellikle testlerde "Timer is still pending
    // even after the widget tree was disposed" hatasina yol acar).
    _ayarlar.removeListener(notifyListeners);
    _tarla.removeListener(notifyListeners);
    _guvenlik.removeListener(notifyListeners);
    _bakim.removeListener(notifyListeners);
    _aktivite.removeListener(notifyListeners);
    _cihaz.removeListener(notifyListeners);
    _ayarlar.dispose();
    _tarla.dispose();
    _guvenlik.dispose();
    _bakim.dispose();
    _aktivite.dispose();
    _cihaz.dispose();
    // Enjekte edilmis (paylasilan) bir veritabani BASKA bir sahibin --
    // kapatmak, o sahibin altindaki veriyi de kapatirdi (bkz. yukaridaki
    // constructor notu).
    if (_veritabaniSahibi) {
      unawaited(_veritabani.close());
    }
    super.dispose();
  }
}
