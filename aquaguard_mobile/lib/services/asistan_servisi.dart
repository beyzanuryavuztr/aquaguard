/// AquaGuard - Akilli Asistan Servisi
/// ======================================
///
/// Amac:
///   Operatorun serbest metinle sordugu sorulari (Turkce, "Zon 3 nasil?",
///   "kac tedavi yapildi?", "en cok hangi tur tikanma goruluyor?" gibi)
///   uygulamanin O ANKI CANLI verisine (UygulamaDurumu) bakarak yanitlar.
///
///   BILINCLI TASARIM KARARI: Bu bir LLM/harici API entegrasyonu DEGILDIR --
///   tamamen yerel, kural/anahtar-kelime tabanli bir niyet (intent) eslesmesi
///   kullanir. Nedenleri:
///     1) Demo/yaris ortaminda internet baglantisina/API anahtarina bagimli
///        kalmak riskli olurdu (bkz. bu proje daha once gercek MQTT-uzerinden
///        internet baglantisinin guvenilmez cikmasi nedeniyle Demo Modu'na
///        yonelmisti -- ayni ders burada da gecerli).
///     2) Asistanin SADECE uygulamanin kendi dogru/guncel verisi hakkinda
///        konusmasi istenir -- serbest bir LLM'in "halusinasyon" riski
///        (olmayan bir zon hakkinda uydurma bilgi vermesi) burada YOKTUR.
///     3) Tamamen offline calisir, gecikme sifir, test edilebilir (bkz.
///        test/asistan_servisi_test.dart).
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import '../models/sensor_okuma.dart';
import '../providers/uygulama_durumu.dart';

class AsistanServisi {
  AsistanServisi._();

  static const List<String> ornekSorular = [
    'Genel durum nasıl?',
    'Zon 3 nasıl?',
    'Kaç tedavi yapıldı?',
    'En çok hangi tıkanma türü görülüyor?',
    'Hangi zonlarda sulama durduruldu?',
    'Çevrimdışı zon var mı?',
  ];

  /// Turkce metni karsilastirma icin normalize eder: kucuk harfe cevirir,
  /// Turkce'ye ozgu buyuk/kucuk harf donusumlerini (I/ı, İ/i) dogru yapar.
  static String _normallestir(String metin) {
    return metin
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .trim();
  }

  static final RegExp _zonNumarasiDeseni = RegExp(r'zon\s*(\d+)');

  /// Kullanicinin sorusuna gore bir yanit uretir. [durum] o anki canli
  /// UygulamaDurumu'dur -- her cagrida GUNCEL veriye bakilir.
  static String yanitUret(String soru, UygulamaDurumu durum) {
    final s = _normallestir(soru);

    if (s.isEmpty) {
      return 'Bir şey yazmadınız. ${_ornekSoruOner()}';
    }

    final zonEslesmesi = _zonNumarasiDeseni.firstMatch(s);
    if (zonEslesmesi != null) {
      final zon = int.parse(zonEslesmesi.group(1)!);
      return _zonYanitiUret(zon, durum);
    }

    if (_herhangiBiriGeciyorMu(s, [
      'merhaba',
      'selam',
      'günaydın',
      'iyi günler',
    ])) {
      return 'Merhaba! Size sistem durumu hakkında yardımcı olabilirim. '
          '${_ornekSoruOner()}';
    }

    if (_herhangiBiriGeciyorMu(s, ['teşekkür', 'sağol', 'sagol'])) {
      return 'Rica ederim! Başka bir sorunuz olursa buradayım.';
    }

    if (_herhangiBiriGeciyorMu(s, [
      'yardım',
      'ne sorabilir',
      'komut',
      'neler sorabilir',
    ])) {
      return 'Şunun gibi sorular sorabilirsiniz:\n'
          '${ornekSorular.map((s) => '• $s').join('\n')}';
    }

    if (_herhangiBiriGeciyorMu(s, [
      'kaç tarla',
      'tarla sayısı',
      'kaç zon',
      'zon sayısı',
    ])) {
      return '${durum.tarlalar.length} tarlanız ve toplam '
          '${durum.tumZonNumaralari.length} izlenen zonunuz var.';
    }

    if (_herhangiBiriGeciyorMu(s, [
      'çevrimdışı',
      'cevrimdisi',
      'bağlantı kesil',
      'offline',
    ])) {
      return _cevrimdisiYanitiUret(durum);
    }

    if (_herhangiBiriGeciyorMu(s, [
      'sulama',
      'vana',
      'vanayı',
      'vanası',
    ])) {
      return _sulamaYanitiUret(durum);
    }

    if (_herhangiBiriGeciyorMu(s, [
      'kaç tedavi',
      'tedavi sayısı',
      'kaç kere tedavi',
      'tedavi kaç',
    ])) {
      return _tedaviSayilariYanitiUret(durum);
    }

    if (_herhangiBiriGeciyorMu(s, [
      'en çok',
      'en sık',
      'hangi tür yaygın',
      'yaygın tür',
      'en fazla',
    ])) {
      return _enYayginTurYanitiUret(durum);
    }

    if (_herhangiBiriGeciyorMu(s, [
      'genel durum',
      'nasıl gidiyor',
      'sistem nasıl',
      'her şey yolunda',
      'durum ne',
      'özet',
    ])) {
      return _genelDurumYanitiUret(durum);
    }

    return 'Bunu tam olarak anlayamadım. ${_ornekSoruOner()}';
  }

