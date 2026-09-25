/*
 * AquaGuard - Ana Firmware (Deneyap Kart 1A v2)
 * ==========================================
 *
 * Amac:
 *   Tum modulleri (sensors, decision_engine, treatment, logger, mqtt_handler)
 *   bir araya getiren ana dongu. Akis, HER zon icin ayri ayri:
 *
 *     [zon vanasi acik mi?] -> sensor oku -> karar ver (Katman 1)
 *     -> gerekiyorsa tedavi uygula -> SD karta logla -> MQTT ile yayinla
 *
 * 2026-09-25 BUYUK MIMARI DUZELTMESI:
 *   Onceki tasarim "4 ayri Deneyap Kart, her biri BOLGE_ID'siyle TEK bir
 *   zonu izliyor" varsayiyordu. Enver'in gonderdigi pin notu + kart
 *   fotografi ve kullanici onayiyla DOGRULANDI: gercekte TEK kart 4 zonu
 *   DOGRUDAN yonetiyor, sensorler de zon-bazli DEGIL -- TEK ortak set.
 *
 *   PRATIK SONUC: bu kart, sulama zamanlamasini (hangi zonun vanasinin ne
 *   zaman acik oldugunu) KENDISI BELIRLEMEZ -- bu operator/zamanlayici
 *   kararidir (ana_vana.h'nin API'si degismedi, "sulama_baslat"/"durdur").
 *   Firmware sadece HANGI zonlarin vanasi O AN acik oldugunu GOZLEMLER:
 *   acik olan her zon icin, paylasimli sensor setinden taze bir okuma alip
 *   O ZONA atfeder ve teshis/tedavi uygular. Ayni anda birden fazla zon
 *   acikSA, paylasimli sensor hangi zonun suyunu gordugunu AYIRT EDEMEZ --
 *   bu, donanimin fiziksel bir sinirlamasidir, yazilimla cozulemez (bkz.
 *   DONANIM_KONTROL_LISTESI.md). Sahada normal kullanimda zonlarin TEK
 *   TEK sulanmasi (ayni anda sadece bir vananin acik olmasi) ONERILIR.
 *
 *   TASARIM ILKESI: Zamanlama millis() tabanli sayaclarla yapilir, delay()
 *   yalnizca kurulumda (seri port stabilizasyonu) kullanilir. DIKKAT:
 *   PubSubClient'in connect() cagrisi TCP baglanti kurana kadar BEKLER;
 *   bu yuzden (a) bir pompa calisirken yeniden baglanma ERTELENIR
 *   (mqtt_handler.h), (b) donanim watchdog'u kilitlenmeye karsi karti
 *   yeniden baslatir (bkz. watchdogBaslat).
 *
 * ONEMLI - DERLEME / SAHA NOTU:
 *   Bu dosya artik GERCEK kart tanimiyla (esp32:esp32:deneyapkart1Av2)
 *   derleniyor (2026-09-25 -- daha once SADECE jenerik ESP32 kartina gore
 *   derleniyordu). GERCEK DONANIMDA HIC CALISTIRILMADI. Pin numaralari
 *   icin config.h basindaki notlara bakiniz -- bircogu HALA Enver'in
 *   dogrulamasini bekliyor (#warning ile isaretli).
 *
 * Gerekli kutuphaneler (Deneyap Kart IDE / Arduino IDE Kutuphane Yoneticisi):
 *   - WiFi (ESP32 cekirdegiyle birlikte gelir, ayrica kurulmaz)
 *   - PubSubClient (Nick O'Leary)
 *   - ArduinoJson (Benoit Blanchon), v6+
 *   - RTClib (Adafruit)
 *   - SD (Arduino core ile birlikte gelir)
 *   - ESP32Servo (Kevin Harrington/John Bennett)
 *
 * Tarih:  2026-09-01 (tek-kart/4-zon mimarisi: 2026-09-25)
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
// SON BILINEN DURUM -- HER ZON ICIN AYRI (2026-09-25) -- MQTT yayin araligi,
// okuma araligindan farkli oldugu icin en son okumayi/teshisi ara bellekte
// tutariz. 1-indeksli diziler (dizin 0 kullanilmaz).
// ============================================================================

static SensorOkumalari _zonOkuma[TOPLAM_ZON_SAYISI + 1];
static TeshisSonucu _zonTeshis[TOPLAM_ZON_SAYISI + 1];
static unsigned long _sonOkumaZamaniMs = 0;
static unsigned long _sonMqttZamaniMs = 0;

// ============================================================================
// ILERI BILDIRIMLER
// ============================================================================

void islemDongusunuCalistir(int zon);

// ============================================================================
// DONANIM WATCHDOG (K3)
// ============================================================================
#include <esp_task_wdt.h>

static void watchdogBaslat() {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  esp_task_wdt_config_t ayar = {};
  ayar.timeout_ms = WATCHDOG_ZAMAN_ASIMI_MS;
  ayar.idle_core_mask = 0;   // bosta gorevleri izleme, sadece ana dongu
  ayar.trigger_panic = true; // zaman asiminda yeniden baslat
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
  Serial.println(F(" AquaGuard - Deneyap Kart 1A v2 Firmware v2.0"));
  Serial.println(F(" Arge-T HydroLab - TEKNOFEST 2026"));
  Serial.println(F(" (Tek kart / 4 zon dogrudan yonetim mimarisi)"));
  Serial.println(F("=========================================="));

  sensorleriBaslat();
  Serial.println(F("[SISTEM] Sensorler baslatildi."));

  tedaviSistemBaslat();
  Serial.println(F("[SISTEM] Tedavi kontrol sistemi baslatildi (mutex hazir)."));

  anaVanaBaslat();
  Serial.print(F("[SISTEM] "));
  Serial.print(TOPLAM_ZON_SAYISI);
  Serial.println(F(" zon vanasi baslatildi (varsayilan: acik)."));

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
  bool durulamaSimdiBitti = tedaviGuncelle();
  if (durulamaSimdiBitti) {
    // ZON IZOLASYONU: tedavi + zorunlu durulama TAM olarak bitti (mutex
    // serbest kaldi) -- dozlama icin gecici kapatilmis DIGER zonlarin
    // vanalarini simdi geri ac. tedaviZonuGetir() durulama SIRASINDA hala
    // gecerlidir (treatment.h sadece BURADA, durulama biter bitmez sifirlar).
    int tedaviZonu = tedaviZonuGetir();
    if (tedaviZonu == 0) {
      // Guvenlik yedegi: zon bilinmiyorsa (olmamasi gereken durum) hepsini ac.
      digerZonlarinVanasiniAyarla(0, true);
    } else {
      digerZonlarinVanasiniAyarla(tedaviZonu, true);
    }
    Serial.println(F("[SULAMA] Durulama tamamlandi, izole edilmis diger zonlarin vanalari yeniden aciliyor."));
  }
  anaVanaZamanlayiciyiGuncelle();   // sureli sulama -- suresi dolani kapat
  mqttDonguyuIsle();

  unsigned long simdi = millis();

  // Periyodik sensor okuma + karar + tedavi + log dongusu -- HER ACIK zon icin.
  if (simdi - _sonOkumaZamaniMs >= OKUMA_ARALIGI_MS) {
    _sonOkumaZamaniMs = simdi;
    for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
      islemDongusunuCalistir(zon);
    }
  }

  // Periyodik MQTT veri yayini (en son bilinen okuma/teshis ile) -- HER zon icin.
  if (simdi - _sonMqttZamaniMs >= MQTT_GONDERIM_ARALIGI_MS) {
    _sonMqttZamaniMs = simdi;

    char zaman[32];
    zamanDamgasiAl(zaman, sizeof(zaman));

    for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
      veriYayinla(zon, _zonOkuma[zon], _zonTeshis[zon], aktifTedaviGetir(),
                  durulamaAktifMi() && tedaviZonuGetir() == zon, zaman);
    }
  }
}

// ============================================================================
// TEK BIR ZON ICIN: OLCUM + KARAR + TEDAVI + LOG DONGUSU
// ============================================================================

void islemDongusunuCalistir(int zon) {
  // Zon vanasi operator tarafindan MANUEL kapatilmissa: sulama akmiyorken
  // debi/basinc okumalari anlamsiz (yanlis "tikanma" alarmina yol acar) --
  // teshis dongusunu atla, sadece durumu logla. bkz. ana_vana.h.
  if (!anaVanaAcikMi(zon)) {
    // GUVENLIK YEDEGI (birincil kontrol mqtt_handler.h'deki "sulama_durdur"
    // isleyicisindedir -- vana kapanma anini ORADA aninda yakalar): bu zon
    // icin GERCEKTEN CALISAN bir tedavi varsa aninda durdur.
    if (aktifTedaviGetir() != TEDAVI_YOK && tedaviZonuGetir() == zon) {
      tedaviAcilDurdur();
      digerZonlarinVanasiniAyarla(zon, true);
      Serial.print(F("[GUVENLIK] Zon "));
      Serial.print(zon);
      Serial.println(F(": vana kapali -- suren tedavi ANINDA durduruldu (akis yok), diger zonlar geri acildi."));
    } else if (durulamaAktifMi() && tedaviZonuGetir() == zon) {
      // Vana kapaliyken durulama suresi ILERLEMESIN (bkz. treatment.h
      // durulamaZamanlayicisiniSifirla() yorumu -- bu periyodik cagri,
      // OKUMA_ARALIGI_MS'de bir, baslangic zamanini "simdi"ye oteler).
      durulamaZamanlayicisiniSifirla();
    }
    // Vana kapaliyken bu zonun son bilinen teshisini guvenli "veri yok"
    // durumuna sifirla -- MQTT eski/gecersiz bir "tespit_edildi" durumunu
    // sonsuza kadar tekrar tekrar yayinlamasin.
    _zonTeshis[zon] = TeshisSonucu{};
    return;
  }

  // NOT: birden fazla zon AYNI ANDA acikSA, paylasimli sensor hangi zonun
  // suyunu gordugunu ayirt edemez -- her acik zon icin AYNI FIZIKSEL anda
  // taze bir okuma alinir (bkz. dosya basi mimari notu, DONANIM_KONTROL_
  // LISTESI.md). Sahada tek-seferde-tek-zon sulama ONERILIR.
  _zonOkuma[zon] = tumSensorleriOku();
  _zonTeshis[zon] = kuralTabanliTeshis(_zonOkuma[zon]);

  Serial.print(F("[OKUMA] Zon "));           Serial.print(zon);
  Serial.print(F("  pH="));                  Serial.print(_zonOkuma[zon].ph, 2);
  Serial.print(F("  EC="));                  Serial.print(_zonOkuma[zon].ec, 2);
  Serial.print(F("  ORP="));                 Serial.print(_zonOkuma[zon].orp, 0);
  Serial.print(F("  Turbidite="));           Serial.print(_zonOkuma[zon].turbidite, 1);
  Serial.print(F("  Debi="));                Serial.print(_zonOkuma[zon].debi, 2);
  Serial.print(F("  dBasinc="));             Serial.println(_zonOkuma[zon].deltaBasinc, 3);

  Serial.print(F("[TESHIS] Zon "));          Serial.print(zon);
  Serial.print(F("  durum="));               Serial.print(durumAdiGetir(_zonTeshis[zon].durum));
  Serial.print(F("  tur="));                 Serial.print(turAdiGetir(_zonTeshis[zon].tur));
  Serial.print(F("  guven=%"));              Serial.println(_zonTeshis[zon].guven, 1);

  sensorVerisiLogla(zon, _zonOkuma[zon], _zonTeshis[zon]);

  if (_zonTeshis[zon].durum == DURUM_TESPIT_EDILDI) {
    if (tedaviMesgulMu()) {
      Serial.print(F("[TEDAVI] Zon "));
      Serial.println(F(": tikanma tespit edildi ama baska bir tedavi/durulama surdugu icin BEKLETILIYOR (mutex kilidi)."));
    } else {
      TedaviTuru gerekliTedavi = tedaviTuruBelirle(_zonTeshis[zon].tur);
      bool baslatildi = tedaviBaslatZonIzoleyerek(zon, gerekliTedavi);

      if (baslatildi) {
        Serial.print(F("[TEDAVI] Zon "));
        Serial.print(zon);
        Serial.print(F(": BASLATILDI (diger zonlar izole edildi): "));
        Serial.println(tedaviAdiGetir(gerekliTedavi));

        tedaviLogla(zon, gerekliTedavi, tedaviSuresiGetir(gerekliTedavi), _zonTeshis[zon].tur, _zonTeshis[zon].guven);
      } else {
        Serial.print(F("[TEDAVI] UYARI: Zon "));
        Serial.print(zon);
        Serial.println(F(" icin tedavi baslatilamadi (mutex reddetti)."));
      }
    }
  } else if (_zonTeshis[zon].durum == DURUM_BELIRSIZ) {
    Serial.print(F("[OPERATOR BILDIRIMI] Zon "));
    Serial.print(zon);
    Serial.println(F(": tikanma olabilir ama guven dusuk -- tedavi TETIKLENMEDI, operator kontrolu bekleniyor."));
  }

  Serial.println();
}
