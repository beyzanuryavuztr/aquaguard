/// AquaGuard - Simulasyon (Demo) Servisi
/// =========================================
///
/// Amac:
///   Henuz gercek Deneyap Kart donanimi baglanmamisken uygulamayi TAM
///   FONKSIYONEL, gercekci ve profesyonel bir demo halinde gostermek icin
///   uygulama icinde (herhangi bir ag/MQTT baglantisi olmadan) sahte ama
///   FIZIKSEL OLARAK ANLAMLI sensor verisi uretir.
///
///   Mantik, python/aquaguard_mock_yayinci.py ile AYNIDIR (normal ->
///   kotulesme -> tedavi -> durulama -> iyilesme dongusu), sadece MQTT
///   yerine dogrudan Dart callback'i ile UygulamaDurumu'na beslenir. Karar
///   hesaplamasi icin karar_motoru.dart (Katman 1'in Dart karsiligi)
///   kullanilir -- boylece demo modundaki veriler, gercek cihazdan
///   gelecek verilerle AYNI KURALLARA gore siniflandirilir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';
import 'dart:math' as math;

import '../config/sensor_imzalari.dart';
import '../models/sensor_okuma.dart';
import 'karar_motoru.dart';

/// Tek bir senaryo adiminin ham verisi. `gecmis_veri_uretici.dart` da ayni
/// senaryo mantigini (bu sefer GECMISE DONUK zaman damgalariyla) kullanmak
/// icin bu sinifi ve `senaryoAdimlariUret()`'i disari acar.
class SimAdim {
  final Map<String, double> ornek;
  final TedaviTuru tedaviAktif;
  final bool durulamaAktif;

  const SimAdim(this.ornek, this.tedaviAktif, this.durulamaAktif);
}

TedaviTuru _tedaviEslemesi(String tur) {
  switch (tur) {
    case 'kimyasal':
      return TedaviTuru.asitDozlama;
    case 'biyolojik':
      return TedaviTuru.klorEnjeksiyon;
    case 'fiziksel':
      return TedaviTuru.yuksekBasincliYikama;
    default:
      return TedaviTuru.yok;
  }
}

/// [TikanmaTuru] enum'unu sensor_imzalari.dart haritasinin anahtarlarina
/// (String) cevirir -- manuel mudahale komutlari (operator secimi) enum
/// olarak gelir, senaryo ureteclerimiz ise String sinif adi bekler.
String _turAdi(TikanmaTuru tur) {
  switch (tur) {
    case TikanmaTuru.kimyasal:
      return 'kimyasal';
    case TikanmaTuru.biyolojik:
      return 'biyolojik';
    case TikanmaTuru.fiziksel:
      return 'fiziksel';
    case TikanmaTuru.yok:
      return 'normal';
  }
}

