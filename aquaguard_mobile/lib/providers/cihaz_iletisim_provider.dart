/// AquaGuard - Cihaz Iletisim Provider (Mimari Bolunme, Faz 12)
/// ===================================================================
///
/// Amac:
///   Eski "God Object" UygulamaDurumu'nun (bkz. ayarlar_provider.dart
///   dosya basi notu) EN BUYUK, EN COHESIVE dilimini tasir: cihazla
///   (gercek MQTT veya Demo Modu simulasyonu) ILETISIMLE ilgili HER SEY --
///   baglanti yasam dongusu, sensor verisi alimi, manuel mudahale (tedavi
///   baslat/durdur, sulama kontrolu, acil durdurma), komut ACK/NACK,
///   offline komut kuyrugu, demo senaryo tetikleme.
///
///   BILINCLI TASARIM KARARI: bu alanlarin AYRI provider'lara (orn.
///   "SensorVeriProvider" + "MudahaleProvider" + "OfflineProvider")
///   bolunmesi DUSUNULDU ama REDDEDILDI -- hepsi AYNI iki nesneyi
///   (_mqtt, _simulasyon) dogrudan MANIPULE ediyor, gercek kod
///   COHESION'i burada, "cihazla nasil konusuruz" sorusunda. Yapay bir
///   bolunme, provider'lar arasi asiri capraz-referans/callback zinciri
///   yaratirdi (kod OKUNABILIRLIGINI ARTIRMAZ, sadece DAGITIRDI). Bunun
///   yerine MQTT host/port/guvenli VE demo modu/hizi da (konsept olarak
///   "ayar" olsa bile) BURADA tutulur -- cunku OPERASYONEL olarak
///   baglanti yasam donguisune sikica bagli (bir ayar degisince BURASI
///   yeniden baglanmalidir).
///
///   TarlaProvider'a (zon listesi icin) ve AktiviteBildirimProvider'a
///   (olay kaydi/bildirim icin) REFERANS tutar -- main.dart'ta kurulur.
///
/// Tarih:  2026-09-16
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/ayarlar_sabitleri.dart';
import '../models/aktivite_kaydi.dart';
import '../models/bekleyen_komut.dart';
import '../models/demo_hizi.dart';
import '../models/kuyruklanmis_komut.dart';
import '../models/sensor_okuma.dart';
import '../repositories/sensor_okuma_repository.dart';
import '../repositories/modlu_repolar.dart';
import '../services/bildirim_servisi.dart';
import '../services/depolama_servisi.dart';
import '../services/gecmis_veri_uretici.dart';
import '../services/mqtt_kimlik_servisi.dart';
import '../services/mqtt_servisi.dart';
import '../services/simulasyon_servisi.dart';
import '../widgets/durum_renkleri.dart';
import 'aktivite_bildirim_provider.dart';
import 'depolama_unawaited.dart';
import 'tarla_provider.dart';

class CihazIletisimProvider extends ChangeNotifier {
  final DepolamaServisi _depolama;
  final SensorOkumaRepository _sensorDepo;
  final TarlaProvider _tarla;
  final AktiviteBildirimProvider _aktivite;
  // Demo/Gercek veri deposu ayrimi (K7, bkz. repositories/modlu_repolar.dart).
  final VeriModu _veriModu;

  CihazIletisimProvider({
    required TarlaProvider tarla,
    required AktiviteBildirimProvider aktivite,
    DepolamaServisi? depolama,
    SensorOkumaRepository? sensorDepo,
    VeriModu? veriModu,
  }) : _depolama = depolama ?? DepolamaServisi(),
       _veriModu = veriModu ?? VeriModu(),
       _sensorDepo = sensorDepo ?? SharedPreferencesSensorOkumaRepository(),
       // ignore: prefer_initializing_formals
       _tarla = tarla,
       // ignore: prefer_initializing_formals
       _aktivite = aktivite;

  MqttServisi? _mqtt;
  SimulasyonServisi? _simulasyon;
  bool _demoModuAktif = true;
  DemoHizi _demoHizi = DemoHizi.normal;
  bool _hazir = false;

  String _mqttHost = '';
  int _mqttPort = 0;
  bool _mqttGuvenli = false;
  String _mqttKullaniciAdi = "";
  String _mqttParola = "";
  MqttBaglantiDurumu _baglantiDurumu = MqttBaglantiDurumu.baglaniyor;
  bool _cihazBagliMi = true;
  StreamSubscription<List<ConnectivityResult>>? _baglantiAboneligi;

  final Map<int, SensorOkuma> _sonOkumalar = {};
  final Map<int, bool> _zonCevrimici = {};
  final Map<int, List<SensorOkuma>> _gecmisler = {};
  final Map<int, DateTime> _tedaviBaslangicZamanlari = {};
  final Set<int> _sulamasiDurdurulanZonlar = {};

  // Zon basina en son YEREL vana komutu zamani -- cihaz telemetrisi ile
  // esitleme, komut cihaza ulasip yansiyana kadar (bekleme suresi boyunca)
  // eski durumla yerel durumu ezmesin diye.
  final Map<int, DateTime> _vanaKomutZamanlari = {};

  final List<KuyruklanmisKomut> _kuyruklananKomutlar = [];
  final Map<String, Completer<KomutSonucu>> _bekleyenKomutlar = {};

  // ============================================================================
  // DISARIYA ACIK (READ-ONLY) DURUM
  // ============================================================================

  bool get hazir => _hazir;
  bool get demoModuAktif => _demoModuAktif;
  DemoHizi get demoHizi => _demoHizi;
  String get mqttHost => _mqttHost;
  int get mqttPort => _mqttPort;
  bool get mqttGuvenli => _mqttGuvenli;
  String get mqttKullaniciAdi => _mqttKullaniciAdi;

