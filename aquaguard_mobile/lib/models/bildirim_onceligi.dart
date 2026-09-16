/// AquaGuard - Bildirim Onceligi (Sema v2)
/// =============================================
///
/// Amac:
///   Onceden HER bildirim ayni onemde gosteriliyordu (BildirimServisi.goster()
///   sabit `Importance.high` kullaniyordu). Sahada bir ciftci icin "kimyasal
///   tıkanma tespit edildi" ile "pil düşük" AYNI aciliyette DEGILDIR -- bu
///   enum, `AktiviteTuru`'yu 4 seviyeye esler, boylece bildirim kanali
///   (Android Importance/Priority) ve sessiz-saat davranisi (bkz.
///   models/bildirim_tercihleri.dart) buna gore ayarlanabilir.
///
///   `kritik` seviyesi SESSIZ SAATTE BILE gosterilir (guvenlik onceligi) --
///   bkz. providers/uygulama_durumu.dart sessiz-saat kontrolu.
///
/// Tarih:  2026-09-16
library;

import 'aktivite_kaydi.dart';
import 'bildirim_tercihleri.dart';

enum Oncelik { kritik, yuksek, orta, dusuk }

extension OncelikX on Oncelik {
  String get etiket => switch (this) {
    Oncelik.kritik => 'Kritik',
    Oncelik.yuksek => 'Yüksek',
    Oncelik.orta => 'Orta',
    Oncelik.dusuk => 'Düşük',
  };
}

Oncelik oncelikGetir(AktiviteTuru tur) => switch (tur) {
  AktiviteTuru.tespit => Oncelik.kritik,
  AktiviteTuru.belirsiz => Oncelik.yuksek,
  AktiviteTuru.tedaviBaslangic => Oncelik.yuksek,
  AktiviteTuru.tedaviBitis => Oncelik.orta,
  AktiviteTuru.normaleDonus => Oncelik.orta,
  AktiviteTuru.manuelMudahale => Oncelik.orta,
  AktiviteTuru.dusukPil => Oncelik.dusuk,
};

/// Bu bildirimin (OS-seviyesi push, SnackBar DEGIL) sessiz saat nedeniyle
/// BASTIRILMASI gerekip gerekmedigini doner. `kritik` oncelik HER ZAMAN
/// gosterilir (guvenlik onceligi -- bir tıkanma tespitini gece bile
/// kacirmak istenmez). Baslangic > bitis olabilir (gece yarisini gecen
/// bir aralik, orn. 22:00-07:00) -- bu durumda "araligin DISI" degil
/// "gun-ici iki parcaya bolunmus ic" mantigiyla ele alinir.
bool sessizSaattaBastirilmaliMi(
  BildirimTercihleri tercihler,
  Oncelik oncelik, [
  DateTime? simdi,
]) {
  if (oncelik == Oncelik.kritik) return false;
  if (!tercihler.sessizSaatAktif) return false;

  final su = simdi ?? DateTime.now();
  final dakika = su.hour * 60 + su.minute;
  final baslangic = tercihler.sessizBaslangicDakika!;
  final bitis = tercihler.sessizBitisDakika!;

  if (baslangic <= bitis) {
    return dakika >= baslangic && dakika < bitis;
  }
  return dakika >= baslangic || dakika < bitis;
}
