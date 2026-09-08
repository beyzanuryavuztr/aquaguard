/// AquaGuard - Su Tuketimi Hesabi
/// ==================================
///
/// Amac:
///   Bir zonun gecmis debi (LPM) okumalarindan, o zon tarafindan tuketilen
///   TOPLAM suyu (litre) hesaplayan saf fonksiyon. Ayri bir sayac
///   TUTULMAZ -- her cagrida gecmisten YENIDEN hesaplanir (bkz.
///   BakimGorevi.durumu(), TedaviBasariAnalizi ile ayni "hesapla, saklama"
///   ilkesi -- bu proje daha once ayri tutulan sayaclarin gercek veriyle
///   driftini yasamis, o yuzden artik hicbir turetilebilir deger ayrica
///   saklanmiyor).
///
/// Yontem:
///   Ardisik iki okuma arasinda gecen sureyi (dakika), ONCEKI (kronolojik
///   olarak daha eski) okumanin debisiyle (LPM) carpip toplar -- tam bir
///   trapez integrali degil, basit bir "sabit debi varsayimi" yaklasimidir.
///   Sensor ornekleme araligi (canli modda saniyeler, gecmis-uretiminde
///   ~90 dakika) debinin bu araliklar icinde COK degismedigi bir olcekte
///   oldugundan, bu yaklasimin hata payi ihmal edilebilir seviyededir.
///
/// Tarih:  2026-09-08
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'sensor_okuma.dart';

/// [gecmisEnYeniOnce]: TEK BIR zonun UygulamaDurumu.gecmis(zone) formatinda
/// (EN YENI ONCE) gecmisi. Birden fazla zonun toplamini almak icin her
/// zonun sonucunu ayri hesaplayip toplayin (TedaviBasariAnalizi.birlestir'in
/// aksine, tek bir double oldugu icin ayri bir "birlestir" sinifi
/// gerekmez -- cagiran taraf basitce '+' ile toplar).
double suTuketimiHesaplaLitre(List<SensorOkuma> gecmisEnYeniOnce) {
  if (gecmisEnYeniOnce.length < 2) return 0.0;

  final kronolojik = gecmisEnYeniOnce.reversed.toList();
  var toplamLitre = 0.0;

  for (var i = 0; i < kronolojik.length - 1; i++) {
    final onceki = kronolojik[i];
    final sonraki = kronolojik[i + 1];
    final gecenDakika =
        sonraki.zaman.difference(onceki.zaman).inSeconds / 60.0;
    if (gecenDakika <= 0) continue;
    toplamLitre += onceki.debi * gecenDakika;
  }

  return toplamLitre;
}
