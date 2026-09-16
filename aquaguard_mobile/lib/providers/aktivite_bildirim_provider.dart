/// AquaGuard - Aktivite/Bildirim Provider (Mimari Bolunme, Faz 12)
/// ======================================================================
///
/// Amac:
///   Tum zonlardaki onemli olaylarin kalici gecmisini (aktiviteGecmisi),
///   bunlardan bildirime DONUSENLERIN kalici listesini (bildirimGecmisi)
///   ve aninda gosterilecek bildirim kuyrugunu tasir. CihazIletisimProvider
///   (sensor verisi degisimlerini algilayan) ve GuvenlikProvider/diger
///   provider'lar (manuel mudahale kayitlari icin) bu provider'a bir
///   REFERANS alip [aktiviteKaydiEkle]'yi cagirir -- boylece "bir olay
///   oldugunda nasil kaydedilir/bildirilir" mantigi TEK bir yerde kalir
///   (eskiden UygulamaDurumu icinde 5 farkli yerde elle kopyalanmisti,
///   bkz. [[feedback-schema-single-source-of-truth]] -- bu HALA gecerli,
///   sadece artik ayri bir sinifta).
///
///   AyarlarProvider'a bir REFERANS tutar (bildirim tercihlerini okumak
///   icin, bkz. _bildirimKategoriAcikMi) -- bu, iki provider arasindaki
///   TEK gercek çapraz bagimliliktir, main.dart'ta kurulur.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/foundation.dart';

import '../models/aktivite_kaydi.dart';
import '../models/enerji_durumu.dart';
import '../repositories/aktivite_bildirim_repository.dart';
import 'ayarlar_provider.dart';
import 'depolama_unawaited.dart';

class AktiviteBildirimProvider extends ChangeNotifier {
  final AktiviteBildirimRepository _depo;
  final AyarlarProvider _ayarlar;

  // Alan adi (_ayarlar) private oldugu icin parametre adiyla (ayarlar)
  // birebir eslestirilemez (bkz. asagidaki ignore) -- farkli dosyalardan
  // (main.dart) named-parameter olarak cagrilabilmesi icin parametre
  // PUBLIC bir isim tasimak zorunda.
  AktiviteBildirimProvider({
    required AyarlarProvider ayarlar,
    AktiviteBildirimRepository? depo,
  }) : _depo = depo ?? SharedPreferencesAktiviteBildirimRepository(),
       // ignore: prefer_initializing_formals
       _ayarlar = ayarlar;

  final List<AktiviteKaydi> _bildirimKuyrugu = [];
  final List<AktiviteKaydi> _aktiviteGecmisi = [];
  // BILDIRIM GECMISI: _aktiviteGecmisi'nin (TUM olaylar) aksine, sadece
  // gercekten bir bildirime DONUSMUS (operatorun 4 kategorili tercihini
  // GECEN) kayitlarin kalici listesi -- Bildirim Gecmisi ekraninin ve
  // rozetin (badge) kaynagi. Ikisi de aktiviteKaydiEkle() icinde AYNI
  // anda beslenir, ayri ayri elle kopyalanmaz.
  final List<AktiviteKaydi> _bildirimGecmisi = [];
  // Okundu olarak isaretlenmis bildirim ID'leri (bkz.
  // models/aktivite_kaydi.dart -> bildirimIdGetir()). bildirimGecmisi'nden
  // dusen (200 sinirini asan) eski kayitlarin ID'si buradan da temizlenir --
  // aksi halde bu kume sonsuza dek buyurdu.
  final Set<int> _okunmusBildirimIdleri = {};

  List<AktiviteKaydi> get aktiviteGecmisi =>
      List.unmodifiable(_aktiviteGecmisi);
  List<AktiviteKaydi> get bildirimGecmisi =>
      List.unmodifiable(_bildirimGecmisi);
  int get okunmamisBildirimSayisi =>
      _bildirimGecmisi.where((k) => !bildirimOkunmusMu(k)).length;

  bool bildirimOkunmusMu(AktiviteKaydi kayit) =>
      _okunmusBildirimIdleri.contains(bildirimIdGetir(kayit));

