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
 *     "durulama_aktif": false,
 *     "ana_vana_acik":  true
 *   }
 *
 *   ana_vana_acik (SEMA v2, 2026-09-19): ana sulama vanasinin GERCEK durumu.
 *   Uygulama vana durumunu tahmin etmek yerine bununla esitler (K1/Y3).
 *
 *   guven_* alanlari, kural katmaninin UC tikanma turunu de ne kadar olasi
 *   gordugunu tasir (aciklanabilirlik) -- mobil uygulamadaki "Neden bu
 *   karar?" panelinin veri kaynagidir. Tikanma yoksa (durum=normal) ucu de 0'dir.
 *
 *   SEMA v2 NOTU (2026-09-16; komut_durumu + ana_vana_acik 2026-09-19'da
 *   UYGULANDI, hazne alanlari HENUZ YOK): Flutter tarafi (models/
 *   sensor_okuma.dart) artik opsiyonel "hazne_asit_seviye_yuzde" ve
 *   "hazne_klor_seviye_yuzde" alanlarini da OKUYABILIYOR (null-safe --
 *   alan JSON'da yoksa UI ilgili karti gostermez). Bu firmware HENUZ bu
 *   alanlari YAYINLAMIYOR cunku gercek donanimda bir hazne seviye sensoru
 *   YOK (bkz. config.h). Fiziksel bir seviye sensoru (ornegin bir
 *   ultrasonik veya siamano float switch) eklendiginde, bu iki alan
 *   `belge["hazne_asit_seviye_yuzde"]`/`belge["hazne_klor_seviye_yuzde"]`
 *   olarak asagidaki JSON olusturma bolumune eklenmelidir -- python/
 *   aquaguard_mock_yayinci.py zaten (illustratif/demo amacli) bu alanlari
 *   yayinliyor, gercek sema BUNUNLA eslesmelidir.
 *
 * Konu (topic) semasi:
 *   aquaguard/zone{N}/veri   -> yukaridaki JSON, RETAINED (son mesaj brokerda
 *                               saklanir; yeni baglanan istemci -- ornegin
 *                               Flutter uygulamasi -- aninda son durumu alir)
 *   aquaguard/zone{N}/durum  -> "online" / "offline" (Last Will Testament ile
 *                               cihazin baglanti durumu izlenebilir)
 *   aquaguard/zone{N}/komut_durumu -> her komuta ACK/NACK yaniti (QoS0, retained
 *                               DEGIL): {"komut_id":"...","durum":"tamamlandi"|"reddedildi"}
 *                               komut_id yoksa yanit gonderilmez. bkz. _komutDurumuYayinla().
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
static char _komutDurumuTopic[56];

// ============================================================================
// OPERATOR KOMUTLARI (bkz. dosya basindaki JSON sema aciklamasi)
// ============================================================================
//
// PubSubClient'in callback imzasi TUM abone olunan konular icin ORTAKTIR --
// bu cihaz sadece _komutTopic'e abone oldugu icin ek bir konu kontrolüne
// gerek yoktur, ama ileride baska bir konuya abone olunursa `topic`
// parametresi kontrol edilmelidir.
// Komut sonucunu (ACK/NACK) cihazdan uygulamaya bildirir (SEMA v2).
// Uygulama her komuta benzersiz bir "komut_id" ekler ve bu konudan yanit
// bekler; yanit gelmezse 30 sn sonra "zaman asimi" gosterir. komut_id
// yoksa (eski istemci / elle test) sessizce atlanir. Yayin basarisiz olursa
// (baglanti koptu vb.) komutun UYGULANMASINI etkilemez -- sadece geri
// bildirim kaybolur.
void _komutDurumuYayinla(const char* komutId, bool basarili) {
  if (komutId == nullptr || komutId[0] == '\0') {
    return;
  }
  StaticJsonDocument<192> yanit;
  yanit["komut_id"] = komutId;
  yanit["durum"] = basarili ? "tamamlandi" : "reddedildi";
  char cikti[192];
  size_t uzunluk = serializeJson(yanit, cikti, sizeof(cikti));
  _mqttClient.publish(_komutDurumuTopic, (const uint8_t*)cikti, uzunluk, false);
}

void _komutMesajGeldiginde(char* topic, byte* payload, unsigned int uzunluk) {
  StaticJsonDocument<320> belge;
  DeserializationError hata = deserializeJson(belge, payload, uzunluk);
  if (hata) {
    Serial.println(F("[Komut] JSON ayristirilamadi, mesaj yoksayildi."));
    return;
  }

  const char* komut = belge["komut"] | "";
  // komutId, belge'nin icindeki bir dizgeye isaret eder -- bu fonksiyon
  // bitene kadar gecerlidir (belge yerel degisken), yanit ayni cagri
  // icinde yayinlandigi icin guvenlidir.
  const char* komutId = belge["komut_id"] | "";

  // Her dal, sonucu `basarili` degiskenine yazar; ACK/NACK EN SONDA tek
  // noktadan yayinlanir (bir dal yanit gondermeyi unutamaz).
  bool basarili = false;

  if (strcmp(komut, "tedavi_baslat") == 0) {
    // GUVENLIK: ana vana kapaliyken (akis yok) YENI bir kimyasal dozlama/
    // yikama BASLATILAMAZ -- akissiz bir hatta dozlama, kimyasalin asiri
    // yogunlasmasina/pompanin kuru calismasina yol acar. bkz. ana_vana.h.
    if (!anaVanaAcikMi()) {
      Serial.println(F("[Komut] Operator: manuel tedavi REDDEDILDI (ana vana kapali, akis yok)."));
    } else {
      TedaviTuru tedavi = tedaviTuruAyristir(belge["tedavi_turu"] | "");
      if (tedavi == TEDAVI_YOK) {
        Serial.println(F("[Komut] Gecersiz/eksik tedavi_turu, yoksayildi."));
      } else {
        basarili = tedaviBaslat(tedavi);
        Serial.println(basarili
            ? F("[Komut] Operator: manuel tedavi baslatildi.")
            : F("[Komut] Operator: manuel tedavi REDDEDILDI (mutex mesgul)."));
      }
    }
  } else if (strcmp(komut, "tedavi_durdur") == 0) {
    bool durduruldu = tedaviErkenDurdur();
    Serial.println(durduruldu
        ? F("[Komut] Operator: aktif tedavi erken durduruldu, durulamaya geciliyor.")
        : F("[Komut] Operator: durdurulacak aktif tedavi yok."));
    // "Durdurulacak tedavi yok" da istenen son durumdur (tedavi calismiyor):
    // acil durdurma gibi durumlarda NACK yanlis alarm uretmesin.
    basarili = true;
  } else if (strcmp(komut, "normale_dondur") == 0) {
    // Sadece bir GUNLUK kaydi -- karar motoru zaten bir sonraki okumada
    // esik asilmiyorsa "normal" dondurecektir; burada aktuator durumunda
    // degisiklik YOKTUR (yanlis alarmda zaten hicbir aktuator calismiyordu).
    Serial.println(F("[Komut] Operator: durumu yanlis alarm olarak isaretledi."));
    basarili = true;
  } else if (strcmp(komut, "sulama_durdur") == 0) {
    // GUVENLIK: vana kapatilirken GERCEKTEN CALISAN bir pompa varsa, akis
    // olmadan dozlamaya devam etmek tehlikelidir -- aninda VE TAM olarak
    // durdur (tedaviAcilDurdur, mutex'i de sifirlar -- bu gercek bir
    // ariza/beklenmeyen durumdur).
    if (aktifTedaviGetir() != TEDAVI_YOK) {
      tedaviAcilDurdur();
      Serial.println(F("[GUVENLIK] Ana vana kapatiliyor -- suren tedavi ANINDA durduruldu (akis yok)."));
    } else if (durulamaAktifMi()) {
      // SADECE zorunlu durulama suruyor (pompa zaten kapali) -- akissiz
      // durulamaya devam EDILEMEZ ama mutex SIFIRLANMAZ (bkz.
      // durulamaZamanlayicisiniSifirla() dosya-basi yorumu): aksi halde
      // yarim kalmis bir durulama "tamamlandi" sayilip hat tam
      // yikanmadan yeni tedaviye izin verilirdi.
      Serial.println(F("[GUVENLIK] Ana vana kapatiliyor -- durulama akis kesildigi icin yarim kaldi (mutex ACIK kalmaya devam ediyor)."));
    }
    anaVanayiKapat();
    Serial.println(F("[Komut] Operator: ana vana MANUEL kapatildi, sulama durdu."));
    basarili = true;
  } else if (strcmp(komut, "sulama_baslat") == 0) {
    anaVanayiAc();
    // Eger yarim kalmis bir durulama varsa, flow GERCEKTEN geri geldigi
    // bu andan itibaren suresi SIFIRDAN baslar (bkz. treatment.h).
    durulamaZamanlayicisiniSifirla();
    Serial.println(F("[Komut] Operator: ana vana yeniden acildi, sulama basladi."));
    basarili = true;
  } else {
    Serial.print(F("[Komut] Bilinmeyen komut: "));
    Serial.println(komut);
  }

  _komutDurumuYayinla(komutId, basarili);
}

// ============================================================================
// KURULUM
// ============================================================================

void mqttBaslat() {
  snprintf(_veriTopic, sizeof(_veriTopic), MQTT_KONU_VERI, BOLGE_ID);
  snprintf(_durumTopic, sizeof(_durumTopic), MQTT_KONU_DURUM, BOLGE_ID);
  snprintf(_komutTopic, sizeof(_komutTopic), MQTT_KONU_KOMUT, BOLGE_ID);
  snprintf(_komutDurumuTopic, sizeof(_komutDurumuTopic), MQTT_KONU_KOMUT_DURUMU, BOLGE_ID);

  _sim800Seri.begin(SIM800L_BAUD, SERIAL_8N1, SIM800L_RX_PIN, SIM800L_TX_PIN);

  Serial.println(F("[MQTT] SIM800L modemi baslatiliyor..."));
  _modem.restart();

  Serial.print(F("[MQTT] GPRS'e baglaniliyor: "));
  Serial.println(GSM_APN);
  _modem.gprsConnect(GSM_APN, GSM_KULLANICI, GSM_SIFRE);

  _mqttClient.setServer(MQTT_BROKER_ADRESI, MQTT_BROKER_PORT);
  // KRITIK: PubSubClient varsayilan paket siniri 256 bayttir; telemetri JSON'u
  // (~330 bayt) bu sinirin USTUNDE oldugu icin setBufferSize olmadan her
  // publish() sessizce basarisiz olur. Ayrica gelen komutlar da bu
  // tamponu kullanir.
  if (!_mqttClient.setBufferSize(MQTT_PAKET_BOYUTU)) {
    Serial.println(F("[MQTT] UYARI: tampon boyutu ayarlanamadi (bellek yetersiz) -- veri yayini basarisiz olabilir."));
  }
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

  StaticJsonDocument<768> belge;
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
  // Ana vana durumu CIHAZDAN raporlanir -- uygulama vana durumunu tahmin
  // etmek yerine bununla esitler (bkz. Flutter SensorOkuma.anaVanaAcik).
  belge["ana_vana_acik"] = anaVanaAcikMi();

  char cikti[768];
  size_t uzunluk = serializeJson(belge, cikti, sizeof(cikti));

  bool basarili = _mqttClient.publish(_veriTopic, (const uint8_t*)cikti, uzunluk, true);
  if (!basarili) {
    Serial.println(F("[MQTT] UYARI: veri yayinlanamadi (baglanti veya boyut sorunu)."));
  }
}

#endif // AQUAGUARD_MQTT_HANDLER_H
