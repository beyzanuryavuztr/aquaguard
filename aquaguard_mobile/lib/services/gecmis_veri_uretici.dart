/// AquaGuard - Gecmise Donuk Veri Ureticisi
/// =============================================
///
/// Amac:
///   Uygulama ilk kez acildiginda (bir zon icin hic gecmis yoksa), sanki
///   sistem GUNLERDIR sahada calisiyormus gibi gorunmesi icin GECMISE DONUK
///   zaman damgali sentetik bir sensor gecmisi uretir. Boylece jüri/kullanici
///   uygulamayi actiginda Istatistikler, Aktivite Gecmisi ve sensor trend
///   grafikleri bombos degil, dolu ve anlamli gorunur -- canli demonun
///   dakikalar icinde birikmesini beklemeye gerek kalmaz.
///
///   AYNI senaryo motoru (`senaryoAdimlariUret`) ve AYNI karar motoru
///   (`KararMotoru`) kullanilir -- yani gecmis veri, canli demo verisiyle
///   BIREBIR AYNI kurallara gore uretilir, ayri/tutarsiz bir "sahte veri"
///   kaynagi degildir.
///
///   Zon numarasindan turetilen SABIT bir seed kullanilir (`zone * 7919 +
///   42`) -- boylece ayni zon icin uretim HER ZAMAN ayni sonucu verir
///   (tekrarlanabilirlik, brief'in Python veri ureticisindeki seed=42
///   ilkesiyle tutarli).
///
/// Tarih:  2026-09-02
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:math' as math;

import '../models/aktivite_kaydi.dart';
import '../models/sensor_okuma.dart';
import 'simulasyon_servisi.dart';

class GecmisVeriUreticisi {
  GecmisVeriUreticisi._();

  /// Kac gunluk gecmis uretilecek.
  static const int gunSayisi = 12;

  /// Iki okuma arasindaki simule edilen zaman araligi.
  static const Duration okumaAraligi = Duration(minutes: 90);

  /// Bir zon icin, GECMISTEN SIMDIYE dogru sirali (eskiden yeniye) sentetik
  /// sensor gecmisi uretir.
  static List<SensorOkuma> zonGecmisiUret(int zone, {DateTime? simdi}) {
    final rng = math.Random(zone * 7919 + 42);
    final adimSayisi = (gunSayisi * 24 * 60) ~/ okumaAraligi.inMinutes;
    final referansZaman = simdi ?? DateTime.now();

    final uretec = senaryoAdimlariUret(rng).iterator;
    final sonuc = <SensorOkuma>[];

    for (var i = adimSayisi; i >= 1; i--) {
      uretec.moveNext();
      final zaman = referansZaman.subtract(okumaAraligi * i);
      sonuc.add(simAdimindanOkumaUret(uretec.current, zone, zaman));
    }

    return sonuc;
  }

  /// Kronolojik (eskiden yeniye) bir gecmisten, ardisik okumalar arasindaki
  /// TUM durum/tedavi gecislerinden aktivite kayitlarini turetir.
  static List<AktiviteKaydi> aktiviteleriTuret(
    List<SensorOkuma> kronolojikGecmis,
  ) {
    final sonuc = <AktiviteKaydi>[];
    for (var i = 1; i < kronolojikGecmis.length; i++) {
      sonuc.addAll(
        gecisAktiviteleriniUret(kronolojikGecmis[i - 1], kronolojikGecmis[i]),
      );
    }
    return sonuc;
  }
}