  Future<void> baslat() async {
    final oncedenKayitliAktiviteler = await _depo.aktiviteGecmisiGetir();
    _aktiviteGecmisi.addAll(oncedenKayitliAktiviteler);
    _aktiviteGecmisi.sort((a, b) => b.zaman.compareTo(a.zaman));
    if (_aktiviteGecmisi.length > 200) {
      _aktiviteGecmisi.removeRange(200, _aktiviteGecmisi.length);
    }

    _bildirimGecmisi.addAll(await _depo.bildirimGecmisiGetir());
    _bildirimGecmisi.sort((a, b) => b.zaman.compareTo(a.zaman));
    if (_bildirimGecmisi.length > 200) {
      _bildirimGecmisi.removeRange(200, _bildirimGecmisi.length);
    }

    _okunmusBildirimIdleri.addAll(
      await _depo.okunmusBildirimIdleriGetir(),
    );

    _dusukPilKontroluYap();
    notifyListeners();
  }

  /// Ilk kurulumda (bir zonun HIC gecmisi yoksa) uretilen GECMISE DONUK
  /// sentetik aktiviteleri toplu ekler -- CihazIletisimProvider.baslat()
  /// tarafindan, sentetik sensor gecmisi urettigi sirada cagrilir.
  /// Canli SnackBar/push bildirimi KASITLI OLARAK tetiklenmez (backdated
  /// veri icin bildirim firtinasi olmasin diye), ama kalici gecmislere
  /// (kategori tercihine uyanlar) eklenir.
  void tohumVerisiEkle(List<AktiviteKaydi> uretilenlerEnYeniOnce) {
    _aktiviteGecmisi.addAll(uretilenlerEnYeniOnce);
    _bildirimGecmisi.addAll(
      uretilenlerEnYeniOnce.where((k) => _bildirimKategoriAcikMi(k.tur)),
    );
  }

  /// tohumVerisiEkle()'den SONRA, kalici depoya YAZMAK icin -- ayri
  /// tutulmasinin nedeni: CihazIletisimProvider.baslat() birden fazla
  /// zon icin tohumVerisiEkle() cagirabilir, her seferinde diske
  /// yazmak yerine hepsi bittikten SONRA TEK seferde yazilir (orijinal
  /// UygulamaDurumu.baslat() ile AYNI davranis).
  Future<void> tohumVerisiniKaydet() async {
    if (_aktiviteGecmisi.isEmpty && _bildirimGecmisi.isEmpty) return;

    // baslat() zaten kalici gecmisi YUKLEYIP SIRALAMIŞTI (en yeni once);
    // tohumVerisiEkle() ise sonradan uretilen zon verilerini bu listenin
    // SONUNA ekliyordu -- bu yuzden burada TEKRAR sirala+kirp, aksi halde
    // "en yeni once" degismezi (invariant) bozulur (birden fazla zonun
    // sentetik verisi birbirine karismis, kronolojik olmayan sirada kalir).
    _aktiviteGecmisi.sort((a, b) => b.zaman.compareTo(a.zaman));
    if (_aktiviteGecmisi.length > 200) {
      _aktiviteGecmisi.removeRange(200, _aktiviteGecmisi.length);
    }
    _bildirimGecmisi.sort((a, b) => b.zaman.compareTo(a.zaman));
    if (_bildirimGecmisi.length > 200) {
      _bildirimGecmisi.removeRange(200, _bildirimGecmisi.length);
    }

    unawaited(_depo.aktiviteGecmisiniKaydet(_aktiviteGecmisi));
    unawaited(_depo.bildirimGecmisiniKaydet(_bildirimGecmisi));
    notifyListeners();
  }

  List<AktiviteKaydi> bildirimleriAlVeTemizle() {
    final kopya = List<AktiviteKaydi>.from(_bildirimKuyrugu);
    _bildirimKuyrugu.clear();
    return kopya;
  }

  /// Bildirim Gecmisi ekrani acildiginda cagrilir -- suan bildirimGecmisi'nde
  /// olan TUM kayitlari okunmus isaretler (rozet sifirlanir). Okunmus ID
  /// kumesi, GUNCEL bildirimGecmisi ID'leriyle KESISTIRILEREK kaydedilir --
  /// aksi halde 200 sinirindan dusen eski kayitlarin ID'si kumede sonsuza
  /// dek birikirdi.
  Future<void> bildirimleriOkunduIsaretle() async {
    final guncelIdler = _bildirimGecmisi.map(bildirimIdGetir).toSet();
    _okunmusBildirimIdleri
      ..addAll(guncelIdler)
      ..retainAll(guncelIdler);
    await _depo.okunmusBildirimIdleriniKaydet(_okunmusBildirimIdleri);
    notifyListeners();
  }

