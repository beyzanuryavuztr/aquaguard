/// AquaGuard - Hava Durumu + Bitki Turune Gore Basit Sulama Onerisi (Faz 4)
/// ==============================================================================
///
/// Amac:
///   Kullanicinin acikca istedigi "bitki ve hava durumuna gore sulama
///   onerisi" ozelligi. DURUSTLUK NOTU (models/trend_tahmini.dart'taki
///   "istatistiksel egilim, tahmin degildir" ilkesiyle AYNI disiplin):
///   bu, GERCEK bir agronomik model (evapotranspirasyon/Penman-Monteith,
///   toprak nem sensoru, bitki gelisim evresi vb.) DEGILDIR -- sadece
///   yarinki yagis ihtimali + sicaklik + kabaca bitki turune gore BASIT,
///   KURAL TABANLI bir yon verir. UI'da "basit oneri, profesyonel tarim
///   danismanligi yerine gecmez" notu ile birlikte gosterilir.
///
///   Bu ozellik daha once "guvenilmez/anahtarli harici API'den kacin"
///   ilkesi geregince ertelenmisti. Open-Meteo (API anahtari GEREKTIRMEYEN,
///   ucretsiz, kucuk olcekli kullanim icin acikca tasarlanmis bir servis)
///   bu varsayimi degistirdigi icin yeniden degerlendirildi.
///
/// Tarih:  2026-09-25
library;

import 'bitki_turu.dart';
import 'hava_tahmini.dart';

enum SulamaOneriSeviyesi { erteleyebilirsiniz, normal, artirabilirsiniz }

class SulamaOnerisi {
  final SulamaOneriSeviyesi seviye;
  final String mesaj;

  const SulamaOnerisi({required this.seviye, required this.mesaj});
}

/// Saf fonksiyon -- ag/GPS/UI'dan tamamen bagimsiz, dogrudan test edilebilir.
/// [yarininTahmini] null ise (veri henuz gelmemis/hata) cagiran taraf bu
/// fonksiyonu HIC CAGIRMAMALI -- UI seviyesinde "hava durumu alinamadi"
/// gosterilir, sahte bir oneri UYDURULMAZ.
SulamaOnerisi sulamaOnerisiUret({
  required GunlukHavaTahmini yarininTahmini,
  required BitkiTuru bitkiTuru,
}) {
  final suIhtiyaci = bitkiSuIhtiyaciEgilimi(bitkiTuru);
  final yagisYuksek = yarininTahmini.yagisIhtimaliYuzde >= 60;
  final yagisOrta =
      yarininTahmini.yagisIhtimaliYuzde >= 30 &&
      yarininTahmini.yagisIhtimaliYuzde < 60;
  final sicakGun = yarininTahmini.maksSicaklikC >= 32;

  if (yagisYuksek) {
    return SulamaOnerisi(
      seviye: SulamaOneriSeviyesi.erteleyebilirsiniz,
      mesaj:
          'Yarın yağış ihtimali yüksek (%${yarininTahmini.yagisIhtimaliYuzde}). '
          'Planlı sulamayı erteleyip toprağın doğal nemine bırakmayı '
          'değerlendirebilirsiniz.',
    );
  }

  if (sicakGun && suIhtiyaci == SuIhtiyaciEgilimi.yuksek && !yagisOrta) {
    return SulamaOnerisi(
      seviye: SulamaOneriSeviyesi.artirabilirsiniz,
      mesaj:
          'Yarın sıcaklık yüksek (${yarininTahmini.maksSicaklikC.toStringAsFixed(0)}°C) '
          've bitki türünüzün su ihtiyacı yüksek. Yağış beklenmiyor -- '
          'normalden biraz daha fazla sulama düşünülebilir.',
    );
  }

  if (sicakGun && !yagisOrta) {
    return SulamaOnerisi(
      seviye: SulamaOneriSeviyesi.normal,
      mesaj:
          'Yarın sıcak (${yarininTahmini.maksSicaklikC.toStringAsFixed(0)}°C) ve '
          'yağış beklenmiyor. Planladığınız sulamaya normal şekilde devam '
          'edebilirsiniz.',
    );
  }

  return const SulamaOnerisi(
    seviye: SulamaOneriSeviyesi.normal,
    mesaj:
        'Yarın için hava koşulları olağan görünüyor. Planladığınız sulamaya '
        'normal şekilde devam edebilirsiniz.',
  );
}