  /// Parola arayuze DUZ METIN olarak acilmaz (yalnizca 'tanimli mi' bilgisi).
  bool get mqttParolaTanimli => _mqttParola.isNotEmpty;
  MqttBaglantiDurumu get baglantiDurumu => _baglantiDurumu;
  bool get cihazBagliMi => _cihazBagliMi;

  SensorOkuma? sonOkuma(int zone) => _sonOkumalar[zone];
  bool zonCevrimiciMi(int zone) => _zonCevrimici[zone] ?? false;
  List<SensorOkuma> gecmis(int zone) =>
      List.unmodifiable(_gecmisler[zone] ?? const <SensorOkuma>[]);
  DateTime? tedaviBaslangicZamani(int zone) => _tedaviBaslangicZamanlari[zone];
  bool sulamasiDurduruldu(int zone) => _sulamasiDurdurulanZonlar.contains(zone);

  /// Tum zonlardaki tum gecmis okumalar tek bir listede (istatistik hesaplari icin).
  List<SensorOkuma> get tumOkumalarBirlesik {
    final liste = <SensorOkuma>[];
    for (final zon in _tarla.tumZonNumaralari) {
      liste.addAll(_gecmisler[zon] ?? const <SensorOkuma>[]);
    }
    return liste;
  }

  /// Tedavi sayilari (turlere gore), KALICI gecmisten HESAPLANIR (ayri bir
  /// sayac tutulmuyor) -- boylece uygulama yeniden acildiginda sifirlanmaz.
  Map<TedaviTuru, int> get tedaviSayaclari {
    final sayaclar = <TedaviTuru, int>{
      TedaviTuru.asitDozlama: 0,
      TedaviTuru.klorEnjeksiyon: 0,
      TedaviTuru.yuksekBasincliYikama: 0,
    };
    for (final zon in _tarla.tumZonNumaralari) {
      final kronolojik = (_gecmisler[zon] ?? const <SensorOkuma>[]).reversed;
      var oncekiTedavi = TedaviTuru.yok;
      for (final okuma in kronolojik) {
        if (okuma.tedaviAktif != TedaviTuru.yok &&
            oncekiTedavi == TedaviTuru.yok) {
          sayaclar[okuma.tedaviAktif] = (sayaclar[okuma.tedaviAktif] ?? 0) + 1;
        }
        oncekiTedavi = okuma.tedaviAktif;
      }
    }
    return sayaclar;
  }

  /// Verilen zon listesinin durum ozetini hesaplar (Genel Bakış ve Zon
  /// Dashboard ekranlarinin ikisi de bunu kullanir). Her zon TEK bir
  /// kovaya duser; siniflandirma DurumRenkleri.onceligiBelirle()'den gelir
  /// (tek kaynak).
  ZonDurumOzeti durumOzetiHesapla(List<int> zonlar) {
    var normal = 0,
        belirsiz = 0,
        tespitEdildi = 0,
        tedavide = 0,
        cevrimdisi = 0;
    for (final zon in zonlar) {
      final okuma = _sonOkumalar[zon];
      final cevrimici = _zonCevrimici[zon] ?? false;
      switch (DurumRenkleri.onceligiBelirle(
        okuma: okuma,
        cevrimici: cevrimici,
      )) {
        case ZonOnceligi.cevrimdisi:
          cevrimdisi++;
        case ZonOnceligi.tedavide:
          tedavide++;
        case ZonOnceligi.tespitEdildi:
          tespitEdildi++;
        case ZonOnceligi.belirsiz:
          belirsiz++;
        case ZonOnceligi.normal:
          normal++;
      }
    }
    return ZonDurumOzeti(
      normal: normal,
      belirsiz: belirsiz,
      tespitEdildi: tespitEdildi,
      tedavide: tedavide,
      cevrimdisi: cevrimdisi,
    );
  }

  // ============================================================================
  // BASLATMA
  // ============================================================================
  //
  // NOT: cagirilmadan ONCE _tarla.baslat() VE _aktivite.baslat() TAMAMLANMIS
  // OLMALIDIR (main.dart'taki orkestrasyon sirasi bunu garanti eder) --
  // bu fonksiyon zon listesini _tarla'dan okur, seed edilen aktiviteleri
  // _aktivite'ye yazar.

  /// AKTIF modun (Demo ya da Gercek) kalici verisini yukler: zon basina sensor
  /// gecmisi + son okuma. SENTETIK gecmis SADECE Demo Modu'nda uretilir (K7):
  /// gercek modda bos depo bos kalir -- ekranlar "veri yok" gosterir, sahte
  /// tikanma olaylari/istatistik uretilmez.
  Future<void> _modVerisiniYukle() async {
    for (final zon in _tarla.tumZonNumaralari) {
      var gecmis = await _sensorDepo.gecmisiGetir(zon);

      // Demo Modu'nda HIC gecmis yoksa (ilk kurulum): sanki sistem gunlerdir
      // sahada calisiyormus gibi GECMISE DONUK sentetik bir gecmis uret --
      // trend grafikleri/istatistikler ilk acilista bile dolu gorunur.
      if (gecmis.isEmpty && _demoModuAktif) {
        final kronolojikGecmis = GecmisVeriUreticisi.zonGecmisiUret(zon);
        gecmis = kronolojikGecmis.reversed
            .toList(); // depolama EN YENI ONCE bekler
        unawaited(_sensorDepo.gecmisiTopluKaydet(zon, gecmis));

        final uretilenAktiviteler = GecmisVeriUreticisi.aktiviteleriTuret(
          kronolojikGecmis,
        );
        _aktivite.tohumVerisiEkle(uretilenAktiviteler.reversed.toList());

        if (kronolojikGecmis.isNotEmpty) {
          final sonUretilen = kronolojikGecmis.last;
          unawaited(_sensorDepo.sonOkumayiKaydet(sonUretilen));
        }
      }
      _gecmisler[zon] = gecmis;

      final onbellek = await _sensorDepo.sonOkumayiGetir(zon);
      if (onbellek != null) {
        _sonOkumalar[zon] = onbellek;
        // Uygulama tedavi surerken kapatilip acilmis olabilir -- bu durumda
        // ilerleme cubugunun "sifirdan basliyormus" gibi gorunmemesi icin
        // son bilinen okumanin zaman damgasini YAKLASIK baslangic olarak kullan.
        if (onbellek.tedaviAktif != TedaviTuru.yok) {
          _tedaviBaslangicZamanlari[zon] = onbellek.zaman;
        }
      }
    }
  }

