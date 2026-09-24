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
 *   TASARIM ILKESI: Zamanlama millis() tabanli sayaclarla yapilir, delay()
 *   yalnizca kurulumda (seri port stabilizasyonu) kullanilir. DIKKAT:
 *   PubSubClient'in connect() cagrisi TCP baglanti kurana kadar BEKLER;
 *   bu yuzden (a) bir pompa calisirken yeniden baglanma ERTELENIR
 *   (mqtt_handler.h), (b) donanim watchdog'u kilitlenmeye karsi karti
 *   yeniden baslatir (bkz. watchdogBaslat).
 *
 *   2026-09-23: Iletisim katmani SIM800L/GSM'den Deneyap Kart'in dahili
 *   WiFi'sine TASINDI (bkz. mqtt_handler.h basi).
 *
 * ONEMLI - DERLEME / SAHA NOTU:
 *   Bu dosya arduino-cli ile GENEL ESP32 karti icin DERLENDI (2026-09-19),
 *   ama Deneyap Kart tanimiyla derlenmedi ve GERCEK DONANIMDA HIC
 *   CALISTIRILMADI. Kod, Arduino/ESP32
 *   C++ standartlarina ve kullanilan kutuphanelerin (WiFi, PubSubClient,
 *   ArduinoJson, RTClib, SD, ESP32Servo) bilinen API'lerine uygun sekilde
 *   yazilmistir; ancak gercek Deneyap Kart uzerinde Deneyap Kart IDE'siyle
 *   derlenip fiziksel sensorlerle DOGRULANMASI GEREKIR. Pin numaralari ve
 *   kalibrasyon sabitleri icin config.h basindaki notlara bakiniz.
 *
 * Gerekli kutuphaneler (Deneyap Kart IDE / Arduino IDE Kutuphane Yoneticisi):
 *   - WiFi (ESP32 cekirdegiyle birlikte gelir, ayrica kurulmaz)
 *   - PubSubClient (Nick O'Leary)
 *   - ArduinoJson (Benoit Blanchon), v6+
 *   - RTClib (Adafruit)
 *   - SD (Arduino core ile birlikte gelir)
 *   - ESP32Servo (Kevin Harrington/John Bennett) -- KLASIK "Servo"
 *     kutuphanesi DEGIL: Deneyap Kart ESP32 tabanlidir ve standart AVR
 *     Servo kutuphanesiyle uyumlu calismaz
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#include "config.h"
#include "sensors.h"
#include "decision_engine.h"
#include "treatment.h"
#include "ana_vana.h"
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
// DONANIM WATCHDOG (K3)
// ============================================================================
// Ana dongu WATCHDOG_ZAMAN_ASIMI_MS boyunca ilerlemezse kart yeniden
// baslatilir; yeniden baslatma pompa pinlerini LOW yapar (guvenli yon).
// Arduino-ESP32 cekirdek 3.x (IDF 5) ve 2.x (IDF 4) API'leri FARKLIDIR:
// 3.x yolu derlenerek dogrulandi, 2.x yolu (Deneyap Kart paketi 2.x
// cekirdek kullanabilir) DERLENMEDI -- gercek kartla ilk derlemede kontrol edin.
#include <esp_task_wdt.h>

static void watchdogBaslat() {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  esp_task_wdt_config_t ayar = {};
  ayar.timeout_ms = WATCHDOG_ZAMAN_ASIMI_MS;
  ayar.idle_core_mask = 0;   // bosta gorevleri izleme, sadece ana dongu
  ayar.trigger_panic = true; // zaman asiminda yeniden baslat
  // Cekirdek watchdog'u onceden baslattiysa yeniden yapilandir, degilse baslat.
  if (esp_task_wdt_reconfigure(&ayar) == ESP_ERR_INVALID_STATE) {
    esp_task_wdt_init(&ayar);
  }
#else
  esp_task_wdt_init(WATCHDOG_ZAMAN_ASIMI_MS / 1000, true);
#endif
  esp_task_wdt_add(NULL);    // mevcut gorevi (loop) izlemeye al
}

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

  anaVanaBaslat();
  Serial.println(F("[SISTEM] Ana sulama vanasi baslatildi (varsayilan: acik)."));

  loggerBaslat();
  Serial.println(F("[SISTEM] SD kart / RTC loglama baslatildi."));

  mqttBaslat();
  Serial.println(F("[SISTEM] WiFi/MQTT modulu baslatildi."));

  // Watchdog, WiFi'ye baglanma gibi uzun kurulum adimlarindan SONRA devreye
  // girer (aksi halde kurulum sirasinda kendini yeniden baslatirdi).
  watchdogBaslat();
  Serial.println(F("[SISTEM] Donanim watchdog aktif."));

  Serial.println(F("[SISTEM] Kurulum tamamlandi, ana donguye giriliyor.\n"));
}

// ============================================================================
// ANA DONGU
// ============================================================================

void loop() {
  esp_task_wdt_reset();   // ana dongu yasiyor -- watchdog'u besle
  // Non-blocking durum makineleri -- HER turda ilerletilmeli
  tedaviGuncelle();
  anaVanaZamanlayiciyiGuncelle();   // sureli sulama -- suresi dolani kapat
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
  // Ana vana operator tarafindan MANUEL kapatilmissa: sulama akmiyorken
  // debi/basinc okumalari anlamsiz (yanlis "tikanma" alarmina yol acar) --
  // teshis dongusunu atla, sadece durumu logla. bkz. ana_vana.h.
  if (!anaVanaAcikMi()) {
    // GUVENLIK YEDEGI (birincil kontrol mqtt_handler.h'deki "sulama_durdur"
    // isleyicisindedir -- vana kapanma anini ORADA aninda yakalar): vana
    // baska bir yoldan kapanmis olabilecegi ihtimaline karsi, burada da
    // GERCEKTEN CALISAN bir pompa varsa aninda durdur.
    if (aktifTedaviGetir() != TEDAVI_YOK) {
      tedaviAcilDurdur();
      Serial.println(F("[GUVENLIK] Ana vana kapali -- suren tedavi ANINDA durduruldu (akis yok)."));
    } else if (durulamaAktifMi()) {
      // Vana kapaliyken durulama suresi ILERLEMESIN (akissiz gecen sure
      // durulama sayilmaz) -- bu blok periyodik olarak (OKUMA_ARALIGI_MS
      // = 5sn'de bir) calistigi icin, her cagrida baslangic zamanini
      // "simdi"ye oteleyerek sureyi fiilen DONDURMUS oluyoruz (5sn,
      // DURULAMA_SURESI_MS=45sn'nin cok altinda -- guvenli marj). bkz.
      // treatment.h -> durulamaZamanlayicisiniSifirla() yorumu.
      durulamaZamanlayicisiniSifirla();
    }
    // Vana kapaliyken debi/basinc okumalari ANLAMSIZDIR (sifir akis fiziksel
    // tikanma gibi gorunur) -- son bilinen teshisi guvenli "veri yok"
    // durumuna sifirla, MQTT eski/gecersiz bir "tespit_edildi" durumunu
    // sonsuza kadar tekrar tekrar yayinlamasin (bkz. veriYayinla dongusu).
    _sonTeshis = TeshisSonucu{};
    Serial.println(F("[SULAMA] Ana vana manuel kapali -- olcum/teshis atlaniyor."));
    return;
  }

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
