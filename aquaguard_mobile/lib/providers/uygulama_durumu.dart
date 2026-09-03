/// AquaGuard - Uygulama Durumu (Ana Provider)
/// ==============================================
///
/// Amac:
///   Uygulamanin TUM canli durumunu tek bir yerde tutar: tarlalar, her
///   zonun son okumasi, baglanti durumu, gecmis kayitlar. MQTT servisinden
///   gelen olaylari dinler, yerel depolamaya (cevrimdisi mod icin) yazar
///   ve UI'nin dinleyecegi tek "gercek kaynak" (single source of truth)
///   olarak calisir.
///
///   Neden Provider/ChangeNotifier: Bu proje icin en basit, en yaygin
///   ogretilen state management yontemi budur -- her ekran, sadece
///   ihtiyaci olan veriye `context.watch<UygulamaDurumu>()` ile abone
///   olur, veri degisince otomatik yeniden cizilir (rebuild).
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/foundation.dart';

import '../models/aktivite_kaydi.dart';
import '../models/sensor_okuma.dart';
import '../models/tarla.dart';
import '../models/tarla_notu.dart';
import '../services/depolama_servisi.dart';
import '../services/gecmis_veri_uretici.dart';
import '../services/mqtt_servisi.dart';
import '../services/simulasyon_servisi.dart';
import '../widgets/durum_renkleri.dart';

class UygulamaDurumu extends ChangeNotifier {
  final DepolamaServisi _depolama = DepolamaServisi();
  MqttServisi? _mqtt;
  SimulasyonServisi? _simulasyon;
  bool _demoModuAktif = true;

  List<Tarla> _tarlalar = [];
  final Map<int, SensorOkuma> _sonOkumalar = {};
  final Map<int, bool> _zonCevrimici = {};
  final Map<int, List<SensorOkuma>> _gecmisler = {};

  String _mqttHost = '';
  int _mqttPort = 0;
  MqttBaglantiDurumu _baglantiDurumu = MqttBaglantiDurumu.baglaniyor;
  bool _bildirimlerAcik = true;
  bool _hazir = false;

  final List<String> _bildirimKuyrugu = [];
  final Map<int, DateTime> _tedaviBaslangicZamanlari = {};
  final List<AktiviteKaydi> _aktiviteGecmisi = [];
  // OPERATOR MUDAHALESI: sulamasi manuel durdurulmus zonlar -- ana vana
  // acik/kapali durumu, teshis akisindan BAGIMSIZ bir operator kontrolu
  // (bkz. sulamayiDurdur/sulamayiBaslat). Yeniden acilista kaybolmamasi
  // icin kalici depolanir -- bir operator sizinti supheyle vanayi kapattiysa,
  // uygulama kapanip acilsa bile bu bilgi kaybolmamali.
  final Set<int> _sulamasiDurdurulanZonlar = {};
  final List<TarlaNotu> _tarlaNotlari = [];

  // ============================================================================
  // DISARIYA ACIK (READ-ONLY) DURUM
  // ============================================================================

  List<Tarla> get tarlalar => List.unmodifiable(_tarlalar);
  bool get hazir => _hazir;
  String get mqttHost => _mqttHost;
  int get mqttPort => _mqttPort;
  MqttBaglantiDurumu get baglantiDurumu => _baglantiDurumu;
  bool get bildirimlerAcik => _bildirimlerAcik;
  bool get demoModuAktif => _demoModuAktif;

  /// Ilgili zonda su an suren tedavinin (varsa) BASLANGIC zamani. Bu bilgi
  /// cihazdan gelmez; ilk kez "tedavi_aktif != yok" gorduğumuz an istemci
  /// tarafinda kaydedilir. Aktif tedavi ekranindaki ilerleme cubugu bunu kullanir.
  DateTime? tedaviBaslangicZamani(int zone) => _tedaviBaslangicZamanlari[zone];

  SensorOkuma? sonOkuma(int zone) => _sonOkumalar[zone];
  bool zonCevrimiciMi(int zone) => _zonCevrimici[zone] ?? false;