  /// Demo <-> Gercek gecisinde: onceki modun bellek durumunu at, yeni modun
  /// kendi kalici verisini yukle (iki mod ASLA karismaz -- K7).
  Future<void> _modDegistiVerisiniYenile() async {
    _veriModu.demo = _demoModuAktif;
    _sonOkumalar.clear();
    _gecmisler.clear();
    _tedaviBaslangicZamanlari.clear();
    _zonCevrimici.clear();
    await _aktivite.modVerisiniYenidenYukle();
    await _modVerisiniYukle();
    await _aktivite.tohumVerisiniKaydet();
  }

  Future<void> baslat() async {
    unawaited(BildirimServisi.baslat());
    unawaited(_cihazAgDurumunuIzlemeyeBasla());
    _kuyruklananKomutlar
      ..clear()
      ..addAll(await _depolama.kuyruklananKomutlariGetir());
    final ayarlar = await _depolama.mqttAyarlariniGetir();
    _mqttHost = ayarlar.host;
    _mqttPort = ayarlar.port;
    _mqttGuvenli = ayarlar.guvenli;
    final kimlik = await MqttKimlikServisi.oku();
    _mqttKullaniciAdi = kimlik.kullaniciAdi;
    _mqttParola = kimlik.parola;
    _demoModuAktif = await _depolama.demoModuAcikMi();
    _veriModu.demo = _demoModuAktif;
    _demoHizi = await _depolama.demoHiziGetir();
    _sulamasiDurdurulanZonlar
      ..clear()
      ..addAll(await _depolama.sulamaKapaliZonlariGetir());

    // Cevrimdisi mod: baglanmadan ONCE son bilinen degerleri yukle,
    // boylece ekran hicbir zaman bomben acilmiyor.
    await _modVerisiniYukle();
    await _aktivite.tohumVerisiniKaydet();

    _hazir = true;
    notifyListeners();

    if (_demoModuAktif) {
      _simulasyonuBaslat();
    } else {
      await _mqttyeBaglan();
    }
  }

  Future<void> _mqttyeBaglan() async {
    _mqtt?.baglantiyiKapat();
    _mqtt = MqttServisi(
      veriGeldiginde: _veriGeldiginde,
      zonDurumuDegistiginde: _zonDurumuDegistiginde,
      baglantiDurumuDegistiginde: _baglantiDurumuDegistiginde,
      komutDurumuGeldiginde: _komutDurumuGeldiginde,
    );
    await _mqtt!.baglan(
      host: _mqttHost,
      port: _mqttPort,
      zonlar: _tarla.tumZonNumaralari,
      guvenli: _mqttGuvenli,
      kullaniciAdi: _mqttKullaniciAdi,
      parola: _mqttParola,
    );
  }

  void _simulasyonuBaslat() {
    _simulasyon?.durdur();
    _simulasyon = SimulasyonServisi(
      zonlar: _tarla.tumZonNumaralari,
      veriUretildiginde: _veriGeldiginde,
    );
    _simulasyon!.baslat(aralik: _demoHizi.sure);
    for (final zon in _sulamasiDurdurulanZonlar) {
      _simulasyon!.sulamayiDuraklat(zon);
    }
    _baglantiDurumuDegistiginde(MqttBaglantiDurumu.bagli);
    for (final zon in _tarla.tumZonNumaralari) {
      _zonDurumuDegistiginde(zon, true);
    }
  }

  // ============================================================================
  // DEMO MODU
  // ============================================================================

  Future<void> demoModunuAc() async {
    if (_demoModuAktif) return;
    _demoModuAktif = true;
    await _depolama.demoModunuAyarla(true);
    _mqtt?.baglantiyiKapat();
    _mqtt = null;
    await _modDegistiVerisiniYenile();
    _simulasyonuBaslat();
    notifyListeners();
  }

  Future<void> demoModunuKapat() async {
    if (!_demoModuAktif) return;
    _demoModuAktif = false;
    await _depolama.demoModunuAyarla(false);
    _simulasyon?.durdur();
    _simulasyon = null;
    await _modDegistiVerisiniYenile();
    notifyListeners();
    await _mqttyeBaglan();
  }

  Future<void> demoHiziniAyarla(DemoHizi hiz) async {
    _demoHizi = hiz;
    await _depolama.demoHiziniKaydet(hiz);
    _simulasyon?.hiziDegistir(hiz.sure);
    notifyListeners();
  }

