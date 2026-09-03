/*
 * AquaGuard - SIM800L GSM/MQTT Iletisim Katmani
 * =================================================
 *
 * Amac:
 *   SIM800L GSM modulu uzerinden GPRS baglantisi kurar ve sensor/teshis/
 *   tedavi verisini MQTT protokolu ile uzak sunucuya (ve oradan Flutter
 *   mobil uygulamasina) yayinlar. Baglanti koptugunda ENGELLEMEDEN
 *   (non-blocking) periyodik olarak yeniden baglanmayi dener.
 *
 * JSON PAYLOAD SEMASI (mock_yayinci.py ve Flutter uygulamasiyla AYNI olmali):
 *   {
 *     "zaman":         "2026-09-01 15:32:10",
 *     "zone":          1,
 *     "ph":            7.02,
 *     "ec":            1.17,
 *     "orp":           367.1,
 *     "turbidite":     3.97,
 *     "debi":          3.90,
 *     "delta_basinc":  0.12,
 *     "durum":         "normal" | "belirsiz" | "tespit_edildi",
 *     "tikanma_turu":  "yok" | "kimyasal" | "biyolojik" | "fiziksel",
 *     "guven":         94.2,
 *     "guven_kimyasal": 12.4,
 *     "guven_biyolojik": 94.2,
 *     "guven_fiziksel": 3.1,
 *     "tedavi_aktif":  "yok" | "asit_dozlama" | "klor_enjeksiyon" | "yuksek_basincli_yikama",
 *     "durulama_aktif": false
 *   }
 *
 *   guven_* alanlari, kural katmaninin UC tikanma turunu de ne kadar olasi
 *   gordugunu tasir (aciklanabilirlik) -- mobil uygulamadaki "Neden bu
 *   karar?" panelinin veri kaynagidir. Tikanma yoksa (durum=normal) ucu de 0'dir.
 *
 * Konu (topic) semasi:
 *   aquaguard/zone{N}/veri   -> yukaridaki JSON, RETAINED (son mesaj brokerda
 *                               saklanir; yeni baglanan istemci -- ornegin
 *                               Flutter uygulamasi -- aninda son durumu alir)
 *   aquaguard/zone{N}/durum  -> "online" / "offline" (Last Will Testament ile
 *                               cihazin baglanti durumu izlenebilir)
 *   aquaguard/zone{N}/komut  -> SADECE ABONE OLUNUR (yayinlanmaz). Operator
 *                               mudahalesi (mobil uygulama) buraya JSON komut
 *                               yollar, RETAINED DEGILDIR:
 *                                 {"komut":"tedavi_baslat","tedavi_turu":"asit_dozlama"}
 *                                 {"komut":"tedavi_durdur"}
 *                                 {"komut":"normale_dondur"}
 *                               bkz. _komutMesajGeldiginde() asagida.
 *
 * Kutuphaneler: TinyGSM + PubSubClient + ArduinoJson
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_MQTT_HANDLER_H
#define AQUAGUARD_MQTT_HANDLER_H

#define TINY_GSM_MODEM_SIM800

#include <Arduino.h>
#include <string.h>
#include <TinyGsmClient.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include "sensors.h"
#include "decision_engine.h"
#include "treatment.h"
#include "ana_vana.h"

// ============================================================================
// GLOBAL NESNELER
// ============================================================================

static HardwareSerial _sim800Seri(2);   // ESP32 UART2
static TinyGsm _modem(_sim800Seri);
static TinyGsmClient _gsmClient(_modem);
static PubSubClient _mqttClient(_gsmClient);

static unsigned long _sonBaglantiDenemesiMs = 0;
static const unsigned long BAGLANTI_DENEME_ARALIGI_MS = 15000UL;

static char _durumTopic[48];
static char _veriTopic[48];
static char _komutTopic[48];

// ============================================================================
// OPERATOR KOMUTLARI (bkz. dosya basindaki JSON sema aciklamasi)
// ============================================================================
//
// PubSubClient'in callback imzasi TUM abone olunan konular icin ORTAKTIR --
// bu cihaz sadece _komutTopic'e abone oldugu icin ek bir konu kontrolüne
// gerek yoktur, ama ileride baska bir konuya abone olunursa `topic`
// parametresi kontrol edilmelidir.
void _komutMesajGeldiginde(char* topic, byte* payload, unsigned int uzunluk) {
  StaticJsonDocument<256> belge;
  DeserializationError hata = deserializeJson(belge, payload, uzunluk);
  if (hata) {
    Serial.println(F("[Komut] JSON ayristirilamadi, mesaj yoksayildi."));
    return;
  }

  const char* komut = belge["komut"] | "";

  if (strcmp(komut, "tedavi_baslat") == 0) {
    TedaviTuru tedavi = tedaviTuruAyristir(belge["tedavi_turu"] | "");
    if (tedavi == TEDAVI_YOK) {
      Serial.println(F("[Komut] Gecersiz/eksik tedavi_turu, yoksayildi."));
      return;
    }
    bool basladi = tedaviBaslat(tedavi);
    Serial.println(basladi
        ? F("[Komut] Operator: manuel tedavi baslatildi.")
        : F("[Komut] Operator: manuel tedavi REDDEDILDI (mutex mesgul)."));
  } else if (strcmp(komut, "tedavi_durdur") == 0) {
    bool durduruldu = tedaviErkenDurdur();
    Serial.println(durduruldu
        ? F("[Komut] Operator: aktif tedavi erken durduruldu, durulamaya geciliyor.")
        : F("[Komut] Operator: durdurulacak aktif tedavi yok."));
  } else if (strcmp(komut, "normale_dondur") == 0) {
    // Sadece bir GUNLUK kaydi -- karar motoru zaten bir sonraki okumada
    // esik asilmiyorsa "normal" dondurecektir; burada aktuator durumunda
    // degisiklik YOKTUR (yanlis alarmda zaten hicbir aktuator calismiyordu).
    Serial.println(F("[Komut] Operator: durumu yanlis alarm olarak isaretledi."));
  } else if (strcmp(komut, "sulama_durdur") == 0) {
    anaVanayiKapat();
    Serial.println(F("[Komut] Operator: ana vana MANUEL kapatildi, sulama durdu."));
  } else if (strcmp(komut, "sulama_baslat") == 0) {
    anaVanayiAc();
    Serial.println(F("[Komut] Operator: ana vana yeniden acildi, sulama basladi."));
  } else {
    Serial.print(F("[Komut] Bilinmeyen komut: "));
    Serial.println(komut);
  }
}

// ============================================================================
// KURULUM
// ============================================================================

void mqttBaslat() {
  snprintf(_veriTopic, sizeof(_veriTopic), MQTT_KONU_VERI, BOLGE_ID);
  snprintf(_durumTopic, sizeof(_durumTopic), MQTT_KONU_DURUM, BOLGE_ID);
  snprintf(_komutTopic, sizeof(_komutTopic), MQTT_KONU_KOMUT, BOLGE_ID);

  _sim800Seri.begin(SIM800L_BAUD, SERIAL_8N1, SIM800L_RX_PIN, SIM800L_TX_PIN);

  Serial.println(F("[MQTT] SIM800L modemi baslatiliyor..."));
  _modem.restart();

  Serial.print(F("[MQTT] GPRS'e baglaniliyor: "));
  Serial.println(GSM_APN);
  _modem.gprsConnect(GSM_APN, GSM_KULLANICI, GSM_SIFRE);

  _mqttClient.setServer(MQTT_BROKER_ADRESI, MQTT_BROKER_PORT);
  _mqttClient.setCallback(_komutMesajGeldiginde);
}

// ============================================================================
// BAGLANTI DURUMU
// ============================================================================

bool mqttBagliMi() {
  return _mqttClient.connected();
}

// Non-blocking yeniden baglanma: her cagrida hemen denemez, sadece
// BAGLANTI_DENEME_ARALIGI_MS gectiyse dener. Boylece ana dongu kilitlenmez.
void mqttBaglantiyiSagla() {
  if (_mqttClient.connected()) {
    return;
  }

  unsigned long simdi = millis();
  if (simdi - _sonBaglantiDenemesiMs < BAGLANTI_DENEME_ARALIGI_MS) {
    return;
  }
  _sonBaglantiDenemesiMs = simdi;

  if (!_modem.isGprsConnected()) {
    Serial.println(F("[MQTT] GPRS baglantisi yok, yeniden deneniyor..."));
    _modem.gprsConnect(GSM_APN, GSM_KULLANICI, GSM_SIFRE);
    return;
  }

  Serial.println(F("[MQTT] Brokera baglaniliyor..."));

  // MQTT_KULLANICI_ADI bos string ("") oldugunda bile PubSubClient'in
  // kullanici adli overload'unu cagirmak, CONNECT paketine BOS ama VAR
  // olan bir kullanici adi alani koyar -- bazi sıkı brokerlar bunu
  // reddeder. Bu yuzden kimlik dogrulama bilgisi yoksa parametresiz
  // overload'u kullaniyoruz.
  bool baglandi;
  if (strlen(MQTT_KULLANICI_ADI) > 0) {
    baglandi = _mqttClient.connect(
        CIHAZ_ADI,
        MQTT_KULLANICI_ADI, MQTT_SIFRE,
        _durumTopic, 1, true, "offline"   // Last Will Testament
    );
  } else {
    baglandi = _mqttClient.connect(
        CIHAZ_ADI,
        _durumTopic, 1, true, "offline"   // Last Will Testament
    );
  }

  if (baglandi) {
    Serial.println(F("[MQTT] Baglanti basarili."));
    _mqttClient.publish(_durumTopic, "online", true);
    _mqttClient.subscribe(_komutTopic);
  } else {
    Serial.print(F("[MQTT] Baglanti basarisiz, hata kodu: "));
    Serial.println(_mqttClient.state());
  }
}

// Ana dongude HER TURDA cagrilmali (PubSubClient'in ic islerini yurutur)
void mqttDonguyuIsle() {
  if (_mqttClient.connected()) {
    _mqttClient.loop();
  } else {
    mqttBaglantiyiSagla();
  }
}

// ============================================================================
// VERI YAYINLAMA
// ============================================================================

void veriYayinla(const SensorOkumalari& okuma, const TeshisSonucu& teshis,
                  TedaviTuru aktifTedavi, bool durulamaAktif, const char* zamanDamgasi) {
  if (!_mqttClient.connected()) {
    return;
  }

  StaticJsonDocument<512> belge;
  belge["zaman"] = zamanDamgasi;
  belge["zone"] = BOLGE_ID;
  belge["ph"] = serialized(String(okuma.ph, 2));
  belge["ec"] = serialized(String(okuma.ec, 2));
  belge["orp"] = serialized(String(okuma.orp, 0));
  belge["turbidite"] = serialized(String(okuma.turbidite, 1));
  belge["debi"] = serialized(String(okuma.debi, 2));
  belge["delta_basinc"] = serialized(String(okuma.deltaBasinc, 3));
  belge["durum"] = durumAdiGetir(teshis.durum);
  belge["tikanma_turu"] = turAdiGetir(teshis.tur);
  belge["guven"] = serialized(String(teshis.guven, 1));
  belge["guven_kimyasal"] = serialized(String(teshis.guvenKimyasal, 1));
  belge["guven_biyolojik"] = serialized(String(teshis.guvenBiyolojik, 1));
  belge["guven_fiziksel"] = serialized(String(teshis.guvenFiziksel, 1));
  belge["tedavi_aktif"] = tedaviAdiGetir(aktifTedavi);
  belge["durulama_aktif"] = durulamaAktif;

  char cikti[512];
  size_t uzunluk = serializeJson(belge, cikti, sizeof(cikti));

  bool basarili = _mqttClient.publish(_veriTopic, (const uint8_t*)cikti, uzunluk, true);
  if (!basarili) {
    Serial.println(F("[MQTT] UYARI: veri yayinlanamadi (baglanti veya boyut sorunu)."));
  }
}

#endif // AQUAGUARD_MQTT_HANDLER_H
