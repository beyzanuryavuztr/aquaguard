/*
 * AquaGuard - Ana Firmware (Deneyap Kart)
 * ==========================================
 *
 * Amac:
 *   Tum modulleri (sensors, decision_engine, treatment, logger, mqtt_handler)
 *   bir araya getiren ana dongu. Akis:
 *
 *     sensor oku -> karar ver (Katman 1) -> gerekiyorsa tedavi uygula
 *     -> SD karta logla -> MQTT ile yayinla
 *
 *   TASARIM ILKESI: Hicbir yerde delay() kullanilmaz. Tum zamanlama
 *   millis() tabanli non-blocking sayaclarla yapilir; boylece sensor
 *   okuma, tedavi durum makinesi ve MQTT baglantisi birbirini bloke etmeden
 *   ayni anda ilerleyebilir.
 *
 * ONEMLI - DERLEME / SAHA NOTU:
 *   Bu dosya, bu gelistirme ortaminda (Arduino/Deneyap Kart derleyicisi
 *   kurulu olmadigi icin) DERLENIP TEST EDILEMEMISTIR. Kod, Arduino/ESP32
 *   C++ standartlarina ve kullanilan kutuphanelerin (TinyGSM, PubSubClient,
 *   ArduinoJson, RTClib, SD, Servo) bilinen API'lerine uygun sekilde
 *   yazilmistir; ancak gercek Deneyap Kart uzerinde Deneyap Kart IDE'siyle
 *   derlenip fiziksel sensorlerle DOGRULANMASI GEREKIR. Pin numaralari ve
 *   kalibrasyon sabitleri icin config.h basindaki notlara bakiniz.
 *
 * Gerekli kutuphaneler (Deneyap Kart IDE / Arduino IDE Kutuphane Yoneticisi):
 *   - TinyGSM (Volodymyr Shymanskyy)
 *   - PubSubClient (Nick O'Leary)
 *   - ArduinoJson (Benoit Blanchon), v6+
 *   - RTClib (Adafruit)
 *   - SD (Arduino core ile birlikte gelir)
 *   - Servo (Arduino core ile birlikte gelir)
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#include "config.h"
#include "sensors.h"
#include "decision_engine.h"
#include "treatment.h"
#include "logger.h"
#include "mqtt_handler.h"

// ============================================================================
// SON BILINEN DURUM (MQTT yayin araligi, okuma araligindan farkli oldugu icin
// en son okumayi/teshisi ara bellekte tutariz)
// ============================================================================

static SensorOkumalari _sonOkuma;
static TeshisSonucu _sonTeshis;
static unsigned long _sonOkumaZamaniMs = 0;
static unsigned long _sonMqttZamaniMs = 0;

// ============================================================================
// ILERI BILDIRIMLER
// ============================================================================

void islemDongusunuCalistir();

// ============================================================================
// KURULUM
// ============================================================================

void setup() {
  Serial.begin(115200);
  delay(200);   // sadece seri port stabilizasyonu icin, tek seferlik

  Serial.println(F("=========================================="));
  Serial.println(F(" AquaGuard - Deneyap Kart Firmware v1.0"));
  Serial.println(F(" Arge-T HydroLab - TEKNOFEST 2026"));
  Serial.println(F("=========================================="));

  sensorleriBaslat();
  Serial.println(F("[SISTEM] Sensorler baslatildi."));

  tedaviSistemBaslat();
  Serial.println(F("[SISTEM] Tedavi kontrol sistemi baslatildi (mutex hazir)."));

  loggerBaslat();
  Serial.println(F("[SISTEM] SD kart / RTC loglama baslatildi."));

  mqttBaslat();
  Serial.println(F("[SISTEM] GSM/MQTT modulu baslatildi."));

  Serial.println(F("[SISTEM] Kurulum tamamlandi, ana donguye giriliyor.\n"));
}

// ============================================================================
// ANA DONGU
// ============================================================================

void loop() {
  // Non-blocking durum makineleri -- HER turda ilerletilmeli
  tedaviGuncelle();
  mqttDonguyuIsle();

  unsigned long simdi = millis();

  // Periyodik sensor okuma + karar + tedavi + log dongusu
  if (simdi - _sonOkumaZamaniMs >= OKUMA_ARALIGI_MS) {
    _sonOkumaZamaniMs = simdi;
    islemDongusunuCalistir();
  }

  // Periyodik MQTT veri yayini (en son bilinen okuma/teshis ile)
  if (simdi - _sonMqttZamaniMs >= MQTT_GONDERIM_ARALIGI_MS) {
    _sonMqttZamaniMs = simdi;

    char zaman[32];
    zamanDamgasiAl(zaman, sizeof(zaman));

    veriYayinla(_sonOkuma, _sonTeshis, aktifTedaviGetir(), durulamaAktifMi(), zaman);
  }
}

// ============================================================================
// TEK BIR OLCUM + KARAR + TEDAVI + LOG DONGUSU
// ============================================================================

void islemDongusunuCalistir() {
  _sonOkuma = tumSensorleriOku();
  _sonTeshis = kuralTabanliTeshis(_sonOkuma);

  Serial.print(F("[OKUMA] pH="));           Serial.print(_sonOkuma.ph, 2);
  Serial.print(F("  EC="));                 Serial.print(_sonOkuma.ec, 2);
  Serial.print(F("  ORP="));                Serial.print(_sonOkuma.orp, 0);
  Serial.print(F("  Turbidite="));          Serial.print(_sonOkuma.turbidite, 1);
  Serial.print(F("  Debi="));               Serial.print(_sonOkuma.debi, 2);
  Serial.print(F("  dBasinc="));            Serial.println(_sonOkuma.deltaBasinc, 3);

  Serial.print(F("[TESHIS] durum="));       Serial.print(durumAdiGetir(_sonTeshis.durum));
  Serial.print(F("  tur="));                Serial.print(turAdiGetir(_sonTeshis.tur));
  Serial.print(F("  guven=%"));             Serial.println(_sonTeshis.guven, 1);

  sensorVerisiLogla(_sonOkuma, _sonTeshis);

  if (_sonTeshis.durum == DURUM_TESPIT_EDILDI) {
    if (tedaviMesgulMu()) {
      Serial.println(F("[TEDAVI] Tikanma tespit edildi ama baska bir tedavi/durulama surdugu icin BEKLETILIYOR (mutex kilidi)."));
    } else {
      TedaviTuru gerekliTedavi = tedaviTuruBelirle(_sonTeshis.tur);
      bool baslatildi = tedaviBaslat(gerekliTedavi);

      if (baslatildi) {
        Serial.print(F("[TEDAVI] BASLATILDI: "));
        Serial.println(tedaviAdiGetir(gerekliTedavi));

        tedaviLogla(gerekliTedavi, tedaviSuresiGetir(gerekliTedavi), _sonTeshis.tur, _sonTeshis.guven);
      } else {
        // Teorik olarak buraya dusmemeli (tedaviMesgulMu() zaten kontrol edildi),
        // ama guvenlik icin log birakiyoruz.
        Serial.println(F("[TEDAVI] UYARI: Tedavi baslatilamadi (mutex reddetti)."));
      }
    }
  } else if (_sonTeshis.durum == DURUM_BELIRSIZ) {
    Serial.println(F("[OPERATOR BILDIRIMI] Tikanma olabilir ama guven dusuk -- tedavi TETIKLENMEDI, operator kontrolu bekleniyor."));
  }

  Serial.println();
}
