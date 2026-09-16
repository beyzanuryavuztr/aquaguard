/// AquaGuard - Trend Tahmini (Basit Lineer Regresyon)
/// =========================================================
///
/// Amac:
///   Bir sensorun SON N gunundeki egilimini (en kucuk kareler/least-squares
///   lineer regresyon, `dart:math` disinda YENI bir paket GEREKTIRMEZ) hesaplayip
///   birkac gun ileriye projekte eder.
///
///   DURUSTLUK UYARISI (proje geneli ilke -- bkz. tikanma_detay_ekrani.dart
///   _KararKatmaniEtiketi, model_performansi_ekrani.dart benzer notlari):
///   bu bir ISTATISTIKSEL EGILIM hesaplamasidir, "yapay zeka tahmini" veya
///   "makine ogrenmesi ongorusu" DEGILDIR. Karar motorunun Katman 2'si
///   (Random Forest) nasil offline-only/asla-canli-teshiste-kullanilmaz
///   ise, bu da benzer bir netlikte sunulmalidir -- UI'da HER ZAMAN
///   "istatistiksel eğilim (tahmin değildir)" ibaresiyle birlikte gosterilir.
///
/// Tarih:  2026-09-16
library;

import 'sensor_okuma.dart';

class TrendTahmini {
  final double egim; // birim/gun
  final double kesisim;
  final DateTime baslangicZamani;

  const TrendTahmini({
    required this.egim,
    required this.kesisim,
    required this.baslangicZamani,
  });

  /// [gunSonra] gun sonrasi icin projekte edilen deger.
  double degerTahminEt(double gunSonra) => kesisim + egim * gunSonra;
}

/// [kronolojikOkumalar]: TEK bir zonun ESKIDEN YENIYE sirali gecmisi.
/// [degerSecici]: hangi sensorun (orn. debi, turbidite) trendi hesaplanacak.
/// En az 3 nokta gerektirir (2 nokta HER ZAMAN "mukemmel" bir dogru verir,
/// bu yaniltici bir guven hissi yaratirdi) -- yetersiz veri varsa null doner.
TrendTahmini? trendHesapla(
  List<SensorOkuma> kronolojikOkumalar,
  double Function(SensorOkuma) degerSecici,
) {
  if (kronolojikOkumalar.length < 3) return null;

  final baslangic = kronolojikOkumalar.first.zaman;
  final noktalar = kronolojikOkumalar
      .map(
        (o) => (
          x: o.zaman.difference(baslangic).inHours / 24.0, // gun cinsinden
          y: degerSecici(o),
        ),
      )
      .toList();

  final n = noktalar.length;
  final xOrtalama = noktalar.map((p) => p.x).reduce((a, b) => a + b) / n;
  final yOrtalama = noktalar.map((p) => p.y).reduce((a, b) => a + b) / n;

  var pay = 0.0;
  var payda = 0.0;
  for (final nokta in noktalar) {
    final xFark = nokta.x - xOrtalama;
    pay += xFark * (nokta.y - yOrtalama);
    payda += xFark * xFark;
  }

  // Tum noktalar AYNI zaman damgasindaysa (payda=0) egim tanimsizdir --
  // bolme hatasi yerine "egilim yok" (egim=0) donulur.
  final egim = payda == 0 ? 0.0 : pay / payda;
  final kesisim = yOrtalama - egim * xOrtalama;

  return TrendTahmini(egim: egim, kesisim: kesisim, baslangicZamani: baslangic);
}
