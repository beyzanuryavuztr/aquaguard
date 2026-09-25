/*
 * AquaGuard - Sensor Okuma Katmani
 * ==================================
 *
 * Amac:
 *   6 sensorun (pH, EC, ORP, turbidite, debi, diferansiyel basinc) ham
 *   analog/darbe verisini okuyup, kalibrasyon formulleriyle fiziksel
 *   birimlere cevirir, aykiri deger (outlier) filtresi uygular ve fiziksel
 *   olarak mumkun araliga sinirlar (normalizasyon).
 *
 * Aykiri deger filtresi:
 *   Analog sensorler (ozellikle pH/ORP probu) elektriksel gurultuye
 *   duyarlidir. Her okuma icin ardisik 5 hizli ornek alinir ve bunlarin
 *   MEDYANI kullanilir -- ortalama yerine medyan secilmesinin nedeni,
 *   medyanin tek bir ani sicramadan (spike) etkilenmemesidir.
 *
 * Debi olcumu:
 *   Debi sensoru darbe (pulse) ciktisi verir; bir kesme (interrupt) rutini
 *   her darbede sayaci arttirir. Iki okuma arasindaki gecen sure ve darbe
 *   sayisi kullanilarak LPM (litre/dakika) hesaplanir.
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_SENSORS_H
#define AQUAGUARD_SENSORS_H

#include <Arduino.h>
#include "config.h"

// ============================================================================
// VERI YAPISI
// ============================================================================

struct SensorOkumalari {
  float ph;
  float ec;
  float orp;
  float turbidite;
  float debi;
  float deltaBasinc;
  // YENI (2026-09-25, Enver'in notu -- A0 "sicaklik"): HAM VOLTAJ, santigrat
  // DEGIL -- sensor modeli/referans noktalari bilinmedigi icin bir donusum
  // formulu UYDURULMADI. pH/EC telafisine KATILMIYOR -- sadece dogrudan
  // yayinlaniyor (bkz. mqtt_handler.h "sicaklik_ham_voltaj", nullable).
  // Sensorun gercekten kullanilip kullanilmayacagi (yoksa bos pin mi)
  // Enver'e SORULDU.
  float sicaklikHamVoltaj;
  unsigned long zamanDamgasi;   // millis() -- bu okumanin alindigi an
};

// ============================================================================
// DEBI SENSORU ICIN KESME (INTERRUPT) DEGISKENLERI
// ============================================================================

static volatile unsigned long _debiPalsSayaci = 0;
static unsigned long _debiSonHesapZamaniMs = 0;

// ISR: her darbede yalnizca sayaci arttirir, baska islem yapmaz (kisa tutulmali)
static void IRAM_ATTR _debiPalsKesmesi() {
  _debiPalsSayaci = _debiPalsSayaci + 1;  // "++" volatile uyarisi (C++20) icin acik yazim
}

// ============================================================================
// YARDIMCI FONKSIYONLAR
// ============================================================================

static float _degereSinirlaFloat(float deger, float alt, float ust) {
  if (deger < alt) return alt;
  if (deger > ust) return ust;
  return deger;
}

// 5 ornegin medyanini dondurur (basit ekleme siralamasi -- kucuk dizi icin yeterli)
static float _medyanBul(float ornekler[], int adet) {
  for (int i = 1; i < adet; i++) {
    float anahtar = ornekler[i];
    int j = i - 1;
    while (j >= 0 && ornekler[j] > anahtar) {
      ornekler[j + 1] = ornekler[j];
      j--;
    }
    ornekler[j + 1] = anahtar;
  }
  return ornekler[adet / 2];
}

// DERLEME ZAMANI GUVENLIK KONTROLU (Y1): sensorun en yuksek cikis voltaji,
// bolucu orani uygulandiktan SONRA ADC referansini (3.3 V) asiyorsa derleme
// DURUR -- aksi halde kartin ADC girisi zarar gorurdu. Bkz. config.h
// "GERILIM BOLUCU ORANLARI".
static_assert(PH_MAKS_CIKIS_V * PH_BOLUCU_ORANI <= ADC_REFERANS_VOLTAJ,
              "pH sensoru cikisi ADC referansini asiyor: PH_BOLUCU_ORANI kucultulmeli");
static_assert(EC_MAKS_CIKIS_V * EC_BOLUCU_ORANI <= ADC_REFERANS_VOLTAJ,
              "EC sensoru cikisi ADC referansini asiyor: EC_BOLUCU_ORANI kucultulmeli");
static_assert(ORP_MAKS_CIKIS_V * ORP_BOLUCU_ORANI <= ADC_REFERANS_VOLTAJ,
              "ORP sensoru cikisi ADC referansini asiyor: ORP_BOLUCU_ORANI kucultulmeli");
static_assert(TURBIDITE_MAKS_CIKIS_V * TURBIDITE_BOLUCU_ORANI <= ADC_REFERANS_VOLTAJ,
              "Turbidite modulu cikisi ADC referansini asiyor: TURBIDITE_BOLUCU_ORANI kucultulmeli");
static_assert(BASINC_MAKS_CIKIS_V * BASINC_BOLUCU_ORANI <= ADC_REFERANS_VOLTAJ,
              "Basinc sensoru cikisi ADC referansini asiyor: BASINC_BOLUCU_ORANI kucultulmeli");

// Bir analog pinden 5 hizli ornek alip medyan voltaji dondurur.
// [bolucuOrani]: sensor ile ADC pini arasindaki gerilim bolucunun orani
// (V_pin / V_sensor); donen deger SENSOR TARAFI voltajdir (bolucu geri alinir).
static float _medyanVoltajOku(int pin, float bolucuOrani = 1.0f) {
  const int ORNEK_SAYISI = 5;
  float ornekler[ORNEK_SAYISI];
  for (int i = 0; i < ORNEK_SAYISI; i++) {
    int ham = analogRead(pin);
    ornekler[i] = ((ham / ADC_COZUNURLUK) * ADC_REFERANS_VOLTAJ) / bolucuOrani;
    delayMicroseconds(200);   // ardisik ornekler arasi kisa bekleme
  }
  return _medyanBul(ornekler, ORNEK_SAYISI);
}

// ============================================================================
// SENSOR BAZLI OKUMA + KALIBRASYON FONKSIYONLARI
// ============================================================================

float phOku() {
  float voltaj = _medyanVoltajOku(PIN_PH_SENSOR, PH_BOLUCU_ORANI);
  float ph = PH_KALIBRASYON_OFSET + (voltaj - PH_KALIBRASYON_NOTR_V) * PH_KALIBRASYON_EGIM;
  return _degereSinirlaFloat(ph, PH_MIN, PH_MAKS);
}

float ecOku() {
  float voltaj = _medyanVoltajOku(PIN_EC_SENSOR, EC_BOLUCU_ORANI);
  float ec = EC_KALIBRASYON_OFSET + voltaj * EC_KALIBRASYON_EGIM;
  return _degereSinirlaFloat(ec, EC_MIN, EC_MAKS);
}

// GECICI (2026-09-25): Deneyap Kart 1A v2'de ORP icin FIZIKSEL OLARAK bos
// analog pin kalmadi (bkz. config.h #warning) -- gercek bir pinden OKUMA
// YAPILMIYOR, sahte/uydurma bir okuma yerine sabit bir NOTR deger donuluyor
// (uc imzanin -- kimyasal/biyolojik/fiziksel -- ORP ortalamalarinin kabaca
// ortasi, decision_engine.h'nin ORP'yi ayirt edici olarak KULLANMAMASI ama
// COKMEMESI icin). Enver bir pin/genisletici onaylayinca gercek okumaya
// donusturulmeli.
float orpOku() {
  return (IMZA_KIMYASAL_ORP_ORT + IMZA_BIYOLOJIK_ORP_ORT + IMZA_FIZIKSEL_ORP_ORT) / 3.0f;
}

float turbiditeOku() {
  float voltaj = _medyanVoltajOku(PIN_TURBIDITE_SENSOR, TURBIDITE_BOLUCU_ORANI);
  // Voltaj dustukce bulaniklik artar (temiz suda voltaj en yuksek)
  float ntu = (TURBIDITE_KALIBRASYON_TEMIZ_V - voltaj) * TURBIDITE_KALIBRASYON_EGIM;
  return _degereSinirlaFloat(ntu, TURBIDITE_MIN, TURBIDITE_MAKS);
}

float basincOku() {
  float voltaj = _medyanVoltajOku(PIN_BASINC_SENSOR, BASINC_BOLUCU_ORANI);
  float oran = (voltaj - BASINC_MIN_VOLTAJ) / (BASINC_MAKS_VOLTAJ - BASINC_MIN_VOLTAJ);
  float bar = oran * BASINC_MAKS_BAR;
  return _degereSinirlaFloat(bar, DELTA_BASINC_MIN, DELTA_BASINC_MAKS);
}

// GECICI/KALIBRE EDILMEDI (2026-09-25): sensor modeli ve referans noktalari
// bilinmiyor -- ham voltaji dogrudan "santigrat" gibi SUNMUYORUZ (bu
// UYDURMA olurdu). Bunun yerine ham voltaji dondururuz; mqtt_handler.h bunu
// acikca "sicaklik_c (HAM, kalibre edilmedi)" olarak yayinlar. Enver sensor
// tipini/kalibrasyonunu netlestirince gercek bir donusum formulu eklenmeli.
float sicaklikOkuHamVoltaj() {
  return _medyanVoltajOku(PIN_SICAKLIK_SENSOR, 1.0f);
}

float debiHesapla() {
  unsigned long simdi = millis();
  unsigned long gecenSureMs = simdi - _debiSonHesapZamaniMs;

  if (gecenSureMs == 0) {
    return DEBI_MIN;   // ilk cagrida bolme hatasini engelle
  }

  // Kesme sirasinda sayaci guvenli sekilde oku ve sifirla
  noInterrupts();
  unsigned long palsSayisi = _debiPalsSayaci;
  _debiPalsSayaci = 0;
  interrupts();

  _debiSonHesapZamaniMs = simdi;

  float litre = palsSayisi / DEBI_PALS_PER_LITRE;
  float dakika = gecenSureMs / 60000.0f;
  float lpm = (dakika > 0) ? (litre / dakika) : DEBI_MIN;

  return _degereSinirlaFloat(lpm, DEBI_MIN, DEBI_MAKS);
}

// ============================================================================
// KURULUM VE TOPLU OKUMA
// ============================================================================

void sensorleriBaslat() {
  pinMode(PIN_PH_SENSOR, INPUT);
  pinMode(PIN_EC_SENSOR, INPUT);
  // PIN_ORP_SENSOR YOK (bkz. orpOku() dosya ici notu) -- pinMode cagrilmaz.
  pinMode(PIN_TURBIDITE_SENSOR, INPUT);
  pinMode(PIN_SICAKLIK_SENSOR, INPUT);
  pinMode(PIN_BASINC_SENSOR, INPUT);

  pinMode(PIN_DEBI_SENSOR, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_DEBI_SENSOR), _debiPalsKesmesi, RISING);

  _debiSonHesapZamaniMs = millis();
}

SensorOkumalari tumSensorleriOku() {
  SensorOkumalari okuma;
  okuma.ph = phOku();
  okuma.ec = ecOku();
  okuma.orp = orpOku();
  okuma.turbidite = turbiditeOku();
  okuma.debi = debiHesapla();
  okuma.deltaBasinc = basincOku();
  okuma.sicaklikHamVoltaj = sicaklikOkuHamVoltaj();
  okuma.zamanDamgasi = millis();
  return okuma;
}

#endif // AQUAGUARD_SENSORS_H