  static bool _herhangiBiriGeciyorMu(String metin, List<String> anahtarlar) {
    return anahtarlar.any((a) => metin.contains(_normallestir(a)));
  }

  static String _ornekSoruOner() {
    return 'Örneğin "genel durum nasıl?" ya da "zon 2 nasıl?" diye sorabilirsiniz.';
  }

  static String _genelDurumYanitiUret(UygulamaDurumu durum) {
    final ozet = durum.durumOzetiHesapla(durum.tumZonNumaralari);
    if (durum.tumZonNumaralari.isEmpty) {
      return 'Henüz izlenen bir zon yok.';
    }
    final parcalar = <String>[];
    if (ozet.normal > 0) parcalar.add('${ozet.normal} zon normal');
    if (ozet.tedavide > 0) parcalar.add('${ozet.tedavide} zon tedavide');
    if (ozet.tespitEdildi > 0) {
      parcalar.add('${ozet.tespitEdildi} zonda tıkanma tespit edildi');
    }
    if (ozet.belirsiz > 0) {
      parcalar.add('${ozet.belirsiz} zon belirsiz durumda (operatör kontrolü gerekiyor)');
    }
    if (ozet.cevrimdisi > 0) parcalar.add('${ozet.cevrimdisi} zon çevrimdışı');

    final sonuc = parcalar.isEmpty
        ? 'Şu anda tüm zonlar hakkında veri bekleniyor.'
        : '${parcalar.join(', ')}.';

    final acilDikkat = ozet.tespitEdildi > 0 || ozet.belirsiz > 0;
    return 'Şu anda $sonuc'
        '${acilDikkat ? '\n\nDikkat gerektiren zonlar var, ilgili zon kartına dokunarak detaya bakabilirsiniz.' : ' Sistem sorunsuz çalışıyor.'}';
  }

