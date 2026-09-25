/*
 * AquaGuard - WiFi/MQTT Iletisim Katmani
 * =================================================
 *
 * Amac:
 *   Deneyap Kart'in dahili WiFi radyosu uzerinden bir kablosuz aga baglanir
 *   ve TOPLAM_ZON_SAYISI zonun HEPSININ sensor/teshis/tedavi verisini MQTT
 *   protokolu ile uzak sunucuya (ve oradan Flutter mobil uygulamasina)
 *   yayinlar. Baglanti koptugunda periyodik olarak yeniden baglanmayi dener.
 *
 *   2026-09-25 BUYUK DUZELTME: onceki tasarim "4 ayri Deneyap Kart, her biri
 *   kendi BOLGE_ID'sine ait TEK bir topic setine yayin yapiyor" varsayiyordu.
 *   Enver'in notu + kullanici onayiyla DOGRULANDI: gercekte TEK kart TUM 4
 *   zonun topic'lerine (veri/durum/komut/komut_durumu) yayin/abonelik yapar.
 *   MQTT SEMASI (disaridan -- uygulama/mock acisindan) DEGISMEDI, sadece
 *   YAYINLAYAN tarafin fiziksel olarak tek cihaz olmasi ic mimariyi degistirdi.
 *
 *   2026-09-23: Iletisim katmani SIM800L/GSM'den Deneyap Kart'in dahili
 *   WiFi'sine TASINDI (bkz. mqtt_handler.h basi).
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
 *     "sicaklik_ham_voltaj": 1.65,
 *     "durum":         "normal" | "belirsiz" | "tespit_edildi",
 *     "tikanma_turu":  "yok" | "kimyasal" | "biyolojik" | "fiziksel",
 *     "guven":         94.2,
 *     "guven_kimyasal": 12.4,
 *     "guven_biyolojik": 94.2,
 *     "guven_fiziksel": 3.1,
 *     "tedavi_aktif":  "yok" | "asit_dozlama" | "klor_enjeksiyon" | "yuksek_basincli_yikama"
 *                      | "besin_sivi" | "besin_toz",
 *     "durulama_aktif": false,
 *     "ana_vana_acik":  true,
 *     "sulama_kalan_saniye": 0
 *   }
 *
 *   sicaklik_ham_voltaj (2026-09-25, YENI, opsiyonel): A0 pininin HAM
 *   voltaji -- santigrat DEGIL, kalibre edilmedi (bkz. sensors.h
 *   sicaklikOkuHamVoltaj() dosya ici notu). Sadece Enver/Beyzanur'un
 *   sensorun gercekten calisip calismadigini gormesi icin.
 *
 *   ana_vana_acik / sulama_kalan_saniye: ARTIK O ZONUN KENDI vanasinin
 *   durumu (bkz. ana_vana.h, zon-bazli) -- tek bir paylasimli "ana vana"
 *   degil.
 *
 * Konu (topic) semasi -- HER zon icin ayri (N = 1..TOPLAM_ZON_SAYISI):
 *   aquaguard/zone{N}/veri   -> yukaridaki JSON, RETAINED
 *   aquaguard/zone{N}/durum  -> "online" / "offline"
 *   aquaguard/zone{N}/komut_durumu -> ACK/NACK: {"komut_id","durum":"tamamlandi"|"reddedildi"}
 *   aquaguard/zone{N}/komut  -> SADECE ABONE OLUNUR. Operator mudahalesi:
 *                                 {"komut":"tedavi_baslat","tedavi_turu":"asit_dozlama"}
 *                                 {"komut":"tedavi_durdur"}
 *                                 {"komut":"normale_dondur"}
 *                                 {"komut":"sulama_baslat","sure_dakika":30}
 *                                 {"komut":"sulama_durdur"}
 *
 *   DURUM (online/offline) SINIRLAMASI: MQTT'nin Last Will Testament (LWT)
 *   ozelligi CONNECT paketi basina SADECE TEK bir topic destekler. Bu kart
 *   TEK bir MQTT baglantisiyla 4 zonu temsil ettigi icin, LWT SADECE Zon
 *   1'in durum topic'ine kayitlidir -- baglanti BEKLENMEDIK sekilde koparsa
 *   (guc kesintisi vb.) sadece zone1/durum otomatik "offline" olur, 2-4
 *   OLMAZ (bilinen/kabul edilen sinirlama). Basarili baglanmada HEPSINE
 *   elle "online" yayinlanir.
 *
 * Kutuphaneler: WiFi (ESP32 cekirdegiyle birlikte gelir) + PubSubClient +
 *   ArduinoJson
 *
 * Tarih:  2026-09-01 (WiFi'ye tasinma: 2026-09-23, tek-kart/4-zon: 2026-09-25)
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_MQTT_HANDLER_H
#define AQUAGUARD_MQTT_HANDLER_H

#include <Arduino.h>
#include <string.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "config.h"
#include "sensors.h"
#include "decision_engine.h"
#include "treatment.h"
#include "ana_vana.h"
#include "logger.h"

// ============================================================================
// GLOBAL NESNELER
// ============================================================================

static WiFiClient _wifiClient;
static PubSubClient _mqttClient(_wifiClient);

static unsigned long _sonBaglantiDenemesiMs = 0;
static const unsigned long BAGLANTI_DENEME_ARALIGI_MS = 15000UL;

// 1-indeksli topic dizileri (dizin 0 kullanilmaz).
static char _veriTopic[TOPLAM_ZON_SAYISI + 1][32];
static char _durumTopic[TOPLAM_ZON_SAYISI + 1][32];
static char _komutTopic[TOPLAM_ZON_SAYISI + 1][32];
static char _komutDurumuTopic[TOPLAM_ZON_SAYISI + 1][40];

// ============================================================================
// OPERATOR KOMUTLARI (bkz. dosya basindaki JSON sema aciklamasi)
// ============================================================================

// zon: yanit hangi zonun komut_durumu topic'ine gidecek.
void _komutDurumuYayinla(int zon, const char* komutId, bool basarili) {
  if (komutId == nullptr || komutId[0] == '\0') {
    return;
  }
  if (zon < 1 || zon > TOPLAM_ZON_SAYISI) return;
  StaticJsonDocument<192> yanit;
  yanit["komut_id"] = komutId;
  yanit["durum"] = basarili ? "tamamlandi" : "reddedildi";
  char cikti[192];
  size_t uzunluk = serializeJson(yanit, cikti, sizeof(cikti));
  _mqttClient.publish(_komutDurumuTopic[zon], (const uint8_t*)cikti, uzunluk, false);
}

// ============================================================================
// ZON-BAZLI DOZLAMA IZOLASYONU (2026-09-25)
// ============================================================================
//
// FIZIKSEL VARSAYIM (Enver ile dogrulanmali -- bkz. DONANIM_KONTROL_LISTESI.md):
// dozlama pompalari (asit/klor/vb.) ORTAK bir ana hatta enjekte ediyor; her
// zonun kendi damlama hatti basindaki bir vana, o zona su/ilac gidip
// gitmeyecegini belirliyor. Bu yuzden bir zona dozlama yapilirken DIGER
// zonlarin vanalari kapatilmazsa, ilac PAYLASIMLI hatta karisip TUM
// zonlara (istenmeyen sekilde) gider.
//
// COZUM (2026-09-25 basitlestirmesi): TEK kart TUM vanalari dogrudan
// yonettigi icin, izolasyon artik MQTT uzerinden BASKA cihazlara komut
// yayinlamaz -- ana_vana.h'deki digerZonlarinVanasiniAyarla() ile DOGRUDAN,
// YEREL bir fonksiyon cagrisidir. Ag gecikmesi/guvenilirlik riski ortadan
// kalkti.
//
// tedaviBaslat()'in izolasyon-farkinda sarmalayicisi -- OTONOM (karar
// motoru) VE MANUEL (operator komutu) tedavi baslatma yollarinin IKISI DE
// bunu cagirmali, dogrudan tedaviBaslat() DEGIL.
bool tedaviBaslatZonIzoleyerek(int zon, TedaviTuru tedavi) {
  if (tedavi == TEDAVI_YOK || tedaviMesgulMu()) {
    return false;   // erken cikis -- gereksiz yere diger zonlari kapatma
  }
  digerZonlarinVanasiniAyarla(zon, false);
  bool basladi = tedaviBaslat(tedavi, zon);
  if (!basladi) {
    // Beklenmeyen yaris durumu (mutex bu iki satir arasinda mesgul oldu) --
    // guvenlik: diger zonlari HEMEN geri ac, kapali birakma.
    digerZonlarinVanasiniAyarla(zon, true);
  }
  return basladi;
}

// topic (orn. "aquaguard/zone3/komut") -- hangi zonun komut konusuna
// geldigini cozer. Eslesme yoksa 0 doner (olmamasi gereken bir durum,
// sadece bu cihazin abone oldugu konular geri cagrilabilir).
static int _topicZonuCoz(const char* topic) {
  for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
    if (strcmp(topic, _komutTopic[zon]) == 0) return zon;
  }
  return 0;
}

void _komutMesajGeldiginde(char* topic, byte* payload, unsigned int uzunluk) {
  int zon = _topicZonuCoz(topic);
  if (zon == 0) {
    Serial.print(F("[Komut] Bilinmeyen topic'ten mesaj, yoksayildi: "));
    Serial.println(topic);
    return;
  }

  StaticJsonDocument<320> belge;
  DeserializationError hata = deserializeJson(belge, payload, uzunluk);
  if (hata) {
    Serial.println(F("[Komut] JSON ayristirilamadi, mesaj yoksayildi."));
    return;
  }

  const char* komut = belge["komut"] | "";
  const char* komutId = belge["komut_id"] | "";

  // Her dal, sonucu `basarili` degiskenine yazar; ACK/NACK EN SONDA tek
  // noktadan yayinlanir (bir dal yanit gondermeyi unutamaz).
  bool basarili = false;

  if (strcmp(komut, "tedavi_baslat") == 0) {
    // GUVENLIK: o zonun vanasi kapaliyken (akis yok) YENI bir kimyasal
    // dozlama/yikama BASLATILAMAZ -- akissiz bir hatta dozlama, kimyasalin
    // asiri yogunlasmasina/pompanin kuru calismasina yol acar.
    if (!anaVanaAcikMi(zon)) {
      Serial.println(F("[Komut] Operator: manuel tedavi REDDEDILDI (zon vanasi kapali, akis yok)."));
    } else {
      TedaviTuru tedavi = tedaviTuruAyristir(belge["tedavi_turu"] | "");
      if (tedavi == TEDAVI_YOK) {
        Serial.println(F("[Komut] Gecersiz/eksik tedavi_turu, yoksayildi."));
      } else {
        basarili = tedaviBaslatZonIzoleyerek(zon, tedavi);
        Serial.println(basarili
            ? F("[Komut] Operator: manuel tedavi baslatildi (diger zonlar izole edildi).")
            : F("[Komut] Operator: manuel tedavi REDDEDILDI (mutex mesgul veya pin dogrulanmadi)."));
        if (basarili) {
          tedaviLogla(zon, tedavi, tedaviSuresiGetir(tedavi), TUR_YOK, 0.0f);
        }
      }
    }
  } else if (strcmp(komut, "tedavi_durdur") == 0) {
    bool durduruldu = tedaviErkenDurdur();
    Serial.println(durduruldu
        ? F("[Komut] Operator: aktif tedavi erken durduruldu, durulamaya geciliyor.")
        : F("[Komut] Operator: durdurulacak aktif tedavi yok."));
    basarili = true;
  } else if (strcmp(komut, "normale_dondur") == 0) {
    Serial.println(F("[Komut] Operator: durumu yanlis alarm olarak isaretledi."));
    basarili = true;
  } else if (strcmp(komut, "sulama_durdur") == 0) {
    // GUVENLIK: bu zon icin GERCEKTEN CALISAN bir tedavi varsa, akis
    // olmadan dozlamaya devam etmek tehlikelidir -- aninda VE TAM olarak
    // durdur.
    if (aktifTedaviGetir() != TEDAVI_YOK && tedaviZonuGetir() == zon) {
      tedaviAcilDurdur();
      digerZonlarinVanasiniAyarla(zon, true);
      Serial.println(F("[GUVENLIK] Zon vanasi kapatiliyor -- suren tedavi ANINDA durduruldu (akis yok), diger zonlar geri acildi."));
    } else if (durulamaAktifMi() && tedaviZonuGetir() == zon) {
      Serial.println(F("[GUVENLIK] Zon vanasi kapatiliyor -- durulama akis kesildigi icin yarim kaldi (mutex ACIK kalmaya devam ediyor)."));
    }
    anaVanayiKapat(zon);
    Serial.println(F("[Komut] Operator: zon vanasi MANUEL kapatildi, sulama durdu."));
    basarili = true;
  } else if (strcmp(komut, "sulama_baslat") == 0) {
    long sureDakika = belge["sure_dakika"] | 0L;
    anaVanayiSureliAc(zon, sureDakika);
    if (tedaviZonuGetir() == zon) {
      // Bu zon icin yarim kalmis bir durulama varsa, flow GERCEKTEN geri
      // geldigi bu andan itibaren suresi SIFIRDAN baslar (bkz. treatment.h).
      durulamaZamanlayicisiniSifirla();
    }
    if (sureDakika > 0) {
      Serial.print(F("[Komut] Operator: zon vanasi yeniden acildi, "));
      Serial.print(sureDakika);
      Serial.println(F(" dakika sureli sulama basladi."));
    } else {
      Serial.println(F("[Komut] Operator: zon vanasi yeniden acildi, sulama basladi (suresiz)."));
    }
    basarili = true;
  } else {
    Serial.print(F("[Komut] Bilinmeyen komut: "));
    Serial.println(komut);
  }

  _komutDurumuYayinla(zon, komutId, basarili);
}

// ============================================================================
// KURULUM
// ============================================================================

void mqttBaslat() {
  for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
    snprintf(_veriTopic[zon], sizeof(_veriTopic[zon]), MQTT_KONU_VERI, zon);
    snprintf(_durumTopic[zon], sizeof(_durumTopic[zon]), MQTT_KONU_DURUM, zon);
    snprintf(_komutTopic[zon], sizeof(_komutTopic[zon]), MQTT_KONU_KOMUT, zon);
    snprintf(_komutDurumuTopic[zon], sizeof(_komutDurumuTopic[zon]), MQTT_KONU_KOMUT_DURUMU, zon);
  }

  WiFi.mode(WIFI_STA);
  Serial.print(F("[MQTT] WiFi'ye baglaniliyor: "));
  Serial.println(WIFI_SSID);
  // WiFi.begin() BLOKLAMAZ -- baglanti arka planda kurulur, durumu
  // WiFi.status() ile takip edilir (bkz. mqttBaglantiyiSagla).
  WiFi.begin(WIFI_SSID, WIFI_SIFRE);

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

  // GUVENLIK (K3, WiFi'de de korunuyor): _mqttClient.connect() TCP baglanti
  // kurana kadar BEKLER (kotu sinyalde birkac saniye surebilir). Bir pompa
  // CALISIRKEN bu bekleme tedaviGuncelle()'yi geciktirebilir -- bu yuzden
  // aktif tedavi bitene kadar yeniden baglanma denemesi ERTELENIR (veri
  // yayini o sure kesilir, ki bu guvenli).
  if (aktifTedaviGetir() != TEDAVI_YOK) {
    return;
  }

  unsigned long simdi = millis();
  if (simdi - _sonBaglantiDenemesiMs < BAGLANTI_DENEME_ARALIGI_MS) {
    return;
  }
  _sonBaglantiDenemesiMs = simdi;

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(F("[MQTT] WiFi baglantisi yok, yeniden deneniyor..."));
    WiFi.begin(WIFI_SSID, WIFI_SIFRE);
    return;
  }

  Serial.println(F("[MQTT] Brokera baglaniliyor..."));

  // LWT SADECE Zon 1'in durum topic'ine kayitli (bkz. dosya basi notu --
  // MQTT protokolu CONNECT basina tek bir will-topic destekler).
  bool baglandi;
  if (strlen(MQTT_KULLANICI_ADI) > 0) {
    baglandi = _mqttClient.connect(
        CIHAZ_ADI,
        MQTT_KULLANICI_ADI, MQTT_SIFRE,
        _durumTopic[1], 1, true, "offline"
    );
  } else {
    baglandi = _mqttClient.connect(
        CIHAZ_ADI,
        _durumTopic[1], 1, true, "offline"
    );
  }

  if (baglandi) {
    Serial.println(F("[MQTT] Baglanti basarili."));
    for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
      _mqttClient.publish(_durumTopic[zon], "online", true);
      _mqttClient.subscribe(_komutTopic[zon]);
    }
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

void veriYayinla(int zon, const SensorOkumalari& okuma, const TeshisSonucu& teshis,
                  TedaviTuru aktifTedavi, bool durulamaAktif, const char* zamanDamgasi) {
  if (!_mqttClient.connected()) {
    return;
  }
  if (zon < 1 || zon > TOPLAM_ZON_SAYISI) return;

  StaticJsonDocument<768> belge;
  belge["zaman"] = zamanDamgasi;
  belge["zone"] = zon;
  belge["ph"] = serialized(String(okuma.ph, 2));
  belge["ec"] = serialized(String(okuma.ec, 2));
  belge["orp"] = serialized(String(okuma.orp, 0));
  belge["turbidite"] = serialized(String(okuma.turbidite, 1));
  belge["debi"] = serialized(String(okuma.debi, 2));
  belge["delta_basinc"] = serialized(String(okuma.deltaBasinc, 3));
  belge["sicaklik_ham_voltaj"] = serialized(String(okuma.sicaklikHamVoltaj, 2));
  belge["durum"] = durumAdiGetir(teshis.durum);
  belge["tikanma_turu"] = turAdiGetir(teshis.tur);
  belge["guven"] = serialized(String(teshis.guven, 1));
  belge["guven_kimyasal"] = serialized(String(teshis.guvenKimyasal, 1));
  belge["guven_biyolojik"] = serialized(String(teshis.guvenBiyolojik, 1));
  belge["guven_fiziksel"] = serialized(String(teshis.guvenFiziksel, 1));
  belge["tedavi_aktif"] = tedaviAdiGetir(aktifTedavi);
  belge["durulama_aktif"] = durulamaAktif;
  // Bu ZONUN KENDI vanasinin durumu (bkz. ana_vana.h, artik zon-bazli).
  belge["ana_vana_acik"] = anaVanaAcikMi(zon);
  belge["sulama_kalan_saniye"] = anaVanaKalanSaniyeGetir(zon);

  char cikti[768];
  size_t uzunluk = serializeJson(belge, cikti, sizeof(cikti));

  bool basarili = _mqttClient.publish(_veriTopic[zon], (const uint8_t*)cikti, uzunluk, true);
  if (!basarili) {
    Serial.print(F("[MQTT] UYARI: Zon "));
    Serial.print(zon);
    Serial.println(F(" verisi yayinlanamadi (baglanti veya boyut sorunu)."));
  }
}

#endif // AQUAGUARD_MQTT_HANDLER_H