  /// Verilen tarlaya ait notlar, EN YENI ONCE.
  List<TarlaNotu> tarlaNotlari(String tarlaId) {
    final liste = _tarlaNotlari.where((n) => n.tarlaId == tarlaId).toList()
      ..sort((a, b) => b.zaman.compareTo(a.zaman));
    return List.unmodifiable(liste);
  }

  /// Zonun ana vanasi operator tarafindan MANUEL kapatilmis mi? (teshis
  /// durumundan bagimsiz bir kontrol -- bkz. sulamayiDurdur/sulamayiBaslat)
  bool sulamasiDurduruldu(int zone) =>
      _sulamasiDurdurulanZonlar.contains(zone);
  List<SensorOkuma> gecmis(int zone) =>
      List.unmodifiable(_gecmisler[zone] ?? const <SensorOkuma>[]);

  /// Tum zonlardaki onemli olaylarin kalici gecmisi, EN YENI ONCE.
  List<AktiviteKaydi> get aktiviteGecmisi =>
      List.unmodifiable(_aktiviteGecmisi);

  /// Tedavi sayilari (turlere gore), KALICI gecmisten HESAPLANIR (ayri bir
  /// sayac tutulmuyor) -- boylece uygulama yeniden acildiginda sifirlanmaz,
  /// depolanmis sensor gecmisiyle her zaman tutarlidir. Her zonun gecmisinde
  /// "tedavi_aktif" alaninin YOK'tan bir tedaviye GECTIGI anlar sayilir.
  Map<TedaviTuru, int> get tedaviSayaclari {
    final sayaclar = <TedaviTuru, int>{
      TedaviTuru.asitDozlama: 0,
      TedaviTuru.klorEnjeksiyon: 0,
      TedaviTuru.yuksekBasincliYikama: 0,
    };
    for (final zon in tumZonNumaralari) {
      // _gecmisler EN YENI ONCE saklanir; kronolojik (eskiden yeniye) gerekir.
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

  /// Tum zonlardaki tum gecmis okumalar tek bir listede (istatistik hesaplari icin).
  List<SensorOkuma> get tumOkumalarBirlesik {
    final liste = <SensorOkuma>[];
    for (final zon in tumZonNumaralari) {
      liste.addAll(_gecmisler[zon] ?? const <SensorOkuma>[]);
    }
    return liste;
  }

  List<String> bildirimleriAlVeTemizle() {
    final kopya = List<String>.from(_bildirimKuyrugu);
    _bildirimKuyrugu.clear();
    return kopya;
  }

  /// Tum tarlalardaki tum zon numaralarinin tekil (benzersiz) listesi.
  List<int> get tumZonNumaralari {
    final kume = <int>{};
    for (final tarla in _tarlalar) {
      kume.addAll(tarla.zonNumaralari);
    }
    return kume.toList()..sort();
  }

  /// Verilen zon listesinin durum ozetini hesaplar (Genel Bakış ve Zon
  /// Dashboard ekranlarinin ikisi de bunu kullanir -- ayni mantigin iki
  /// yerde elle kopyalanmasini onler). Her zon TEK bir kovaya duser;
  /// siniflandirma DurumRenkleri.onceligiBelirle()'den gelir (tek kaynak --
  /// bkz. o fonksiyonun dokumantasyonu, tarla karti da AYNI fonksiyonu kullanir).
  ZonDurumOzeti durumOzetiHesapla(List<int> zonlar) {
    var normal = 0,
        belirsiz = 0,
        tespitEdildi = 0,
        tedavide = 0,
        cevrimdisi = 0;
    for (final zon in zonlar) {
      final okuma = _sonOkumalar[zon];
      final cevrimici = _zonCevrimici[zon] ?? false;
      switch (DurumRenkleri.onceligiBelirle(okuma: okuma, cevrimici: cevrimici)) {
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

  Future<void> baslat() async {
    _tarlalar = await _depolama.tarlalariGetir();
    final ayarlar = await _depolama.mqttAyarlariniGetir();
    _mqttHost = ayarlar.host;
    _mqttPort = ayarlar.port;
    _bildirimlerAcik = await _depolama.bildirimlerAcikMi();
    _demoModuAktif = await _depolama.demoModuAcikMi();
    _sulamasiDurdurulanZonlar
      ..clear()
      ..addAll(await _depolama.sulamaKapaliZonlariGetir());
    _tarlaNotlari
      ..clear()
      ..addAll(await _depolama.tarlaNotlariGetir());

    // Cevrimdisi mod: baglanmadan ONCE son bilinen degerleri yukle,
    // boylece ekran hicbir zaman bomben acilmiyor.
    for (final zon in tumZonNumaralari) {
      var gecmis = await _depolama.gecmisiGetir(zon);

      // Bu zon icin HIC gecmis yoksa (gercekten ilk kurulum): sanki sistem
      // gunlerdir sahada calisiyormus gibi GECMISE DONUK sentetik bir
      // gecmis uret ve kaydet -- boylece Istatistikler/Aktivite Gecmisi/
      // trend grafikleri ilk acilista bile bombos degil, dolu gorunur.
      if (gecmis.isEmpty) {
        final kronolojikGecmis = GecmisVeriUreticisi.zonGecmisiUret(zon);
        gecmis = kronolojikGecmis.reversed
            .toList(); // depolama EN YENI ONCE bekler
        unawaited(_depolama.gecmisiTopluKaydet(zon, gecmis));

        final uretilenAktiviteler = GecmisVeriUreticisi.aktiviteleriTuret(
          kronolojikGecmis,
        );
        _aktiviteGecmisi.addAll(uretilenAktiviteler.reversed);

        if (kronolojikGecmis.isNotEmpty) {
          final sonUretilen = kronolojikGecmis.last;
          unawaited(_depolama.sonOkumayiKaydet(sonUretilen));
        }
      }
      _gecmisler[zon] = gecmis;

      final onbellek = await _depolama.sonOkumayiGetir(zon);
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

    final oncedenKayitliAktiviteler = await _depolama.aktiviteGecmisiGetir();
    final yeniUretilenVarMi = _aktiviteGecmisi.isNotEmpty;
    _aktiviteGecmisi.addAll(oncedenKayitliAktiviteler);
    _aktiviteGecmisi.sort((a, b) => b.zaman.compareTo(a.zaman));
    if (_aktiviteGecmisi.length > 200) {
      _aktiviteGecmisi.removeRange(200, _aktiviteGecmisi.length);
    }
    // Yeni zonlar icin uretilen aktiviteler varsa, birlestirilmis+sirali
    // son hali kalici depoya yaz (aksi halde bir sonraki acilista kaybolur).
    if (yeniUretilenVarMi) {
      unawaited(_depolama.aktiviteGecmisiniKaydet(_aktiviteGecmisi));
    }

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
    );
    await _mqtt!.baglan(
      host: _mqttHost,
      port: _mqttPort,
      zonlar: tumZonNumaralari,
    );
  }

  void _simulasyonuBaslat() {
    _simulasyon?.durdur();
    _simulasyon = SimulasyonServisi(
      zonlar: tumZonNumaralari,
      veriUretildiginde: _veriGeldiginde,
    );
    _simulasyon!.baslat();
    // SimulasyonServisi.baslat() kendi ic "duraklatilmis zonlar" kaydini
    // sifirlar -- daha once (kalici depodan yuklenmis) manuel kapatilmis
    // zonlar varsa yeni servise TEKRAR uygula, aksi halde vana "yeniden
    // acilmis" gibi gorunur.
    for (final zon in _sulamasiDurdurulanZonlar) {
      _simulasyon!.sulamayiDuraklat(zon);
    }
    _baglantiDurumuDegistiginde(MqttBaglantiDurumu.bagli);
    for (final zon in tumZonNumaralari) {
      _zonDurumuDegistiginde(zon, true);
    }
  }

  // ============================================================================
  // DEMO MODU
  // ============================================================================

  /// Demo modunu acar: gercek MQTT baglantisini keser, uygulama-ici
  /// simulasyon servisini baslatir. Donanim henuz hazir olmadiginda veya
  /// juriye/kullaniciya offline bir demo gostermek icin kullanilir.
  Future<void> demoModunuAc() async {
    if (_demoModuAktif) return;
    _demoModuAktif = true;
    await _depolama.demoModunuAyarla(true);
    _mqtt?.baglantiyiKapat();
    _mqtt = null;
    _simulasyonuBaslat();
    notifyListeners();
  }

  /// Demo modunu kapatir: simulasyonu durdurur, gercek MQTT brokerina baglanir.
  Future<void> demoModunuKapat() async {
    if (!_demoModuAktif) return;
    _demoModuAktif = false;
    await _depolama.demoModunuAyarla(false);
    _simulasyon?.durdur();
    _simulasyon = null;
    notifyListeners();
    await _mqttyeBaglan();
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

    _degisimleriKaydet(onceki, okuma);

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

    unawaited(_depolama.sonOkumayiKaydet(okuma));
    unawaited(_depolama.gecmiseEkle(okuma));

    notifyListeners();
  }

  void _degisimleriKaydet(SensorOkuma? onceki, SensorOkuma yeni) {
    if (onceki == null) return; // ilk veri -- gecmis karsilastirma yok

    // Mesaj/kural mantigi burada DEGIL -- gecisAktiviteleriniUret() saf
    // fonksiyonunda (bkz. models/aktivite_kaydi.dart). GecmisVeriUreticisi
    // de (gecmise donuk toplu veri uretirken) AYNI fonksiyonu kullanir.
    for (final kayit in gecisAktiviteleriniUret(onceki, yeni)) {
      _aktiviteGecmisi.insert(0, kayit);
      if (_aktiviteGecmisi.length > 200) _aktiviteGecmisi.removeLast();
      unawaited(_depolama.aktiviteGecmisiniKaydet(_aktiviteGecmisi));
      if (_bildirimlerAcik) _bildirimKuyrugu.add(kayit.mesaj);
    }
  }

  void _zonDurumuDegistiginde(int zone, bool cevrimici) {
    _zonCevrimici[zone] = cevrimici;
    notifyListeners();
  }

  void _baglantiDurumuDegistiginde(MqttBaglantiDurumu durum) {
    _baglantiDurumu = durum;
    notifyListeners();
  }

  // ============================================================================
  // TARLA YONETIMI
  // ============================================================================

  Future<void> tarlaEkle(Tarla tarla) async {
    _tarlalar = [..._tarlalar, tarla];
    await _depolama.tarlalariKaydet(_tarlalar);
    _yeniZonlariBaglantiyaEkle(tarla.zonNumaralari);
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
      unawaited(_depolama.tarlaNotlariniKaydet(_tarlaNotlari));
    }

    // Silinen tarlanin zonlarindan HALA baska bir tarlada kullanilanlari
    // koru; kalanlarin (artik yetim) onbellek/gecmis verisini temizle --
    // aksi halde ayni zon numarasi yeniden kullanilirsa eski veri "hayalet"
    // gibi hemen gorunur.
    final halaKullanilanZonlar = _tarlalar
        .expand((t) => t.zonNumaralari)
        .toSet();
    var yetimZonVarMi = false;
    for (final zon in silinenTarla.zonNumaralari) {
      if (halaKullanilanZonlar.contains(zon)) continue;
      yetimZonVarMi = true;
      _sonOkumalar.remove(zon);
      _zonCevrimici.remove(zon);
      _gecmisler.remove(zon);
      unawaited(_depolama.zonVerisiniTemizle(zon));
    }

    // Demo modunda simulasyon, zon listesini SADECE baslatildigi anda alir --
    // yetim kalan bir zon icin veri uretmeye devam etmesin diye (hem israf
    // hem de az sonra silinen verinin "hayalet" gibi geri gelmesine sebep
    // olur) guncel zon listesiyle yeniden baslatiyoruz.
    if (yetimZonVarMi && _demoModuAktif) {
      _simulasyonuBaslat();
    }

    notifyListeners();
  }

  Future<void> tarlaGuncelle(Tarla guncelTarla) async {
    _tarlalar = _tarlalar
        .map((t) => t.id == guncelTarla.id ? guncelTarla : t)
        .toList();
    await _depolama.tarlalariKaydet(_tarlalar);
    _yeniZonlariBaglantiyaEkle(guncelTarla.zonNumaralari);
    notifyListeners();
  }

  /// Yeni eklenen/guncellenen zonlarin, aktif baglantiya (demo veya MQTT)
  /// hemen dahil olmasini saglar.
  void _yeniZonlariBaglantiyaEkle(List<int> zonlar) {
    if (_demoModuAktif) {
      _simulasyonuBaslat(); // tum zon listesiyle yeniden baslat, en basit ve tutarli yol
    } else {
      for (final zon in zonlar) {
        _mqtt?.zonuAbonelikleEkle(zon);
      }
    }
  }

  // ============================================================================
  // AYARLAR
  // ============================================================================

  Future<void> mqttAyarlariniGuncelle({
    required String host,
    required int port,
  }) async {
    _mqttHost = host;
    _mqttPort = port;
    await _depolama.mqttAyarlariniKaydet(host: host, port: port);
    if (!_demoModuAktif) {
      await _mqttyeBaglan();
    }
    notifyListeners();
  }

  Future<void> bildirimleriDegistir(bool acik) async {
    _bildirimlerAcik = acik;
    await _depolama.bildirimleriAyarla(acik);
    notifyListeners();
  }

  // ============================================================================
  // OPERATOR MUDAHALESI (manuel komut)
  // ============================================================================
  //
  // AquaGuard'in temel iddiasi OTONOM teshis+tedavidir (bkz. PROJE_BRIEF.md);
  // asagidaki fonksiyonlar bunu degistirmez, sadece bir GUVENLIK/ESNEKLIK
  // supabi ekler: dusuk guvenli "belirsiz" durumda sistem turu KENDISI
  // seçemez (operator secmelidir) ve herhangi bir aktif tedavi, sahadaki bir
  // operator tarafindan her zaman ERKEN durdurulabilmelidir. Demo modunda
  // SimulasyonServisi'nin akisini degistirir; gercek MQTT modunda cihaza
  // komut yayinlar (bkz. MqttServisi.komutGonder, firmware/mqtt_handler.h).

  /// "Belirsiz" durumda operatorun, sistemin secemedigi tedaviyi MANUEL
  /// olarak baslatmasini saglar.
  Future<void> manuelTedaviBaslat(int zone, TedaviTuru tedavi) async {
    final tur = tedaviyeKarsilikGelenTur(tedavi);
    if (_demoModuAktif) {
      _simulasyon?.manuelTedaviBaslat(zone, tur);
    } else {
      _mqtt?.komutGonder(zone, {
        'komut': 'tedavi_baslat',
        'tedavi_turu': tedavi.name,
      });
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör "${tedaviEtiketi(tedavi)}" tedavisini manuel olarak başlattı',
    );
  }

  /// Su an suren bir tedaviyi operatorun ERKEN sonlandirmasini saglar
  /// (guvenlik supabi -- her zaman zorunlu durulamadan gecer).
  Future<void> manuelTedaviDurdur(int zone) async {
    final guncelOkuma = _sonOkumalar[zone];
    if (guncelOkuma == null || guncelOkuma.tedaviAktif == TedaviTuru.yok) {
      return;
    }
    final guncelTur = guncelOkuma.tikanmaTuru;
    if (_demoModuAktif) {
      _simulasyon?.manuelTedaviDurdur(zone, guncelTur);
    } else {
      _mqtt?.komutGonder(zone, {'komut': 'tedavi_durdur'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör devam eden tedaviyi manuel olarak durdurdu',
    );
  }

  /// "Yanlis alarm" -- operator, tespiti/supheyi gecersiz sayar, tedaviye
  /// gerek olmadan dogrudan normal izlemeye doner.
  Future<void> manuelNormaleDondur(int zone) async {
    if (_demoModuAktif) {
      _simulasyon?.manuelNormaleDondur(zone);
    } else {
      _mqtt?.komutGonder(zone, {'komut': 'normale_dondur'});
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
    _aktiviteGecmisi.insert(0, kayit);
    if (_aktiviteGecmisi.length > 200) _aktiviteGecmisi.removeLast();
    unawaited(_depolama.aktiviteGecmisiniKaydet(_aktiviteGecmisi));
    if (_bildirimlerAcik) _bildirimKuyrugu.add(kayit.mesaj);
    notifyListeners();
  }

  // ============================================================================
  // SULAMA KONTROLU (ana vana acik/kapali -- teshis akisindan BAGIMSIZ)
  // ============================================================================
  //
  // Karar motoru "tikanma var/yok" teshis eder; bu bolum ise sahadaki
  // operatorun tamamen ayri bir nedenle (sizinti supheci, bakim, komsu
  // parselde is yapiliyor vb.) bir zonun sulamasini TAMAMEN durdurmasini
  // saglar -- tedaviyi durdurmaktan farkli olarak, burada "yanlis teshis"
  // degil "sahada baska bir sebep" soz konusudur. Demo modunda ilgili
  // zonun veri akisi duraklatilir (son okuma donuk kalir); gercek MQTT
  // modunda cihaza komut yayinlanir.

  /// Zonun ana vanasini MANUEL olarak kapatir.
  Future<void> sulamayiDurdur(int zone) async {
    if (_sulamasiDurdurulanZonlar.contains(zone)) return;
    _sulamasiDurdurulanZonlar.add(zone);
    unawaited(
      _depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar),
    );
    if (_demoModuAktif) {
      _simulasyon?.sulamayiDuraklat(zone);
    } else {
      _mqtt?.komutGonder(zone, {'komut': 'sulama_durdur'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör sulamayı (ana vana) manuel olarak durdurdu',
    );
  }

  /// Manuel kapatilmis sulamayi yeniden acar.
  Future<void> sulamayiBaslat(int zone) async {
    if (!_sulamasiDurdurulanZonlar.contains(zone)) return;
    _sulamasiDurdurulanZonlar.remove(zone);
    unawaited(
      _depolama.sulamaKapaliZonlariniKaydet(_sulamasiDurdurulanZonlar),
    );
    if (_demoModuAktif) {
      _simulasyon?.sulamayiDevamEttir(zone);
    } else {
      _mqtt?.komutGonder(zone, {'komut': 'sulama_baslat'});
    }
    _manuelMudahaleKaydet(
      zone,
      'Zon $zone: Operatör sulamayı (ana vana) yeniden başlattı',
    );
  }

  // ============================================================================
  // TARLA NOTLARI (operatorun serbest metin notlari)
  // ============================================================================

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
    await _depolama.tarlaNotlariniKaydet(_tarlaNotlari);
    notifyListeners();
  }

  Future<void> notSil(String notId) async {
    _tarlaNotlari.removeWhere((n) => n.id == notId);
    await _depolama.tarlaNotlariniKaydet(_tarlaNotlari);
    notifyListeners();
  }

  @override
  void dispose() {
    _mqtt?.baglantiyiKapat();
    _simulasyon?.durdur();
    super.dispose();
  }
}

/// `Future`'i "ates et ve unut" (fire-and-forget) sekilde calistirmak icin
/// kucuk bir yardimci -- depolama yazma islemlerinin UI'yi bloklamasini
/// istemiyoruz, ama hatalari da sessizce yutmak istemiyoruz.
void unawaited(Future<void> future) {
  future.catchError((Object hata) {
    debugPrint('AquaGuard depolama hatasi: $hata');
  });
}

/// Bir zon grubunun (tarla veya tum sistem) durum dagilimi. Genel Bakış ve
/// Zon Dashboard ekranlarinin ikisi de UygulamaDurumu.durumOzetiHesapla()
/// araciligiyla bunu kullanir.
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
