/// AquaGuard - Bakim Gorevi Veri Modeli
/// ============================================
///
/// Amac:
///   SDI sisteminin periyodik bakim gorevlerini (sensor kalibrasyonu, filtre
///   temizligi, vana kontrolu, genel denetim) temsil eder. Her gorevin bir
///   periyodu (gun) ve EN SON yapildigi tarih vardir; "sonraki tarih" ve
///   "gecikti mi" bu ikisinden HESAPLANIR (ayri bir "durum" alani tutulmaz --
///   tarih ilerledikce otomatik dogru kalir, proje genelinde tekrarlanan
///   "hesapla, ayri sayac tutma" ilkesiyle tutarli).
///
///   Gorev LISTESI sabit/varsayilan 4 gorevle baslar (kullanicinin kendi
///   gorev EKLEME/SILME akisi bu turda kapsam disi -- gercek SDI bakim
///   ihtiyaclarina dayanan, makul bir varsayilan set sunulur).
///
/// Tarih:  2026-09-05
library;

enum BakimDurumu { normal, yaklasiyor, gecikti }

class BakimGorevi {
  final String id;
  final String baslik;
  final String aciklama;
  final int periyotGun;
  final DateTime sonYapilmaTarihi;

  const BakimGorevi({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.periyotGun,
    required this.sonYapilmaTarihi,
  });

  DateTime get sonrakiTarih =>
      sonYapilmaTarihi.add(Duration(days: periyotGun));

  int kalanGun([DateTime? simdi]) =>
      sonrakiTarih.difference(simdi ?? DateTime.now()).inDays;

  /// "Yaklaşıyor" esigi: periyodun %20'si kadar gun kala VEYA en fazla 7
  /// gun kala (hangisi daha erken gelirse) -- kisa periyotlarda (ör. 30
  /// gun) mantiksiz uzun bir "yaklaşıyor" penceresi olusmamasi icin.
  BakimDurumu durumu([DateTime? simdi]) {
    final su = simdi ?? DateTime.now();
    // ACIMASIZ DENETIM NOTU (2026-09-06): Duration.inDays SIFIRA DOGRU
    // yuvarlar (Duration(hours: -12).inDays == 0, -1 DEGIL) -- kalanGun()'e
    // dayanan bir "kalan < 0" kontrolu, sona erme tarihinin uzerinden HENUZ
    // 24 saat gecmemis bir gorevi "gecikti" olarak YAKALAYAMAZDI (yanlislikla
    // "yaklaşıyor" gosterirdi). Bunun yerine DateTime karsilastirmasi
    // (isAfter) kullanilir -- yuvarlama hatasina karsi kesin.
    if (su.isAfter(sonrakiTarih)) return BakimDurumu.gecikti;
    final kalan = kalanGun(su);
    final yaklasiyorEsigi = (periyotGun * 0.2).clamp(1, 7).round();
    if (kalan <= yaklasiyorEsigi) return BakimDurumu.yaklasiyor;
    return BakimDurumu.normal;
  }

  BakimGorevi tamamlandiOlarakIsaretle([DateTime? simdi]) => BakimGorevi(
    id: id,
    baslik: baslik,
    aciklama: aciklama,
    periyotGun: periyotGun,
    sonYapilmaTarihi: simdi ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'baslik': baslik,
    'aciklama': aciklama,
    'periyotGun': periyotGun,
    'sonYapilmaTarihi': sonYapilmaTarihi.toIso8601String(),
  };

  factory BakimGorevi.fromJson(Map<String, dynamic> json) => BakimGorevi(
    id: json['id'] as String,
    baslik: json['baslik'] as String,
    aciklama: json['aciklama'] as String,
    periyotGun: (json['periyotGun'] as num).toInt(),
    sonYapilmaTarihi:
        DateTime.tryParse(json['sonYapilmaTarihi'] as String? ?? '') ??
        DateTime.now(),
  );
}

/// Sistem ilk kurulduğunda seed edilen varsayilan bakim gorevleri --
/// [simdi] test edilebilirlik icin disaridan verilebilir (varsayilan
/// DateTime.now()).
List<BakimGorevi> varsayilanBakimGorevleri([DateTime? simdi]) {
  final baslangic = simdi ?? DateTime.now();
  return [
    BakimGorevi(
      id: 'filtre_temizligi',
      baslik: 'Filtre Temizliği',
      aciklama: 'Ana hat filtresinin çıkarılıp temizlenmesi',
      periyotGun: 30,
      sonYapilmaTarihi: baslangic,
    ),
    BakimGorevi(
      id: 'vana_kontrolu',
      baslik: 'Vana/Valf Kontrolü',
      aciklama: 'Ana vana ve tedavi kanalı valflerinin mekanik kontrolü',
      periyotGun: 60,
      sonYapilmaTarihi: baslangic,
    ),
    BakimGorevi(
      id: 'sensor_kalibrasyonu',
      // NOT: Ayarlar'daki mevcut "Sensör Kalibrasyonu" bolum basligiyla
      // (salt-okunur kalibrasyon sabitleri karti, Asama 7) KASITLI olarak
      // AYNI metin degil -- ikisi ayni ekranda gorunuyor, ayirt edilebilir
      // olmali (ayrica testlerde find.text() belirsizligini onler).
      baslik: 'Sensör Kalibrasyon Kontrolü',
      aciklama: 'pH/EC/ORP sensörlerinin referans çözeltiyle kalibrasyonu',
      periyotGun: 90,
      sonYapilmaTarihi: baslangic,
    ),
    BakimGorevi(
      id: 'genel_denetim',
      baslik: 'Genel Sistem Denetimi',
      aciklama: 'Tüm lateral hatların ve emitörlerin görsel kontrolü',
      periyotGun: 180,
      sonYapilmaTarihi: baslangic,
    ),
  ];
}