  Future<void> mqttAyarlariniGuncelle({
    required String host,
    required int port,
    required bool guvenli,
    String? kullaniciAdi,
    String? parola,
  }) async {
    _mqttHost = host;
    _mqttPort = port;
    _mqttGuvenli = guvenli;
    // null = mevcut degeri KORU (eski cagrilar kimligi silmez; arayuz
    // parolayi geri gostermez). Bos kullanici adi = kimligi SIL (anonim).
    _mqttKullaniciAdi = kullaniciAdi ?? _mqttKullaniciAdi;
    _mqttParola = _mqttKullaniciAdi.isEmpty ? "" : (parola ?? _mqttParola);
    await MqttKimlikServisi.kaydet(
      kullaniciAdi: _mqttKullaniciAdi,
      parola: _mqttParola,
    );
    await _depolama.mqttAyarlariniKaydet(
      host: host,
      port: port,
      guvenli: guvenli,
    );
    if (!_demoModuAktif) {
      await _mqttyeBaglan();
    }
    notifyListeners();
  }

  // ============================================================================
  // MQTT OLAY ISLEYICILERI
  // ============================================================================

  /// Cihazin GERCEK ana vana durumunu (telemetride `ana_vana_acik`) yerel
  /// tahminle esitler. SADECE gercek MQTT modunda ve alan gelmisse calisir
  /// (eski firmware/demo `null` doner -- yerel tahmin korunur). Yerel bir
  /// vana komutundan sonra [AyarlarSabitleri.vanaEsitlemeBeklemesi] boyunca
  /// esitleme yapilmaz: komut cihaza ulasip yansimadan gelen ESKI bir
  /// telemetri, kullanicinin yeni komutunu ezmesin.
  void _vanaDurumunuCihazlaEsitle(SensorOkuma okuma) {
    final cihazdaAcik = okuma.anaVanaAcik;
    if (_demoModuAktif || cihazdaAcik == null) return;

    final sonKomut = _vanaKomutZamanlari[okuma.zone];
    if (sonKomut != null &&
        DateTime.now().difference(sonKomut) <
            AyarlarSabitleri.vanaEsitlemeBeklemesi) {
      return;
    }

    final yerelKapali = _sulamasiDurdurulanZonlar.contains(okuma.zone);
    if (cihazdaAcik == !yerelKapali) return; // zaten esit

    if (cihazdaAcik) {
      _sulamasiDurdurulanZonlar.remove(okuma.zone);
    } else {
      _sulamasiDurdurulanZonlar.add(okuma.zone);
    }
    unawaited(_depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar));
    _manuelMudahaleKaydet(
      okuma.zone,
      'Zon ${okuma.zone}: ana vana durumu CIHAZDAN alinan veriyle esitlendi '
      '(cihazda vana ${cihazdaAcik ? "ACIK" : "KAPALI"})',
    );
  }

  /// Bir okumanin GECMISE yazilip yazilmayacagi: onceki kayitli okumaya gore
  /// DURUM degistiyse (tespit/tedavi/durulama/tur) HEMEN, degismediyse
  /// yalnizca [AyarlarSabitleri.gecmisKayitAraligi] gectiyse.
  bool _gecmiseYazilmali(SensorOkuma? sonYazilan, SensorOkuma yeni) {
    if (sonYazilan == null) return true;
    if (sonYazilan.durum != yeni.durum ||
        sonYazilan.tikanmaTuru != yeni.tikanmaTuru ||
        sonYazilan.tedaviAktif != yeni.tedaviAktif ||
        sonYazilan.durulamaAktif != yeni.durulamaAktif) {
      return true;
    }
    return yeni.zaman.difference(sonYazilan.zaman) >=
        AyarlarSabitleri.gecmisKayitAraligi;
  }

  /// SADECE test: gercek MQTT'yi beklemeden, cihazdan bir telemetri
  /// mesaji gelmis gibi isler.
  @visibleForTesting
  void telemetriGeldiTestIcin(SensorOkuma okuma) => _veriGeldiginde(okuma);

  void _veriGeldiginde(SensorOkuma okuma) {
    debugPrint(
      '[AquaGuard/Veri] Zon ${okuma.zone}: durum=${okuma.durum.name} '
      'tur=${okuma.tikanmaTuru.name} guven=%${okuma.guven.toStringAsFixed(0)}',
    );
    final onceki = _sonOkumalar[okuma.zone];
    _vanaDurumunuCihazlaEsitle(okuma);

    if (onceki != null) {
      // Mesaj/kural mantigi burada DEGIL -- gecisAktiviteleriniUret() saf
      // fonksiyonunda (bkz. models/aktivite_kaydi.dart).
      for (final kayit in gecisAktiviteleriniUret(onceki, okuma)) {
        _aktivite.aktiviteKaydiEkle(kayit);
      }
    }

    if (okuma.tedaviAktif != TedaviTuru.yok &&
        (onceki == null || onceki.tedaviAktif != okuma.tedaviAktif)) {
      _tedaviBaslangicZamanlari[okuma.zone] = okuma.zaman;
    } else if (okuma.tedaviAktif == TedaviTuru.yok) {
      _tedaviBaslangicZamanlari.remove(okuma.zone);
    }

    _sonOkumalar[okuma.zone] = okuma;
    _zonCevrimici[okuma.zone] = true;

    // Son okuma HER telemetride kaydedilir (yeniden aciista anlik gorunum
    // icin); GECMIS ise dakikada bir + durum degisimlerinde yazilir (Y2).
    unawaited(_sensorDepo.sonOkumayiKaydet(okuma));
    final zonGecmisi = _gecmisler[okuma.zone] ?? const <SensorOkuma>[];
    if (_gecmiseYazilmali(
      zonGecmisi.isEmpty ? null : zonGecmisi.first,
      okuma,
    )) {
      // Bellek listesi DB ile AYNI seriyi ve AYNI siniri tutar; eskiden burada
      // `take(100)` vardi ve acilista yuklenen tum gecmis ilk canli okumada
      // 100 kayda dusuyordu (trend/istatistikler aniden kisaliyordu).
      _gecmisler[okuma.zone] = [
        okuma,
        ...zonGecmisi,
      ].take(AyarlarSabitleri.gecmisBellekMaksimumKayit).toList();
      unawaited(_sensorDepo.gecmiseEkle(okuma));
    }

    notifyListeners();
  }

  void _zonDurumuDegistiginde(int zone, bool cevrimici) {
    _zonCevrimici[zone] = cevrimici;
    notifyListeners();
  }

  void _baglantiDurumuDegistiginde(MqttBaglantiDurumu durum) {
    _baglantiDurumu = durum;
    if (durum == MqttBaglantiDurumu.bagli) {
      unawaited(_kuyruklananKomutlariGonder());
    }
    notifyListeners();
  }

  // ============================================================================
  // OFFLINE MOD (cihaz agi + komut kuyrugu)
  // ============================================================================

  Future<void> _cihazAgDurumunuIzlemeyeBasla() async {
    try {
      final ilkDurum = await Connectivity().checkConnectivity();
      _cihazBagliMi = !ilkDurum.contains(ConnectivityResult.none);
      _baglantiAboneligi = Connectivity().onConnectivityChanged.listen((sonuc) {
        _cihazBagliMi = !sonuc.contains(ConnectivityResult.none);
        notifyListeners();
      });
    } catch (_) {
      // connectivity_plus bazi platformlarda desteklenmeyebilir -- bu bir
      // IYILESTIRME, kritik yol degil, sessizce varsayilan (bagli) kalinir.
    }
  }

  /// Komutu ANINDA gonderir (true) ya da baglanti yoksa kuyruga alir (false).
  /// Kuyruktaki komut [AyarlarSabitleri.kuyrukKomutGecerlilikSuresi] icinde
  /// gonderilemezse DUSER -- cagiran taraf bunu kullaniciya bildirmelidir.
  Future<bool> _komutGonderVeyaKuyrukla(
    int zone,
    Map<String, dynamic> komut,
  ) async {
    final mqtt = _mqtt;
    if (mqtt != null && mqtt.bagliMi) {
      mqtt.komutGonder(zone, komut);
      return true;
    }
    _kuyruklananKomutlar.add(
      KuyruklanmisKomut(
        zone: zone,
        komut: komut,
        olusturmaZamani: DateTime.now(),
      ),
    );
    await _depolama.kuyruklananKomutlariKaydet(_kuyruklananKomutlar);
    return false;
  }

  Future<void> _kuyruklananKomutlariGonder() async {
    if (_kuyruklananKomutlar.isEmpty) return;
    final mqtt = _mqtt;
    if (mqtt == null || !mqtt.bagliMi) return;

    final gecerliler = _kuyruklananKomutlar
        .where(
          (k) =>
              !k.suresiGecmisMi(AyarlarSabitleri.kuyrukKomutGecerlilikSuresi),
        )
        .toList();
    for (final kuyruklu in gecerliler) {
      mqtt.komutGonder(kuyruklu.zone, kuyruklu.komut);
    }
    // Suresi dolan komutlar SESSIZCE dusmesin (ozellikle acil durdurma/vana):
    // operator gecmiste ne GONDERILEMEDIGINI gorebilmeli.
    for (final kuyruklu in _kuyruklananKomutlar) {
      if (kuyruklu.suresiGecmisMi(
        AyarlarSabitleri.kuyrukKomutGecerlilikSuresi,
      )) {
        _manuelMudahaleKaydet(
          kuyruklu.zone,
          'Zon ${kuyruklu.zone}: "${kuyruklu.komut['komut']}" komutu cihaza '
          'ULASAMADI (kuyrukta suresi doldu) -- GONDERILMEDI, cihaz basinda kontrol edin',
        );
      }
    }
    _kuyruklananKomutlar.clear();
    await _depolama.kuyruklananKomutlariKaydet(_kuyruklananKomutlar);
  }

  // ============================================================================
  // TARLA PROVIDER GERI CAGIRIMLARI (bkz. main.dart wiring)
  // ============================================================================

  /// Yeni eklenen/guncellenen zonlarin, aktif baglantiya (demo veya MQTT)
  /// hemen dahil olmasini saglar.
  void zonlarEklendi(List<int> zonlar) {
    if (_demoModuAktif) {
      _simulasyonuBaslat(); // tum zon listesiyle yeniden baslat, en basit ve tutarli yol
    } else {
      for (final zon in zonlar) {
        _mqtt?.zonuAbonelikleEkle(zon);
      }
    }
  }

  /// Artik hicbir tarlada kullanilmayan zonlarin onbellek/gecmis verisini
  /// temizler -- aksi halde ayni zon numarasi yeniden kullanilirsa eski
  /// veri "hayalet" gibi hemen gorunur.
  void zonlarYetimKaldi(List<int> yetimZonlar) {
    for (final zon in yetimZonlar) {
      _sonOkumalar.remove(zon);
      _zonCevrimici.remove(zon);
      _gecmisler.remove(zon);
      unawaited(_sensorDepo.zonVerisiniTemizle(zon));
    }
    if (_demoModuAktif) {
      _simulasyonuBaslat();
    }
    notifyListeners();
  }

  // ============================================================================
  // OPERATOR MUDAHALESI (manuel komut)
  // ============================================================================

  /// "Belirsiz" durumda operatorun, sistemin secemedigi tedaviyi MANUEL
  /// olarak baslatmasini saglar. MUTEX KILIDI: zon zaten bir tedavi/
  /// durulama surdurmekteyse istek REDDEDILIR.
  Future<KomutSonucu> manuelTedaviBaslat(int zone, TedaviTuru tedavi) async {
    final tur = tedaviyeKarsilikGelenTur(tedavi);
    final guncelOkuma = _sonOkumalar[zone];
    final zatenMesgulMu =
        guncelOkuma != null &&
        (guncelOkuma.tedaviAktif != TedaviTuru.yok ||
            guncelOkuma.durulamaAktif);

    KomutSonucu sonuc;
    if (_demoModuAktif) {
      final basarili = _simulasyon?.manuelTedaviBaslat(zone, tur) ?? false;
      sonuc = basarili ? KomutSonucu.uygulandi : KomutSonucu.reddedildi;
    } else if (zatenMesgulMu) {
      sonuc = KomutSonucu.reddedildi;
    } else {
      sonuc = await _komutGonderVeOnayBekle(zone, {
        'komut': 'tedavi_baslat',
        'tedavi_turu': tedaviKoduGetir(tedavi),
      });
    }

    final mesaj = switch (sonuc) {
      KomutSonucu.uygulandi =>
        'Zon $zone: Operatör "${tedaviEtiketi(tedavi)}" tedavisini manuel olarak başlattı',
      KomutSonucu.reddedildi =>
        'Zon $zone: "${tedaviEtiketi(tedavi)}" tedavisi REDDEDİLDİ '
            '(mutex kilidi — zon zaten bir tedavi/durulama sürdürüyor)',
      KomutSonucu.zamanAsimi =>
        'Zon $zone: "${tedaviEtiketi(tedavi)}" komutu için cihazdan yanıt '
            'alınamadı (zaman aşımı) — bağlantıyı kontrol edin',
    };
    _manuelMudahaleKaydet(zone, mesaj);
    return sonuc;
  }

  /// Besin/takviye dozlama (Faz 3, 2026-09-25) -- manuelTedaviBaslat'tan
  /// FARKLI: tikanma teshisinden TAMAMEN BAGIMSIZDIR, operator "belirsiz"
  /// durumu beklemeden HER ZAMAN baslatabilir. AYNI guvenlik kilidine
  /// (mutex) tabidir -- zon zaten bir tedavi/durulama surduruyorsa reddedilir.
  Future<KomutSonucu> besinDozlamaBaslat(int zone, TedaviTuru tedavi) async {
    final guncelOkuma = _sonOkumalar[zone];
    final zatenMesgulMu =
        guncelOkuma != null &&
        (guncelOkuma.tedaviAktif != TedaviTuru.yok ||
            guncelOkuma.durulamaAktif);

    KomutSonucu sonuc;
    if (_demoModuAktif) {
      final basarili = _simulasyon?.besinDozlamaBaslat(zone, tedavi) ?? false;
      sonuc = basarili ? KomutSonucu.uygulandi : KomutSonucu.reddedildi;
    } else if (zatenMesgulMu) {
      sonuc = KomutSonucu.reddedildi;
    } else {
      sonuc = await _komutGonderVeOnayBekle(zone, {
        'komut': 'tedavi_baslat',
        'tedavi_turu': tedaviKoduGetir(tedavi),
      });
    }

    final mesaj = switch (sonuc) {
      KomutSonucu.uygulandi =>
        'Zon $zone: Operatör "${tedaviEtiketi(tedavi)}" dozlamasını manuel olarak başlattı',
      KomutSonucu.reddedildi =>
        'Zon $zone: "${tedaviEtiketi(tedavi)}" dozlaması REDDEDİLDİ '
            '(mutex kilidi — zon zaten bir tedavi/durulama sürdürüyor)',
      KomutSonucu.zamanAsimi =>
        'Zon $zone: "${tedaviEtiketi(tedavi)}" komutu için cihazdan yanıt '
            'alınamadı (zaman aşımı) — bağlantıyı kontrol edin',
    };
    _manuelMudahaleKaydet(zone, mesaj);
    return sonuc;
  }

  Future<KomutSonucu> _komutGonderVeOnayBekle(
    int zone,
    Map<String, dynamic> komut,
  ) async {
    final mqtt = _mqtt;
    if (mqtt == null || !mqtt.bagliMi) return KomutSonucu.zamanAsimi;

    final komutId = mqtt.komutGonder(zone, komut);
    final tamamlayici = Completer<KomutSonucu>();
    _bekleyenKomutlar[komutId] = tamamlayici;

    Timer(AyarlarSabitleri.komutZamanAsimi, () {
      final beklenen = _bekleyenKomutlar.remove(komutId);
      if (beklenen != null && !beklenen.isCompleted) {
        beklenen.complete(KomutSonucu.zamanAsimi);
      }
    });

    return tamamlayici.future;
  }

  void _komutDurumuGeldiginde(String komutId, bool basarili) {
    final tamamlayici = _bekleyenKomutlar.remove(komutId);
    if (tamamlayici != null && !tamamlayici.isCompleted) {
      tamamlayici.complete(
        basarili ? KomutSonucu.uygulandi : KomutSonucu.reddedildi,
      );
    }
  }

  Future<void> manuelTedaviDurdur(int zone) async {
    final guncelOkuma = _sonOkumalar[zone];
    if (guncelOkuma == null || guncelOkuma.tedaviAktif == TedaviTuru.yok) {
      return;
    }
    final guncelTur = guncelOkuma.tikanmaTuru;
    if (_demoModuAktif) {
      _simulasyon?.manuelTedaviDurdur(zone, guncelTur);
    } else {
      await _komutGonderVeyaKuyrukla(zone, {'komut': 'tedavi_durdur'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör devam eden tedaviyi manuel olarak durdurdu',
    );
  }

  Future<void> manuelNormaleDondur(int zone) async {
    if (_demoModuAktif) {
      _simulasyon?.manuelNormaleDondur(zone);
    } else {
      await _komutGonderVeyaKuyrukla(zone, {'komut': 'normale_dondur'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör yanlış alarm olarak işaretledi, durum normale döndürüldü',
    );
  }

  void _manuelMudahaleKaydet(int zone, String mesaj) {
    final kayit = AktiviteKaydi(
      zaman: DateTime.now(),
      zone: zone,
      mesaj: mesaj,
      tur: AktiviteTuru.manuelMudahale,
    );
    _aktivite.aktiviteKaydiEkle(kayit);
    notifyListeners();
  }

  // ============================================================================
  // SULAMA KONTROLU (ana vana acik/kapali -- teshis akisindan BAGIMSIZ)
  // ============================================================================

  Future<void> sulamayiDurdur(int zone) async {
    if (_sulamasiDurdurulanZonlar.contains(zone)) return;
    _sulamasiDurdurulanZonlar.add(zone);
    _vanaKomutZamanlari[zone] = DateTime.now();
    unawaited(_depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar));
    if (_demoModuAktif) {
      _simulasyon?.sulamayiDuraklat(zone);
    } else {
      await _komutGonderVeyaKuyrukla(zone, {'komut': 'sulama_durdur'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör sulamayı (ana vana) manuel olarak durdurdu',
    );
  }

  Future<void> sulamayiBaslat(int zone) async {
    if (!_sulamasiDurdurulanZonlar.contains(zone)) return;
    _sulamasiDurdurulanZonlar.remove(zone);
    _vanaKomutZamanlari[zone] = DateTime.now();
    unawaited(_depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar));
    if (_demoModuAktif) {
      _simulasyon?.sulamayiDevamEttir(zone);
    } else {
      await _komutGonderVeyaKuyrukla(zone, {'komut': 'sulama_baslat'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör sulamayı (ana vana) yeniden başlattı',
    );
  }

  // Demo modunda, gercek firmware'in yaptigi "sure dolunca kendiliginden
  // kapat" davranisini (bkz. firmware/ana_vana.h anaVanaZamanlayiciyiGuncelle)
  // taklit eden istemci-tarafi zamanlayicilar. Gercek modda BUNA GEREK YOK
  // -- zamanlayici KARTTA calisir (bkz. dosya basi "sureli sulama" notu).
  final Map<int, Timer> _demoSulamaZamanlayicilari = {};

  /// Uzaktan/sureli sulama baslatma ("çiftçi evinden sulama başlatsın").
  /// [dakika] <= 0 ise suresiz baslatir (sulamayiBaslat ile ayni etki,
  /// ama -- ondan farkli olarak -- zon o an "manuel durdurulmus" olmasa
  /// BILE calisir, cunku bu YENI bir baslatma eylemi, "durdurulani geri
  /// acma" degil). [dakika], [AyarlarSabitleri.sulamaMaksSureDakika] ile
  /// kirpilir (firmware/config.h SULAMA_MAKS_SURE_DK ile ayni ust sinir).
  Future<bool> sulamayiSureliBaslat(int zone, int dakika) async {
    final kirpilmisDakika = dakika > 0
        ? (dakika > AyarlarSabitleri.sulamaMaksSureDakika
              ? AyarlarSabitleri.sulamaMaksSureDakika
              : dakika)
        : 0;

    _sulamasiDurdurulanZonlar.remove(zone);
    _vanaKomutZamanlari[zone] = DateTime.now();
    unawaited(_depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar));

    bool basarili;
    _demoSulamaZamanlayicilari.remove(zone)?.cancel();
    if (_demoModuAktif) {
      _simulasyon?.sulamayiDevamEttir(zone);
      if (kirpilmisDakika > 0) {
        _demoSulamaZamanlayicilari[zone] = Timer(
          Duration(minutes: kirpilmisDakika),
          () => sulamayiDurdur(zone),
        );
      }
      basarili = true;
    } else {
      basarili = await _komutGonderVeyaKuyrukla(zone, {
        'komut': 'sulama_baslat',
        if (kirpilmisDakika > 0) 'sure_dakika': kirpilmisDakika,
      });
    }

    _manuelMudahaleKaydet(
      zone,
      kirpilmisDakika > 0
          ? 'Zon $zone: Operatör $kirpilmisDakika dakika süreli sulama başlattı'
          : 'Zon $zone: Operatör sulamayı (ana vana) yeniden başlattı',
    );
    return basarili;
  }

  // ============================================================================
  // ACIL DURDURMA (tum sistem geneli guvenlik supabi)
  // ============================================================================

  /// Son acil durdurmada cihaza ULASAMAYIP kuyruga alinan komut sayisi
  /// (gercek modda). 0 = hepsi ANINDA gonderildi. Kuyruktaki komutlar
  /// [AyarlarSabitleri.kuyrukKomutGecerlilikSuresi] icinde iletilemezse DUSER.
  int _sonAcilKuyrugaAlinan = 0;
  int get sonAcilDurdurmaKuyrugaAlinan => _sonAcilKuyrugaAlinan;

  Future<List<int>> acilDurdurmaTetikle() async {
    final zonlar = _tarla.tumZonNumaralari;
    final vanasiYeniKapatilanlar = <int>[];
    final iletimler = <Future<bool>>[];

    for (final zon in zonlar) {
      final okuma = _sonOkumalar[zon];
      if (okuma != null && okuma.tedaviAktif != TedaviTuru.yok) {
        if (_demoModuAktif) {
          _simulasyon?.manuelTedaviDurdur(zon, okuma.tikanmaTuru);
        } else {
          iletimler.add(
            _komutGonderVeyaKuyrukla(zon, {'komut': 'tedavi_durdur'}),
          );
        }
      }
      if (!_sulamasiDurdurulanZonlar.contains(zon)) {
        vanasiYeniKapatilanlar.add(zon);
        _sulamasiDurdurulanZonlar.add(zon);
        if (_demoModuAktif) {
          _simulasyon?.sulamayiDuraklat(zon);
        } else {
          _vanaKomutZamanlari[zon] = DateTime.now();
          iletimler.add(
            _komutGonderVeyaKuyrukla(zon, {'komut': 'sulama_durdur'}),
          );
        }
      }
    }
    unawaited(_depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar));
    final sonuclar = await Future.wait(iletimler);
    _sonAcilKuyrugaAlinan = sonuclar.where((iletildi) => !iletildi).length;

    final kayit = AktiviteKaydi(
      zaman: DateTime.now(),
      zone: 0,
      mesaj:
          'ACİL DURDURMA tetiklendi: tüm tedaviler durduruldu, '
          '${vanasiYeniKapatilanlar.length} zonun ana vanası kapatıldı'
          '${_sonAcilKuyrugaAlinan > 0 ? " -- UYARI: $_sonAcilKuyrugaAlinan komut cihaza ULASAMADI, kuyruga alindi" : ""}',
      tur: AktiviteTuru.manuelMudahale,
    );
    _aktivite.aktiviteKaydiEkle(kayit);
    notifyListeners();

    return vanasiYeniKapatilanlar;
  }

  // ============================================================================
  // DEMO SENARYO TETIKLEME (sadece Demo Modu'nda anlamli)
  // ============================================================================

  Future<void> demoSenaryosuTetikle(DemoSenaryosu senaryo) async {
    if (!_demoModuAktif || _simulasyon == null) return;
    final mevcutZonlar = _tarla.tumZonNumaralari;

    for (final zon in mevcutZonlar) {
      _simulasyon!.manuelNormaleDondur(zon);
    }

    String aciklama;
    switch (senaryo) {
      case DemoSenaryosu.saglikli:
        aciklama = 'Sağlıklı Sistem';
        break;
      case DemoSenaryosu.kimyasal:
        if (mevcutZonlar.contains(2)) {
          _simulasyon!.manuelTedaviBaslat(2, TikanmaTuru.kimyasal);
        }
        aciklama = 'Kimyasal Tıkanma (Zon 2)';
        break;
      case DemoSenaryosu.biyolojik:
        if (mevcutZonlar.contains(1)) {
          _simulasyon!.manuelTedaviBaslat(1, TikanmaTuru.biyolojik);
        }
        aciklama = 'Biyolojik Tıkanma (Zon 1)';
        break;
      case DemoSenaryosu.fiziksel:
        if (mevcutZonlar.contains(3)) {
          _simulasyon!.manuelTedaviBaslat(3, TikanmaTuru.fiziksel);
        }
        aciklama = 'Fiziksel Tıkanma (Zon 3)';
        break;
      case DemoSenaryosu.mutexKilidi:
        if (mevcutZonlar.contains(2)) {
          _simulasyon!.manuelTedaviBaslat(2, TikanmaTuru.biyolojik);
          final reddedildiMi = !_simulasyon!.manuelTedaviBaslat(
            2,
            TikanmaTuru.kimyasal,
          );
          if (reddedildiMi) {
            final redKaydi = AktiviteKaydi(
              zaman: DateTime.now(),
              zone: 2,
              mesaj:
                  'Zon 2: Asit dozlama REDDEDİLDİ (mutex kilidi — '
                  'klor enjeksiyonu sürüyor)',
              tur: AktiviteTuru.manuelMudahale,
            );
            _aktivite.aktiviteKaydiEkle(redKaydi, bildirimDegerlendir: false);
          }
        }
        aciklama =
            'Mutex Kilit Gösterimi (Zon 2: Klor sürüyor, Asit reddedildi)';
        break;
    }

    final kayit = AktiviteKaydi(
      zaman: DateTime.now(),
      zone: 0,
      mesaj: 'Demo senaryosu tetiklendi: $aciklama',
      tur: AktiviteTuru.manuelMudahale,
    );
    _aktivite.aktiviteKaydiEkle(kayit);
    notifyListeners();
  }

  @override
  void dispose() {
    _mqtt?.baglantiyiKapat();
    _simulasyon?.durdur();
    _baglantiAboneligi?.cancel();
    for (final zamanlayici in _demoSulamaZamanlayicilari.values) {
      zamanlayici.cancel();
    }
    super.dispose();
  }
}

/// Demo Modu'nda tek dokunuşla tetiklenebilecek onceden tanimli senaryolar.
enum DemoSenaryosu { saglikli, kimyasal, biyolojik, fiziksel, mutexKilidi }

/// Bir zon grubunun (tarla veya tum sistem) durum dagilimi.
class ZonDurumOzeti {
  final int normal;
  final int belirsiz;
  final int tespitEdildi;
  final int tedavide;
  final int cevrimdisi;

  const ZonDurumOzeti({
    required this.normal,
    required this.belirsiz,
    required this.tespitEdildi,
    required this.tedavide,
    required this.cevrimdisi,
  });
}
