/// AquaGuard - Sensor Saglik Degerlendirmesi (Istemci Taraflı Anomali Tespiti)
/// ================================================================================
///
/// Amac:
///   Bir sensorun kendisinin ARIZALI/GUVENILMEZ olabilecegini, karar
///   motorunun "tikanma tespit etti" cikarimindan BAGIMSIZ olarak
///   isaretler. Ornegin turbidite ani sekilde imkansiz bir sicrama
///   yaparsa, bu bir tikanma DEGIL, muhtemelen sensorun kendisiyle
///   ilgili bir sorundur (baglanti gevsemesi, kirlenme, elektronik ariza).
///
///   Bu, firmware DEGISIKLIGI GEREKTIRMEZ -- MQTT'den gelen ham veri
///   uzerinde, istemci (Flutter) tarafinda saf bir hesaplama olarak
///   calisir. Esikler, config/sensor_imzalari.dart'taki 'normal' sinifin
///   MEVCUT std degerlerinden turetilir -- yeni bir sayi icat edilmez.
///
/// Tarih:  2026-09-16
library;

enum SensorSaglikDurumu { normal, aniSicrama, sabitDeger }

/// [sonDegerlerEnYeniOnce]: bir sensorun son okumalari, EN YENI ONCE sirali
/// (bkz. UygulamaDurumu.gecmis(zone) -- ayni sirayla doner).
/// [normalStd]: sensorImzalari['normal'][anahtar].std -- bu sensorun
/// saglikli calisirken beklenen olagan dalgalanmasi.
SensorSaglikDurumu sensorSagligiDegerlendir({
  required List<double> sonDegerlerEnYeniOnce,
  required double normalStd,
}) {
  // Yetersiz veri: henuz bir karar vermek icin en az 4 okuma gerekir
  // (sabit-deger kontrolu icin) -- erken donuslerde YANLIS POZITIF
  // uretmemek icin varsayilan olarak 'normal' donulur.
  if (sonDegerlerEnYeniOnce.length < 4) return SensorSaglikDurumu.normal;

  final guncel = sonDegerlerEnYeniOnce[0];
  final onceki = sonDegerlerEnYeniOnce[1];
  // Ardisik iki okuma arasindaki fark, sensorun normal std sapmasinin
  // 5 katini asarsa "ani sicrama" -- istatistiksel olarak neredeyse
  // imkansiz bir tek-adim degisim (normal dagilimda >5 sigma).
  if (normalStd > 0 && (guncel - onceki).abs() > normalStd * 5) {
    return SensorSaglikDurumu.aniSicrama;
  }

  // Son 4 okuma BIREBIR ayniysa (sensor "takilmis" olabilir -- gercek
  // sensorler, saglikliyken bile olcum gurultusu nedeniyle asla tam
  // ayni degeri art arda 4 kez vermez).
  if (sonDegerlerEnYeniOnce.take(4).toSet().length == 1) {
    return SensorSaglikDurumu.sabitDeger;
  }

  return SensorSaglikDurumu.normal;
}

String sensorSagligiEtiketi(SensorSaglikDurumu durum) {
  switch (durum) {
    case SensorSaglikDurumu.normal:
      return 'Normal';
    case SensorSaglikDurumu.aniSicrama:
      return 'Ani sıçrama tespit edildi — sensörü kontrol edin';
    case SensorSaglikDurumu.sabitDeger:
      return 'Sensör sabit değer veriyor — bağlantıyı kontrol edin';
  }
}
