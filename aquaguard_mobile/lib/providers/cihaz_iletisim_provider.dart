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

  CihazIletisimProvider({
    required TarlaProvider tarla,
    required AktiviteBildirimProvider aktivite,
    DepolamaServisi? depolama,
    SensorOkumaRepository? sensorDepo,
  }) : _depolama = depolama ?? DepolamaServisi(),
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
    _demoHizi = await _depolama.demoHiziGetir();
    _sulamasiDurdurulanZonlar
      ..clear()
      ..addAll(await _depolama.sulamaKapaliZonlariGetir());

    // Cevrimdisi mod: baglanmadan ONCE son bilinen degerleri yukle,
    // boylece ekran hicbir zaman bomben acilmiyor.
    for (final zon in _tarla.tumZonNumaralari) {
      var gecmis = await _sensorDepo.gecmisiGetir(zon);

      // Bu zon icin HIC gecmis yoksa (gercekten ilk kurulum): sanki sistem
      // gunlerdir sahada calisiyormus gibi GECMISE DONUK sentetik bir
      // gecmis uret ve kaydet -- boylece Istatistikler/Aktivite Gecmisi/
      // trend grafikleri ilk acilista bile bombos degil, dolu gorunur.
      if (gecmis.isEmpty) {
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
    _simulasyonuBaslat();
    notifyListeners();
  }

  Future<void> demoModunuKapat() async {
    if (!_demoModuAktif) return;
    _demoModuAktif = false;
    await _depolama.demoModunuAyarla(false);
    _simulasyon?.durdur();
    _simulasyon = null;
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

  void _veriGeldiginde(SensorOkuma okuma) {
    debugPrint(
      '[AquaGuard/Veri] Zon ${okuma.zone}: durum=${okuma.durum.name} '
      'tur=${okuma.tikanmaTuru.name} guven=%${okuma.guven.toStringAsFixed(0)}',
    );
    final onceki = _sonOkumalar[okuma.zone];

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

    final guncelGecmis = [
      okuma,
      ...(_gecmisler[okuma.zone] ?? const <SensorOkuma>[]),
    ].take(100).toList();
    _gecmisler[okuma.zone] = guncelGecmis;

    unawaited(_sensorDepo.sonOkumayiKaydet(okuma));
    unawaited(_sensorDepo.gecmiseEkle(okuma));

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

  Future<void> _komutGonderVeyaKuyrukla(
    int zone,
    Map<String, dynamic> komut,
  ) async {
    final mqtt = _mqtt;
    if (mqtt != null && mqtt.bagliMi) {
      mqtt.komutGonder(zone, komut);
      return;
    }
    _kuyruklananKomutlar.add(
      KuyruklanmisKomut(
        zone: zone,
        komut: komut,
        olusturmaZamani: DateTime.now(),
      ),
    );
    await _depolama.kuyruklananKomutlariKaydet(_kuyruklananKomutlar);
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

  // ============================================================================
  // ACIL DURDURMA (tum sistem geneli guvenlik supabi)
  // ============================================================================

  Future<List<int>> acilDurdurmaTetikle() async {
    final zonlar = _tarla.tumZonNumaralari;
    final vanasiYeniKapatilanlar = <int>[];

    for (final zon in zonlar) {
      final okuma = _sonOkumalar[zon];
      if (okuma != null && okuma.tedaviAktif != TedaviTuru.yok) {
        if (_demoModuAktif) {
          _simulasyon?.manuelTedaviDurdur(zon, okuma.tikanmaTuru);
        } else {
          unawaited(_komutGonderVeyaKuyrukla(zon, {'komut': 'tedavi_durdur'}));
        }
      }
      if (!_sulamasiDurdurulanZonlar.contains(zon)) {
        vanasiYeniKapatilanlar.add(zon);
        _sulamasiDurdurulanZonlar.add(zon);
        if (_demoModuAktif) {
          _simulasyon?.sulamayiDuraklat(zon);
        } else {
          unawaited(_komutGonderVeyaKuyrukla(zon, {'komut': 'sulama_durdur'}));
        }
      }
    }
    unawaited(_depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar));

    final kayit = AktiviteKaydi(
      zaman: DateTime.now(),
      zone: 0,
      mesaj:
          'ACİL DURDURMA tetiklendi: tüm tedaviler durduruldu, '
          '${vanasiYeniKapatilanlar.length} zonun ana vanası kapatıldı',
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
