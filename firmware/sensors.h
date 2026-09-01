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
  unsigned long zamanDamgasi;   // millis() -- bu okumanin alindigi an
};

// ============================================================================
// DEBI SENSORU ICIN KESME (INTERRUPT) DEGISKENLERI
// ============================================================================

static volatile unsigned long _debiPalsSayaci = 0;
static unsigned long _debiSonHesapZamaniMs = 0;

// ISR: her darbede yalnizca sayaci arttirir, baska islem yapmaz (kisa tutulmali)
static void IRAM_ATTR _debiPalsKesmesi() {
  _debiPalsSayaci++;
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

// Bir analog pinden 5 hizli ornek alip medyan voltaji dondurur
static float _medyanVoltajOku(int pin) {
  const int ORNEK_SAYISI = 5;
  float ornekler[ORNEK_SAYISI];
  for (int i = 0; i < ORNEK_SAYISI; i++) {
    int ham = analogRead(pin);
    ornekler[i] = (ham / ADC_COZUNURLUK) * ADC_REFERANS_VOLTAJ;
    delayMicroseconds(200);   // ardisik ornekler arasi kisa bekleme
  }
  return _medyanBul(ornekler, ORNEK_SAYISI);
}

// ============================================================================
// SENSOR BAZLI OKUMA + KALIBRASYON FONKSIYONLARI
// ============================================================================

float phOku() {
  float voltaj = _medyanVoltajOku(PIN_PH_SENSOR);
  float ph = PH_KALIBRASYON_OFSET + (voltaj - PH_KALIBRASYON_NOTR_V) * PH_KALIBRASYON_EGIM;
  return _degereSinirlaFloat(ph, PH_MIN, PH_MAKS);
}

float ecOku() {
  float voltaj = _medyanVoltajOku(PIN_EC_SENSOR);
  float ec = EC_KALIBRASYON_OFSET + voltaj * EC_KALIBRASYON_EGIM;
  return _degereSinirlaFloat(ec, EC_MIN, EC_MAKS);
}

float orpOku() {
  float voltaj = _medyanVoltajOku(PIN_ORP_SENSOR);
  float orp = (voltaj - ORP_KALIBRASYON_OFSET_V) * ORP_KALIBRASYON_KAZANC;
  return _degereSinirlaFloat(orp, ORP_MIN, ORP_MAKS);
}

float turbiditeOku() {
  float voltaj = _medyanVoltajOku(PIN_TURBIDITE_SENSOR);
  // Voltaj dustukce bulaniklik artar (temiz suda voltaj en yuksek)
  float ntu = (TURBIDITE_KALIBRASYON_TEMIZ_V - voltaj) * TURBIDITE_KALIBRASYON_EGIM;
  return _degereSinirlaFloat(ntu, TURBIDITE_MIN, TURBIDITE_MAKS);
}

float basincOku() {
  float voltaj = _medyanVoltajOku(PIN_BASINC_SENSOR);
  float oran = (voltaj - BASINC_MIN_VOLTAJ) / (BASINC_MAKS_VOLTAJ - BASINC_MIN_VOLTAJ);
  float bar = oran * BASINC_MAKS_BAR;
  return _degereSinirlaFloat(bar, DELTA_BASINC_MIN, DELTA_BASINC_MAKS);
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
  pinMode(PIN_ORP_SENSOR, INPUT);
  pinMode(PIN_TURBIDITE_SENSOR, INPUT);
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
  okuma.zamanDamgasi = millis();
  return okuma;
}

#endif // AQUAGUARD_SENSORS_H
