/*
 * AquaGuard - SD Kart + RTC Loglama Katmani
 * =============================================
 *
 * Amac:
 *   Tum sensor okumalarini ve tedavi olaylarini, RTC modulunden alinan
 *   gercek zaman damgasiyla birlikte SD karta CSV formatinda kaydeder.
 *   GSM baglantisi kesilse bile (SIM800L sinyal kaybi vb.) saha verisi
 *   kaybolmaz; baglanti geri geldiginde gecmis kayitlar incelenebilir.
 *
 * Iki ayri log dosyasi tutulur:
 *   /sensor_log.csv   -> her sensor okuma dongusunde bir satir
 *   /tedavi_log.csv   -> her tedavi baslangic/bitisinde bir satir
 *
 * Kolon adlari, python/aquaguard_dataset.csv ile TUTARLI tutulmustur
 * (ph, ec, orp, turbidite, debi, delta_basinc) -- boylece saha loglari,
 * gerekirse Python tarafinda da dogrudan okunup analiz edilebilir.
 *
 * Kutuphaneler: RTClib (Adafruit) + SD (Arduino core)
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_LOGGER_H
#define AQUAGUARD_LOGGER_H

#include <Arduino.h>
#include <SPI.h>
#include <SD.h>
#include <Wire.h>
#include <RTClib.h>
#include "config.h"
#include "sensors.h"
#include "decision_engine.h"
#include "treatment.h"

// ============================================================================
// DOSYA ADLARI
// ============================================================================

#define SENSOR_LOG_DOSYASI  "/sensor_log.csv"
#define TEDAVI_LOG_DOSYASI  "/tedavi_log.csv"

static RTC_DS3231 _rtc;
static bool _rtcHazir = false;
static bool _sdHazir = false;

// ============================================================================
// YARDIMCI: ZAMAN DAMGASINI "YYYY-MM-DD HH:MM:SS" BICIMINE CEVIR
// ============================================================================

static void _zamanDamgasiOlustur(char* arabellek, size_t arabellekBoyutu) {
  if (!_rtcHazir) {
    snprintf(arabellek, arabellekBoyutu, "RTC_YOK,ms=%lu", millis());
    return;
  }
  DateTime simdi = _rtc.now();
  snprintf(arabellek, arabellekBoyutu, "%04d-%02d-%02d %02d:%02d:%02d",
           simdi.year(), simdi.month(), simdi.day(),
           simdi.hour(), simdi.minute(), simdi.second());
}

// Disariya acik zaman damgasi fonksiyonu (mqtt_handler.h / aquaguard_main.ino icin)
void zamanDamgasiAl(char* arabellek, size_t arabellekBoyutu) {
  _zamanDamgasiOlustur(arabellek, arabellekBoyutu);
}

// ============================================================================
// KURULUM
// ============================================================================

void loggerBaslat() {
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);

  _rtcHazir = _rtc.begin();
  if (!_rtcHazir) {
    Serial.println(F("[LOGGER] UYARI: RTC modulu bulunamadi, zaman damgasi millis() ile tutulacak."));
  } else if (_rtc.lostPower()) {
    Serial.println(F("[LOGGER] UYARI: RTC gucu kesilmisti, saat derleme zamanina ayarlaniyor."));
    _rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

  _sdHazir = SD.begin(PIN_SD_CS);
  if (!_sdHazir) {
    Serial.println(F("[LOGGER] HATA: SD kart baslatilamadi! Loglama devre disi."));
    return;
  }

  // Dosyalar yoksa basliklariyla birlikte olustur
  if (!SD.exists(SENSOR_LOG_DOSYASI)) {
    File f = SD.open(SENSOR_LOG_DOSYASI, FILE_WRITE);
    if (f) {
      f.println(F("zaman,ph,ec,orp,turbidite,debi,delta_basinc,durum,tur,guven"));
      f.close();
    }
  }

  if (!SD.exists(TEDAVI_LOG_DOSYASI)) {
    File f = SD.open(TEDAVI_LOG_DOSYASI, FILE_WRITE);
    if (f) {
      f.println(F("zaman,tedavi_turu,sure_ms,tetikleyen_tur,tetikleyen_guven"));
      f.close();
    }
  }
}

// ============================================================================
// SENSOR + TESHIS SATIRI KAYDET
// ============================================================================

void sensorVerisiLogla(const SensorOkumalari& okuma, const TeshisSonucu& teshis) {
  if (!_sdHazir) return;

  char zaman[32];
  _zamanDamgasiOlustur(zaman, sizeof(zaman));

  File f = SD.open(SENSOR_LOG_DOSYASI, FILE_WRITE);
  if (!f) {
    Serial.println(F("[LOGGER] HATA: sensor_log.csv acilamadi."));
    return;
  }

  f.print(zaman); f.print(',');
  f.print(okuma.ph, 2); f.print(',');
  f.print(okuma.ec, 2); f.print(',');
  f.print(okuma.orp, 0); f.print(',');
  f.print(okuma.turbidite, 1); f.print(',');
  f.print(okuma.debi, 2); f.print(',');
  f.print(okuma.deltaBasinc, 3); f.print(',');
  f.print(durumAdiGetir(teshis.durum)); f.print(',');
  f.print(turAdiGetir(teshis.tur)); f.print(',');
  f.println(teshis.guven, 1);

  f.close();
}

// ============================================================================
// TEDAVI OLAYI KAYDET
// ============================================================================

void tedaviLogla(TedaviTuru tedavi, unsigned long sureMs, TikanmaTuru tetikleyenTur, float tetikleyenGuven) {
  if (!_sdHazir) return;

  char zaman[32];
  _zamanDamgasiOlustur(zaman, sizeof(zaman));

  File f = SD.open(TEDAVI_LOG_DOSYASI, FILE_WRITE);
  if (!f) {
    Serial.println(F("[LOGGER] HATA: tedavi_log.csv acilamadi."));
    return;
  }

  f.print(zaman); f.print(',');
  f.print(tedaviAdiGetir(tedavi)); f.print(',');
  f.print(sureMs); f.print(',');
  f.print(turAdiGetir(tetikleyenTur)); f.print(',');
  f.println(tetikleyenGuven, 1);

  f.close();
}

#endif // AQUAGUARD_LOGGER_H