  static String _zonYanitiUret(int zon, UygulamaDurumu durum) {
    if (!durum.tumZonNumaralari.contains(zon)) {
      return 'Zon $zon adında izlenen bir zon bulamadım. '
          'İzlenen zonlar: ${durum.tumZonNumaralari.join(", ")}.';
    }

    final okuma = durum.sonOkuma(zon);
    final cevrimici = durum.zonCevrimiciMi(zon);
    if (okuma == null) {
      return 'Zon $zon için henüz veri alınmadı.';
    }

    final satirlar = <String>[
      'Zon $zon: ${durumEtiketi(okuma.durum)}${cevrimici ? '' : ' (çevrimdışı, son bilinen durum)'}',
    ];
    if (okuma.durum == TeshisDurumu.tespitEdildi ||
        okuma.durum == TeshisDurumu.belirsiz) {
      satirlar.add(
        'Tür: ${turEtiketi(okuma.tikanmaTuru)}, güven: %${okuma.guven.toStringAsFixed(0)}',
      );
    }
    if (okuma.tedaviAktif != TedaviTuru.yok) {
      satirlar.add('${tedaviEtiketi(okuma.tedaviAktif)} şu anda uygulanıyor.');
    } else if (okuma.durulamaAktif) {
      satirlar.add('Zorunlu durulama sürüyor.');
    }
    if (durum.sulamasiDurduruldu(zon)) {
      satirlar.add('⚠ Bu zonun sulaması operatör tarafından durduruldu.');
    }
    return satirlar.join('\n');
  }

  static String _tedaviSayilariYanitiUret(UygulamaDurumu durum) {
    final sayaclar = durum.tedaviSayaclari;
    final toplam = sayaclar.values.fold(0, (a, b) => a + b);
    if (toplam == 0) {
      return 'Şimdiye kadar hiç tedavi uygulanmadı.';
    }
    return 'Şimdiye kadar toplam $toplam tedavi uygulandı: '
        '${sayaclar[TedaviTuru.asitDozlama]} asit dozlama, '
        '${sayaclar[TedaviTuru.klorEnjeksiyon]} klor enjeksiyonu, '
        '${sayaclar[TedaviTuru.yuksekBasincliYikama]} yüksek basınçlı yıkama.';
  }

  static String _enYayginTurYanitiUret(UygulamaDurumu durum) {
    final sayaclar = <TikanmaTuru, int>{
      TikanmaTuru.kimyasal: 0,
      TikanmaTuru.biyolojik: 0,
      TikanmaTuru.fiziksel: 0,
    };
    for (final okuma in durum.tumOkumalarBirlesik) {
      if (okuma.durum == TeshisDurumu.tespitEdildi) {
        sayaclar[okuma.tikanmaTuru] = (sayaclar[okuma.tikanmaTuru] ?? 0) + 1;
      }
    }
    final toplam = sayaclar.values.fold(0, (a, b) => a + b);
    if (toplam == 0) {
      return 'Şimdiye kadar hiç tıkanma tespit edilmedi.';
    }
    final enYaygin = sayaclar.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final yuzde = (enYaygin.value / toplam * 100).toStringAsFixed(0);
    return 'Şimdiye kadar tespit edilen $toplam tıkanma olayının en yaygını '
        '${turEtiketi(enYaygin.key).toLowerCase()} tür (%$yuzde, ${enYaygin.value} olay).';
  }

  static String _cevrimdisiYanitiUret(UygulamaDurumu durum) {
    final cevrimdisiZonlar = durum.tumZonNumaralari
        .where((z) => !durum.zonCevrimiciMi(z))
        .toList();
    if (cevrimdisiZonlar.isEmpty) {
      return 'Şu anda çevrimdışı zon yok, tüm zonlar bağlı.';
    }
    return '${cevrimdisiZonlar.length} zon çevrimdışı: '
        '${cevrimdisiZonlar.map((z) => 'Zon $z').join(", ")}.';
  }

  static String _sulamaYanitiUret(UygulamaDurumu durum) {
    final durdurulanZonlar = durum.tumZonNumaralari
        .where((z) => durum.sulamasiDurduruldu(z))
        .toList();
    if (durdurulanZonlar.isEmpty) {
      return 'Şu anda hiçbir zonda manuel olarak durdurulmuş sulama yok, '
          'tüm ana vanalar açık.';
    }
    return '${durdurulanZonlar.length} zonda sulama manuel olarak durduruldu: '
        '${durdurulanZonlar.map((z) => 'Zon $z').join(", ")}.';
  }
}