  /// TEK giris noktasi: bir AktiviteKaydi'ni kalici aktivite gecmisine
  /// ekler VE (bildirimDegerlendir true ise VE kategori acik ise) hem
  /// aninda gosterilecek bildirim kuyruguna, hem de kalici Bildirim
  /// Gecmisi'ne ekler.
  void aktiviteKaydiEkle(
    AktiviteKaydi kayit, {
    bool bildirimDegerlendir = true,
  }) {
    _aktiviteGecmisi.insert(0, kayit);
    if (_aktiviteGecmisi.length > 200) _aktiviteGecmisi.removeLast();
    unawaited(_depo.aktiviteGecmisiniKaydet(_aktiviteGecmisi));

    if (bildirimDegerlendir && _bildirimKategoriAcikMi(kayit.tur)) {
      _bildirimKuyrugu.add(kayit);
      _bildirimGecmisi.insert(0, kayit);
      if (_bildirimGecmisi.length > 200) _bildirimGecmisi.removeLast();
      unawaited(_depo.bildirimGecmisiniKaydet(_bildirimGecmisi));
    }
    notifyListeners();
  }

  /// Bir aktivite turunun BILDIRIM kuyruguna eklenip eklenmeyecegini,
  /// operatorun 4 kategorili tercihine (bkz. models/bildirim_tercihleri.dart)
  /// gore belirler. "belirsiz" tespit kategorisiyle, "normale donus" tedavi
  /// tamamlanma kategorisiyle GRUPLANIR; operatorun kendi eylemlerini
  /// (manuelMudahale) onaylayan bildirimler HER ZAMAN gosterilir.
  bool _bildirimKategoriAcikMi(AktiviteTuru tur) {
    final tercihler = _ayarlar.bildirimTercihleri;
    switch (tur) {
      case AktiviteTuru.tespit:
      case AktiviteTuru.belirsiz:
        return tercihler.tespit;
      case AktiviteTuru.tedaviBaslangic:
        return tercihler.tedaviBaslangic;
      case AktiviteTuru.tedaviBitis:
      case AktiviteTuru.normaleDonus:
        return tercihler.tedaviTamamlanma;
      case AktiviteTuru.dusukPil:
        return tercihler.dusukPil;
      case AktiviteTuru.manuelMudahale:
        return true;
    }
  }

  /// SIMULE pil seviyesini (bkz. models/enerji_durumu.dart) kontrol eder;
  /// esigin altindaysa VE operator bu kategoriyi actiysa, uygulama her
  /// SOGUK basladiginda bir bildirim kuyruklar.
  void _dusukPilKontroluYap() {
    final pil = EnerjiDurumu.pilYuzdesiHesapla();
    if (pil >= EnerjiDurumu.dusukPilEsigi) return;

    // Pil seviyesi ZAMAN BAZLI (10 gunluk testere disi dongu) bir
    // simulasyondur -- bu esigin ALTINDA kaldigi surece (birkac gun),
    // HER SOGUK BASLANGICTA ayni uyariyi TEKRAR eklemek hem gercek
    // kullaniciya bildirim spam'i hem de testlerde belirsizlik yaratirdi.
    // Son 24 saat icinde ZATEN bir dusukPil kaydi varsa tekrar eklenmez.
    final simdi = DateTime.now();
    final yakinZamandaUyarildiMi = _aktiviteGecmisi.any(
      (k) =>
          k.tur == AktiviteTuru.dusukPil &&
          simdi.difference(k.zaman) < const Duration(hours: 24),
    );
    if (yakinZamandaUyarildiMi) return;

    final kayit = AktiviteKaydi(
      zaman: simdi,
      zone: 0,
      mesaj: 'Pil seviyesi düşük: %$pil',
      tur: AktiviteTuru.dusukPil,
    );
    aktiviteKaydiEkle(kayit);
  }
}