double _gaussianRastgele(math.Random rng) {
  final u1 = 1.0 - rng.nextDouble();
  final u2 = rng.nextDouble();
  return math.sqrt(-2.0 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

const double _demoGurultuCarpani = 0.5;

double _sensorDegeriHesapla(
  String sensor,
  String kaynakSinif,
  String hedefSinif,
  double ilerleme,
  math.Random rng,
) {
  final kaynak = sensorImzalari[kaynakSinif]![sensor]!;
  final hedef = sensorImzalari[hedefSinif]![sensor]!;
  final ort = kaynak.ortalama + (hedef.ortalama - kaynak.ortalama) * ilerleme;
  final std = kaynak.std + (hedef.std - kaynak.std) * ilerleme;
  return ort + _gaussianRastgele(rng) * std * _demoGurultuCarpani;
}

Map<String, double> _tamOrnekUret(
  String kaynakSinif,
  String hedefSinif,
  double ilerleme,
  math.Random rng,
) {
  return {
    for (final sensor in sensorSirasi)
      sensor: _sensorDegeriHesapla(
        sensor,
        kaynakSinif,
        hedefSinif,
        ilerleme,
        rng,
      ),
  };
}

/// Durulama + iyilesme kuyruk adimlari (tedavi bittikten -- otonom veya
/// operatorun ERKEN durdurmasindan sonra -- normale donusu temsil eder).
/// Manuel "Tedaviyi Durdur" komutu da GUVENLIK geregi bu adimlardan gecer --
/// firmware/treatment.h'deki "her tedavi sonrasi zorunlu durulama" kuralinin
/// demo tarafindaki karsiligi (bkz. manuelTedaviDurdur()).
Iterable<SimAdim> durulamaVeIyilesmeAdimlariUret(
  String hedefTur,
  math.Random rng,
) sync* {
  const durulamaAdim = 2;
  for (var i = 0; i < durulamaAdim; i++) {
    final ilerleme = (0.5 - 0.25 * i).clamp(0.0, 1.0);
    yield SimAdim(
      _tamOrnekUret('normal', hedefTur, ilerleme, rng),
      TedaviTuru.yok,
      true,
    );
  }

  const iyilesmeAdim = 4;
  for (var i = 1; i <= iyilesmeAdim; i++) {
    final ilerleme = (0.25 - 0.25 * (i / iyilesmeAdim)).clamp(0.0, 1.0);
    yield SimAdim(
      _tamOrnekUret('normal', hedefTur, ilerleme, rng),
      TedaviTuru.yok,
      false,
    );
  }
}

/// Tedavi + durulama + iyilesme kuyrugu -- otonom akisin (kotulesme sonrasi)
/// ve manuel "Tedaviyi Baslat" komutunun (bkz. manuelTedaviBaslat()) ORTAK
/// kullandigi tek kaynak.
Iterable<SimAdim> tedaviVeIyilesmeAdimlariUret(
  String hedefTur,
  math.Random rng,
) sync* {
  final tedaviTuru = _tedaviEslemesi(hedefTur);
  const tedaviAdim = 3;
  for (var i = 0; i < tedaviAdim; i++) {
    final ilerleme = (1.0 - 0.15 * i).clamp(0.0, 1.0);
    yield SimAdim(
      _tamOrnekUret('normal', hedefTur, ilerleme, rng),
      tedaviTuru,
      false,
    );
  }

  yield* durulamaVeIyilesmeAdimlariUret(hedefTur, rng);
}

/// Sonsuz bir senaryo akisi: normal -> kotulesme -> tedavi -> durulama ->
/// iyilesme, ardindan yeni rastgele bir tikanma turuyle tekrar basa doner.
Iterable<SimAdim> senaryoAdimlariUret(math.Random rng) sync* {
  const turler = ['kimyasal', 'biyolojik', 'fiziksel'];

  while (true) {
    final hedefTur = turler[rng.nextInt(turler.length)];

    for (var i = 0; i < 4; i++) {
      yield SimAdim(
        _tamOrnekUret('normal', 'normal', 0.0, rng),
        TedaviTuru.yok,
        false,
      );
    }

    const kotulesmeAdim = 6;
    for (var i = 1; i <= kotulesmeAdim; i++) {
      final ilerleme = i / kotulesmeAdim;
      yield SimAdim(
        _tamOrnekUret('normal', hedefTur, ilerleme, rng),
        TedaviTuru.yok,
        false,
      );
    }

    yield* tedaviVeIyilesmeAdimlariUret(hedefTur, rng);
  }
}

class SimulasyonServisi {
  final List<int> zonlar;
  final void Function(SensorOkuma okuma) veriUretildiginde;

  final Map<int, Iterator<SimAdim>> _iteratorlar = {};
  final Map<int, math.Random> _rnglar = {};
  // MUTEX KILIDI (ACIMASIZ DENETIM, 2026-09-06): firmware/treatment.h'deki
  // GERCEK guvenlik kuralinin ("_aktifTedavi != TEDAVI_YOK || _durulamaAktif"
  // iken YENI tedavi reddedilir) demo tarafindaki birebir karsiligi. Daha
  // once manuelTedaviBaslat() bu kontrolu HIC yapmiyordu -- ayni zonda suren
  // bir tedavinin uzerine YENI bir tedavi cagrisi SESSIZCE eskisini iptal
  // edip yerine geciyordu, bu da "Mutex Kilidi" demo senaryosunun aslinda
  // hicbir seyi kilitlemedigi (iki FARKLI zonu es zamanli tetikleyip trivial
  // bir sonuc gosterdigi) bir tasarim eksikligine yol aciyordu. Bu harita,
  // _birAdimUret()'te HER adimda guncellenerek otonom donguyle de senkron
  // kalir (tedavi/durulama bitip normale donduğunde otomatik false olur).
  final Map<int, bool> _zonMesgulMu = {};
  // OPERATOR MUDAHALESI: sulamasi manuel durdurulmus zonlar -- bkz.
  // sulamayiDuraklat()/sulamayiDevamEttir(). Bu zonlar icin _birAdimUret()
  // yeni veri uretmez (vana kapaliyken sensor okumasinin "ilerlemesi"
  // anlamsizdir); UI son bilinen okumayi donduralm gosterir.
  final Set<int> _sulamasiDurdurulanZonlar = {};
  Timer? _zamanlayici;

  SimulasyonServisi({required this.zonlar, required this.veriUretildiginde});

  bool get calisiyorMu => _zamanlayici != null;

  void baslat({Duration aralik = const Duration(seconds: 3)}) {
    final tohumRng = math.Random();
    _iteratorlar.clear();
    _rnglar.clear();
    _sulamasiDurdurulanZonlar.clear();
    _zonMesgulMu.clear();
    for (final zon in zonlar) {
      final rng = math.Random(tohumRng.nextInt(0x7FFFFFFF));
      _rnglar[zon] = rng;
      _iteratorlar[zon] = senaryoAdimlariUret(rng).iterator;
    }

    _zamanlayici?.cancel();
    _birAdimUret(); // ilk veriyi hemen goster, kullanici beklemesin
    _zamanlayici = Timer.periodic(aralik, (_) => _birAdimUret());
  }

  void durdur() {
    _zamanlayici?.cancel();
    _zamanlayici = null;
    _iteratorlar.clear();
    _rnglar.clear();
    _sulamasiDurdurulanZonlar.clear();
    _zonMesgulMu.clear();
  }

  /// Jüri sunumu icin veri uretim HIZINI degistirir -- baslat()'in aksine
  /// zon iteratorlerini/RNG'lerini SIFIRLAMAZ, sadece zamanlayicinin
  /// periyodunu degistirir. Boylece hiz degisirken devam eden bir
  /// senaryo (ornegin bir tedavi ortasinda) KESINTIYE UGRAMAZ.
  void hiziDegistir(Duration yeniAralik) {
    if (_zamanlayici == null) return; // calismiyorsa hicbir sey yapma
    _zamanlayici!.cancel();
    _zamanlayici = Timer.periodic(yeniAralik, (_) => _birAdimUret());
  }

  /// OPERATOR MUDAHALESI: zonun ana vanasini manuel kapatir -- zamanlayici
  /// tikinde bu zon icin ARTIK yeni veri uretilmez (son okuma donuk kalir).
  void sulamayiDuraklat(int zone) => _sulamasiDurdurulanZonlar.add(zone);

  /// Manuel kapatilmis sulamayi yeniden acar -- bir sonraki tikte kaldigi
  /// senaryo adimindan (kesintiye ugramamis gibi) devam eder.
  void sulamayiDevamEttir(int zone) => _sulamasiDurdurulanZonlar.remove(zone);

  bool sulamaDuraklatilmisMi(int zone) =>
      _sulamasiDurdurulanZonlar.contains(zone);

  void _birAdimUret() {
    for (final zon in zonlar) {
      if (_sulamasiDurdurulanZonlar.contains(zon)) continue;
      final iterator = _iteratorlar[zon];
      if (iterator == null || !iterator.moveNext()) continue;
      final adim = iterator.current;
      // Mutex durumunu otonom donguyle senkron tut: tedavi/durulama dogal
      // olarak bitip normale donduğunde de kilit KENDILIGINDEN acilir.
      _zonMesgulMu[zon] = adim.tedaviAktif != TedaviTuru.yok || adim.durulamaAktif;
      veriUretildiginde(simAdimindanOkumaUret(adim, zon, DateTime.now()));
    }
  }

  /// Zon su an bir tedavi VEYA zorunlu durulama surdugu icin YENI bir tedavi
  /// KABUL ETMEZ mi? (bkz. manuelTedaviBaslat -- firmware/treatment.h'deki
  /// "_aktifTedavi != TEDAVI_YOK || _durulamaAktif" kuralinin birebir demo
  /// karsiligi).
  bool zonMesgulMu(int zone) => _zonMesgulMu[zone] ?? false;

  /// OPERATOR MUDAHALESI: Ilgili zonun akisini, secilen tikanma turune karsi
  /// bir tedavi+iyilesme dongusuyle DEGISTIRIR (otonom kotulesme adimlarini
  /// atlayarak), ardindan normal otonom donguye geri doner. "Belirsiz"
  /// durumda sistem turu kendisi secemedigi icin operatorun devreye girmesini
  /// saglar.
  ///
  /// MUTEX KILIDI: zon zaten mesgulse (bir tedavi veya zorunlu durulama
  /// suruyorsa) istek REDDEDILIR ve false donulur -- tipki gercek firmware'in
  /// tedaviBaslat()'inin yaptigi gibi. Basariliysa etki ANINDA (bir sonraki
  /// zamanlayici tikini beklemeden) _zonMesgulMu'ye yansitilir; boylece ayni
  /// zona hemen ardindan gelecek ikinci bir cagri da dogru sekilde reddedilir.
  bool manuelTedaviBaslat(int zone, TikanmaTuru tur) {
    if (!zonlar.contains(zone)) return false;
    if (zonMesgulMu(zone)) return false;
    final rng = _rnglar[zone] ?? math.Random();
    _rnglar[zone] = rng;
    _iteratorlar[zone] = tedaviVeIyilesmeAdimlariUret(
      _turAdi(tur),
      rng,
    ).followedBy(senaryoAdimlariUret(rng)).iterator;
    _zonMesgulMu[zone] = true;
    return true;
  }

  /// OPERATOR MUDAHALESI: Su an suren bir tedaviyi ERKEN sonlandirir. Guvenlik
  /// geregi dogrudan "normal"e atlamaz -- once zorunlu durulama+iyilesme
  /// adimlarindan gecer (bkz. firmware/treatment.h ayni kural), sonra normal
  /// otonom donguye doner. [guncelTur], durulama gorselinin hangi tikanma
  /// turunden iyilesecegini gostermesi icin gerekir. Mutex kilidi durulama
  /// boyunca ACIK kalir (_birAdimUret durulama adimlarinda da mesgul isaretler).
  void manuelTedaviDurdur(int zone, TikanmaTuru guncelTur) {
    if (!zonlar.contains(zone)) return;
    final rng = _rnglar[zone] ?? math.Random();
    _rnglar[zone] = rng;
    _iteratorlar[zone] = durulamaVeIyilesmeAdimlariUret(
      _turAdi(guncelTur),
      rng,
    ).followedBy(senaryoAdimlariUret(rng)).iterator;
    _zonMesgulMu[zone] = true;
  }

  /// OPERATOR MUDAHALESI: "Yanlis alarm" -- hicbir tedaviye gerek olmadan
  /// dogrudan normal izlemeye doner (durulama gerekmez, cunku hicbir aktuator
  /// hic calismadi). Mutex kilidini de ACAR (zon zaten mesgul degildi).
  void manuelNormaleDondur(int zone) {
    if (!zonlar.contains(zone)) return;
    final rng = _rnglar[zone] ?? math.Random();
    _rnglar[zone] = rng;
    _iteratorlar[zone] = senaryoAdimlariUret(rng).iterator;
    _zonMesgulMu[zone] = false;
  }
}

/// Bir [SimAdim]'i (karar motorunu calistirarak) tam bir [SensorOkuma]'ya
/// cevirir. Hem canli SimulasyonServisi hem de GecmisVeriUreticisi (gecmise
/// donuk toplu veri uretimi) AYNI bu fonksiyonu kullanir -- tek kaynak.
SensorOkuma simAdimindanOkumaUret(SimAdim adim, int zone, DateTime zaman) {
  final teshis = KararMotoru.teshisEt(adim.ornek);
  return SensorOkuma(
    zaman: zaman,
    zone: zone,
    ph: adim.ornek['ph']!,
    ec: adim.ornek['ec']!,
    orp: adim.ornek['orp']!,
    turbidite: adim.ornek['turbidite']!,
    debi: adim.ornek['debi']!,
    deltaBasinc: adim.ornek['delta_basinc']!,
    durum: teshis.durum,
    tikanmaTuru: teshis.tur,
    guven: teshis.guven,
    guvenKimyasal: teshis.guvenKimyasal,
    guvenBiyolojik: teshis.guvenBiyolojik,
    guvenFiziksel: teshis.guvenFiziksel,
    tedaviAktif: adim.tedaviAktif,
    durulamaAktif: adim.durulamaAktif,
  );
}
