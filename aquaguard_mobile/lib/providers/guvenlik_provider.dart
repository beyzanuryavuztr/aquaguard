/// AquaGuard - Guvenlik Provider (PIN Korumasi, Mimari Bolunme Faz 12)
/// ============================================================================
///
/// Amac:
///   PIN korumasi acik/kapali durumu, oturum kilidi ve 3-yanlis-deneme
///   kilidini tasir. Eskiden tek bir "God Object" icindeydi -- bir PIN
///   denemesi HER ZAMAN tum sensor dashboard'unun da yeniden cizilmesine
///   sebep oluyordu (tek buyuk ChangeNotifier), artik SADECE bu veriyi
///   gosteren widget'lar (PinKilitEkrani, Ayarlar'daki Guvenlik karti)
///   yeniden cizilir.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/foundation.dart';

import '../services/depolama_servisi.dart';
import '../services/pin_servisi.dart';

class GuvenlikProvider extends ChangeNotifier {
  final DepolamaServisi _depolama;

  GuvenlikProvider({DepolamaServisi? depolama})
    : _depolama = depolama ?? DepolamaServisi();

  bool _pinKorumasiAktif = false;
  // Bu oturumda PIN kilidi henuz acilmadi mi? -- SADECE bellekte (kalici
  // DEGIL): her SOGUK acilista yeniden kilitlenmesi ISTENEN davranis.
  bool _pinKilitliSuAn = false;
  int _basarisizPinDenemesi = 0;
  DateTime? _pinKilitBitisZamani;

  bool get pinKorumasiAktif => _pinKorumasiAktif;
  bool get pinKilitliSuAn => _pinKorumasiAktif && _pinKilitliSuAn;

  /// 3 basarisiz denemeden sonra 30 saniyelik kilit -- SADECE bellekte
  /// tutulur (kalici depolanmaz): uygulama yeniden baslatilirsa kilit
  /// sifirlanir. Bu bilerek yapilmis bir kapsam karari -- gercek bir
  /// guvenlik urunu bunu kalici tutar, ama bu bir yarisma/demo uygulamasi
  /// ve asiri mühendislik burada oncelik degil.
  bool get pinGirisiKilitliMi =>
      _pinKilitBitisZamani != null &&
      DateTime.now().isBefore(_pinKilitBitisZamani!);

  Duration? get pinKilidiKalanSure => pinGirisiKilitliMi
      ? _pinKilitBitisZamani!.difference(DateTime.now())
      : null;

  Future<void> baslat() async {
    _pinKorumasiAktif = await _depolama.pinKorumasiAcikMi();
    _pinKilitliSuAn = _pinKorumasiAktif;
    notifyListeners();
  }

  /// PIN korumasini ACAR -- [yeniPin] guvenli depoya yazilir.
  Future<void> pinKorumasiniAc(String yeniPin) async {
    await PinServisi.pinKaydet(yeniPin);
    await _depolama.pinKorumasiniKaydet(true);
    _pinKorumasiAktif = true;
    notifyListeners();
  }

  Future<void> pinKorumasiniKapat() async {
    await PinServisi.pinSil();
    await _depolama.pinKorumasiniKaydet(false);
    _pinKorumasiAktif = false;
    _pinKilitliSuAn = false;
    _zamanAsimiylaKilitlendi = false;
    notifyListeners();
  }

  /// Girilen PIN'i dogrular. Yanlissa basarisiz deneme sayacini artirir ve
  /// 3. yanlistan sonra 30 saniyelik bir giris kilidi baslatir (bkz.
  /// pinGirisiKilitliMi). Dogruysa oturum kilidini acar ve sayaci sifirlar.
  Future<bool> pinDenemesiYap(String girilen) async {
    if (pinGirisiKilitliMi) return false;
    final dogruMu = await PinServisi.pinDogrula(girilen);
    if (dogruMu) {
      _basarisizPinDenemesi = 0;
      _pinKilitBitisZamani = null;
      _pinKilitliSuAn = false;
      _zamanAsimiylaKilitlendi = false;
      notifyListeners();
      return true;
    }
    _basarisizPinDenemesi++;
    if (_basarisizPinDenemesi >= 3) {
      _pinKilitBitisZamani = DateTime.now().add(const Duration(seconds: 30));
      _basarisizPinDenemesi = 0;
    }
    notifyListeners();
    return false;
  }

  /// Biyometrik dogrulama basarili oldugunda cagrilir -- PIN girisine
  /// gerek kalmadan oturum kilidini acar.
  void pinKilidiniBiyometrikIleAc() {
    _pinKilitliSuAn = false;
    _zamanAsimiylaKilitlendi = false;
    notifyListeners();
  }

  // ==========================================================================
  // OTURUM ZAMAN ASIMI (D3)
  // ==========================================================================
  //
  // Uygulama arka plana alindiktan sonra [zamanAsimi]'ndan UZUN sure
  // gecerse (telefon masada/cebinde acik unutuldu), on plana donuste PIN
  // yeniden istenir. SADECE PIN korumasi acikken ve oturum zaten kilitsizken
  // anlamlidir. Zaman kaynagi enjekte edilebilir (test icin).

  static const Duration varsayilanZamanAsimi = Duration(minutes: 5);

  DateTime? _arkaplanZamani;
  bool _zamanAsimiylaKilitlendi = false;

  /// Kilidin SOGUK acilis yerine zaman asimindan kaynaklandigini belirtir --
  /// arayuz sadece bu durumda PIN ekranini mevcut ekranin USTUNE bindirir
  /// (soguk acilista kilidi zaten baslangic yonlendiricisi gosteriyor).
  bool get zamanAsimiylaKilitlendi =>
      _zamanAsimiylaKilitlendi && pinKilitliSuAn;

  void arkaplanaAlindi({DateTime? simdi}) {
    if (!_pinKorumasiAktif || _pinKilitliSuAn) return;
    _arkaplanZamani = simdi ?? DateTime.now();
  }

  void planaDonuldu({
    DateTime? simdi,
    Duration zamanAsimi = varsayilanZamanAsimi,
  }) {
    final gidis = _arkaplanZamani;
    _arkaplanZamani = null;
    if (gidis == null || !_pinKorumasiAktif || _pinKilitliSuAn) return;
    if ((simdi ?? DateTime.now()).difference(gidis) >= zamanAsimi) {
      _pinKilitliSuAn = true;
      _zamanAsimiylaKilitlendi = true;
      notifyListeners();
    }
  }

  /// SADECE test: PIN korumasi ACIK + oturum kilitsiz durumunu, gercek
  /// guvenli depoya (flutter_secure_storage) dokunmadan kurar.
  @visibleForTesting
  void debugOturumuKilitsizYap() {
    _pinKorumasiAktif = true;
    _pinKilitliSuAn = false;
  }
}
