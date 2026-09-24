/*
 * AquaGuard - WiFi/MQTT Iletisim Katmani
 * =================================================
 *
 * Amac:
 *   Deneyap Kart'in dahili WiFi radyosu uzerinden bir kablosuz aga baglanir
 *   ve sensor/teshis/tedavi verisini MQTT protokolu ile uzak sunucuya (ve
 *   oradan Flutter mobil uygulamasina) yayinlar. Baglanti koptugunda
 *   periyodik olarak yeniden baglanmayi dener.
 *
 *   2026-09-23: Mimari SIM800L/GSM'den WiFi'ye TASINDI (ekip karari --
 *   sunum/fuar ortaminda WiFi, SIM/operator kapsamasindan daha guvenilir).
 *   ONEMLI KISIT: WiFi'nin menzili sinirlidir (yonlendiriciden birkac on
 *   metre) -- GSM'in aksine, kart yonlendiricinin sinyal alaninin DISINDA
 *   bir tarlada CALISMAZ. Gercek saha kurulumunda bu goz onunde bulundurulmali
 *   (bkz. README "Bilinen Sinirlamalar").
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
 *     "tedavi_aktif":  "yok" | "asit_dozlama" | "klor_enjeksiyon" | "yuksek_basincli_yikama"
 *                      | "besin_sivi" | "besin_toz",
 *     "durulama_aktif": false,
 *     "ana_vana_acik":  true,
 *     "sulama_kalan_saniye": 0
 *   }
 *
 *   ana_vana_acik (SEMA v2, 2026-09-19): ana sulama vanasinin GERCEK durumu.
 *   Uygulama vana durumunu tahmin etmek yerine bununla esitler (K1/Y3).
 *
 *   sulama_kalan_saniye (SEMA v3, 2026-09-24): "sulama_baslat" komutu bir
 *   "sure_dakika" ile (sureli) baslatildiysa, vananin KENDILIGINDEN
 *   kapanmasina kalan saniye; sureli bir sulama YOKSA 0. Uygulama bunu
 *   geri sayim gostermek icin kullanir. bkz. ana_vana.h
 *   anaVanaKalanSaniyeGetir().
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
 *                                 {"komut":"tedavi_baslat","tedavi_turu":"besin_sivi"}   (Faz 3)
 *                                 {"komut":"tedavi_baslat","tedavi_turu":"besin_toz"}    (Faz 3)
 *                                 {"komut":"tedavi_durdur"}
 *                                 {"komut":"normale_dondur"}
 *                                 {"komut":"sulama_baslat","sure_dakika":30}   (opsiyonel)
 *                                 {"komut":"sulama_durdur"}
 *                               "besin_sivi"/"besin_toz" (2026-09-25, Faz 3): tikanma
 *                               teshisinden BAGIMSIZ, operatorun kendi karariyla (orn.
 *                               besin takviyesi) manuel baslattigi dozlama -- AYNI
 *                               guvenlik kilidine (mutex) VE zon-izolasyonuna tabidir,
 *                               asit/klor/yikama ile ASLA ayni anda calismaz. bkz.
 *                               treatment.h TedaviTuru, config.h PIN_POMPA_BESIN_SIVI/
 *                               PIN_KARISTIRICI_TOZ/PIN_POMPA_BESIN_TOZ (donanim YER TUTUCU).
 *                               bkz. _komutMesajGeldiginde() asagida.
 *
 * Kutuphaneler: WiFi (ESP32 cekirdegiyle birlikte gelir) + PubSubClient +
 *   ArduinoJson
 *
 * Tarih:  2026-09-01 (WiFi'ye tasinma: 2026-09-23)
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

// ============================================================================
// GLOBAL NESNELER
// ============================================================================

static WiFiClient _wifiClient;
static PubSubClient _mqttClient(_wifiClient);

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

// ============================================================================
// ZON-BAZLI DOZLAMA IZOLASYONU (2026-09-25, ekip karari)
// ============================================================================
//
// FIZIKSEL VARSAYIM (Enver ile dogrulanmali -- bkz. DONANIM_KONTROL_LISTESI.md):
// dozlama pompalari (asit/klor/vb.) ORTAK bir ana hatta enjekte ediyor; her
// zonun kendi damlama hatti basindaki bir vana, o zona su/ilac gidip
// gitmeyecegini belirliyor. Bu yuzden bir zona dozlama yapilirken DIGER
// zonlarin vanalari kapatilmazsa, ilac PAYLASIMLI hatta karisip TUM
// zonlara (istenmeyen sekilde) gider.
//
// COZUM: bu kart, kendi zonu (BOLGE_ID) icin bir tedavi baslatmadan HEMEN
// once, DIGER TUM zonlarin komut konusuna "sulama_durdur" yayinlar (var
// olan zon-bazli MQTT semasi TEKRAR KULLANILIR -- ister bu zonlari BASKA
// fiziksel kartlar yonetsin, ister AYNI kart yonetsin, fark etmez: hangi
// kart o zonun komut konusuna abone ise vanayi kapatir). Tedavi + durulama
// TAMAMEN bitince ayni zonlara "sulama_baslat" yayinlanir.
//
// BILINCLI SINIRLAMA (dogruluk icin acikca yazildi): bu, ACK BEKLEMEYEN
// "ates et ve devam et" bir koordinasyondur -- diger zonlarin vanasinin
// GERCEKTEN kapandigini TEYIT ETMEDEN dozlamaya baslar. Gercek zamanli
// senkron bir el sikisma (handshake) non-blocking tek-ilmekli bir tasarimda
// onemli bir karmasiklik/gecikme riski tasirdi; MQTT+vana tepki suresi
// (tipik olarak <1 sn) 30 saniyelik dozlama suresine kiyasla kucuk bir
// paydir. Gercek donanimda ilk testte, izolasyonun GERCEKTEN zamaninda
// calistigi (vana kapanmadan pompa baslamadigi) OLCULMELIDIR.
void _digerZonlarinVanasiniAyarla(bool acik) {
  const char* komut = acik ? "sulama_baslat" : "sulama_durdur";
  StaticJsonDocument<64> govde;
  govde["komut"] = komut;
  char cikti[64];
  size_t uzunluk = serializeJson(govde, cikti, sizeof(cikti));

  char hedefTopic[48];
  for (int zon = 1; zon <= TOPLAM_ZON_SAYISI; zon++) {
    if (zon == BOLGE_ID) continue;   // kendi zonumuz -- tedaviBaslat zaten yonetiyor
    snprintf(hedefTopic, sizeof(hedefTopic), MQTT_KONU_KOMUT, zon);
    _mqttClient.publish(hedefTopic, (const uint8_t*)cikti, uzunluk, false);
  }
}

// tedaviBaslat()'in izolasyon-farkinda sarmalayicisi -- OTONOM (karar
// motoru) VE MANUEL (operator komutu) tedavi baslatma yollarinin IKISI DE
// bunu cagirmali, dogrudan tedaviBaslat() DEGIL (bkz. aquaguard_main.ino,
// _komutMesajGeldiginde "tedavi_baslat").
bool tedaviBaslatZonIzoleyerek(TedaviTuru tedavi) {
  if (tedavi == TEDAVI_YOK || tedaviMesgulMu()) {
    return false;   // erken cikis -- gereksiz yere diger zonlari kapatma
  }
  _digerZonlarinVanasiniAyarla(false);
  bool basladi = tedaviBaslat(tedavi);
  if (!basladi) {
    // Beklenmeyen yaris durumu (mutex bu iki satir arasinda mesgul oldu) --
    // guvenlik: diger zonlari HEMEN geri ac, kapali birakma.
    _digerZonlarinVanasiniAyarla(true);
  }
  return basladi;
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
        basarili = tedaviBaslatZonIzoleyerek(tedavi);
        Serial.println(basarili
            ? F("[Komut] Operator: manuel tedavi baslatildi (diger zonlar izole edildi).")
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
      // ZON IZOLASYONU: bkz. aquaguard_main.ino ayni yorumun ikizi -- acil
      // durdurma normal durulama-bitti akisini atlar, izole edilmis diger
      // zonlar elle geri acilmali.
      _digerZonlarinVanasiniAyarla(true);
      Serial.println(F("[GUVENLIK] Ana vana kapatiliyor -- suren tedavi ANINDA durduruldu (akis yok), diger zonlar geri acildi."));
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
    // Opsiyonel "sure_dakika" alani -- verilmemisse (0) suresiz acilir
    // (eski davranis). Verilmisse, vana SULAMA_MAKS_SURE_DK ile kirpilip
    // o sure sonunda KENDILIGINDEN kapanir (bkz. ana_vana.h anaVanayiSureliAc).
    long sureDakika = belge["sure_dakika"] | 0L;
    anaVanayiSureliAc(sureDakika);
    // Eger yarim kalmis bir durulama varsa, flow GERCEKTEN geri geldigi
    // bu andan itibaren suresi SIFIRDAN baslar (bkz. treatment.h).
    durulamaZamanlayicisiniSifirla();
    if (sureDakika > 0) {
      Serial.print(F("[Komut] Operator: ana vana yeniden acildi, "));
      Serial.print(sureDakika);
      Serial.println(F(" dakika sureli sulama basladi."));
    } else {
      Serial.println(F("[Komut] Operator: ana vana yeniden acildi, sulama basladi (suresiz)."));
    }
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
    // WiFi.begin() tekrar cagirmak guvenlidir -- ESP32 karisik/eski bir
    // baglanma denemesini iptal edip yenisini baslatir, BLOKLAMAZ.
    WiFi.begin(WIFI_SSID, WIFI_SIFRE);
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
  // Sureli sulama geri sayimi (SEMA v3) -- sureli baslatilmadiysa 0.
  belge["sulama_kalan_saniye"] = anaVanaKalanSaniyeGetir();

  char cikti[768];
  size_t uzunluk = serializeJson(belge, cikti, sizeof(cikti));

  bool basarili = _mqttClient.publish(_veriTopic, (const uint8_t*)cikti, uzunluk, true);
  if (!basarili) {
    Serial.println(F("[MQTT] UYARI: veri yayinlanamadi (baglanti veya boyut sorunu)."));
  }
}

#endif // AQUAGUARD_MQTT_HANDLER_H
