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

import '../models/sensor_okuma.dart';
import '../models/tarla.dart';
import '../services/depolama_servisi.dart';
import '../services/mqtt_servisi.dart';
import '../services/simulasyon_servisi.dart';

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
  List<SensorOkuma> gecmis(int zone) => List.unmodifiable(_gecmisler[zone] ?? const <SensorOkuma>[]);

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

    // Cevrimdisi mod: baglanmadan ONCE son bilinen degerleri yukle,
    // boylece ekran hicbir zaman bomben acilmiyor.
    for (final zon in tumZonNumaralari) {
      final onbellek = await _depolama.sonOkumayiGetir(zon);
      if (onbellek != null) {
        _sonOkumalar[zon] = onbellek;
      }
      _gecmisler[zon] = await _depolama.gecmisiGetir(zon);
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

    if (_bildirimlerAcik) {
      _degisimiKontrolEtVeBildir(onceki, okuma);
    }

    if (okuma.tedaviAktif != TedaviTuru.yok &&
        (onceki == null || onceki.tedaviAktif != okuma.tedaviAktif)) {
      _tedaviBaslangicZamanlari[okuma.zone] = okuma.zaman;
    } else if (okuma.tedaviAktif == TedaviTuru.yok) {
      _tedaviBaslangicZamanlari.remove(okuma.zone);
    }

    _sonOkumalar[okuma.zone] = okuma;
    _zonCevrimici[okuma.zone] = true;

    final guncelGecmis = [okuma, ...(_gecmisler[okuma.zone] ?? const <SensorOkuma>[])].take(100).toList();
    _gecmisler[okuma.zone] = guncelGecmis;

    unawaited(_depolama.sonOkumayiKaydet(okuma));
    unawaited(_depolama.gecmiseEkle(okuma));

    notifyListeners();
  }

  void _degisimiKontrolEtVeBildir(SensorOkuma? onceki, SensorOkuma yeni) {
    if (onceki == null) return; // ilk veri -- gecmis karsilastirma yok

    if (onceki.durum != yeni.durum) {
      switch (yeni.durum) {
        case TeshisDurumu.tespitEdildi:
          _bildirimKuyrugu.add(
            'Zon ${yeni.zone}: ${turEtiketi(yeni.tikanmaTuru)} tıkanma tespit edildi '
            '(güven %${yeni.guven.toStringAsFixed(0)})',
          );
          break;
        case TeshisDurumu.belirsiz:
          _bildirimKuyrugu.add(
            'Zon ${yeni.zone}: Tıkanma şüphesi var, operatör kontrolü gerekiyor',
          );
          break;
        case TeshisDurumu.normal:
          if (onceki.durum != TeshisDurumu.bilinmiyor) {
            _bildirimKuyrugu.add('Zon ${yeni.zone}: Durum normale döndü');
          }
          break;
        case TeshisDurumu.bilinmiyor:
          break;
      }
    }

    if (onceki.tedaviAktif != yeni.tedaviAktif) {
      if (yeni.tedaviAktif != TedaviTuru.yok) {
        _bildirimKuyrugu.add(
          'Zon ${yeni.zone}: ${tedaviEtiketi(yeni.tedaviAktif)} başlatıldı',
        );
      } else if (onceki.tedaviAktif != TedaviTuru.yok) {
        _bildirimKuyrugu.add('Zon ${yeni.zone}: Tedavi tamamlandı, durulama başladı');
      }
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
    _tarlalar = _tarlalar.where((t) => t.id != id).toList();
    await _depolama.tarlalariKaydet(_tarlalar);
    notifyListeners();
  }

  Future<void> tarlaGuncelle(Tarla guncelTarla) async {
    _tarlalar = _tarlalar.map((t) => t.id == guncelTarla.id ? guncelTarla : t).toList();
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

  Future<void> mqttAyarlariniGuncelle({required String host, required int port}) async {
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
