/*
 * AquaGuard - Yapilandirma Dosyasi
 * ==================================
 *
 * Amac:
 *   Tum firmware'in kullandigi pin tanimlari, kalibrasyon sabitleri, karar
 *   esikleri ve iletisim ayarlarini TEK bir yerde toplar. Diger tum .h
 *   dosyalari (sensors.h, decision_engine.h, treatment.h, logger.h,
 *   mqtt_handler.h) bu dosyayi kullanir.
 *
 * ============================================================================
 * 2026-09-25 BUYUK GUNCELLEME -- Enver'in gercek pin notu + kart fotografi
 * ============================================================================
 *   Enver, elle yazilmis bir pin atama notu ve kartin fotografini gonderdi.
 *   Bu, iki temel varsayimi COKTU:
 *
 *   1) KART MODELI KESINLESTI: "Deneyap Kart 1A v2" (ESP32-S3 tabanli).
 *      Bu, bu ortamda zaten kurulu olan Deneyap/esp32 board paketlerinin
 *      pins_arduino.h dosyalari TEK TEK karsilastirilarak DOGRULANDI (tahmin
 *      degil) -- Enver'in notundaki A0-A7 (8 analog kanal) + D12/D13 SADECE
 *      bu varyantta mevcut, digerlerinde (Deneyap Kart, Deneyap Kart 1A v1,
 *      Deneyap Kart G) en fazla A0-A5 var. Onceki pin numaralari (GPIO32-39)
 *      KLASIK ESP32 varsayimiyla secilmisti -- YANLIS CIP AILESI icin
 *      yazilmisti, S3'te bu numaralar flash/PSRAM icin ayrilmis olabilir
 *      (fiziksel risk, sadece "yanlis okuma" degil). Asagida ARTIK ham GPIO
 *      numarasi degil, kartin KENDI sembolik isimleri (D0, A4 gibi)
 *      kullaniliyor -- board paketi dogru GPIO'ya kendisi cevirir.
 *
 *   2) MIMARI DUZELTMESI: onceki tasarim "4 AYRI Deneyap Kart, her biri
 *      kendi zonunu izliyor, MQTT ile koordine oluyor" varsayiyordu
 *      (BOLGE_ID). Kullanicidan DOGRULANDI: gercekte TEK kart 4 zonu
 *      DOGRUDAN yonetiyor (4 vana ayni kartta), sensorler de zon-bazli
 *      DEGIL -- TEK ortak set, vana sirayla acilip o zonun suyu okunuyor
 *      (round-robin). BOLGE_ID kavrami TAMAMEN KALDIRILDI.
 *
 *   HALA DOGRULANMAMIS (Enver'in notunda YOK, TAHMIN EDILMEDI -- asagida
 *   #warning ile isaretli, derlemeyi engellemez ama HER derlemede gorunur):
 *     - Debi ve basinc sensor pinleri (tikanma tespitinin ASIL sinyali!)
 *     - ORP sensor pini (bu kartta A0-A8 TAMAMEN DOLU, ORP icin YER YOK --
 *       ya haric bir ADC genisletici (fotografda gorunen PWM/I2C karti ADC
 *       DEGIL, once teyit edilmeli) gerekiyor ya da ORP bu prototipte YOK)
 *     - 4 "pompa" pininin (D0-D3) HANGI kimyasala gittigi (asit/klor/besin
 *       sivi) -- asagidaki esleme UZMAN TAHMINIDIR, DOGRULANMADAN gercek
 *       donanimda GUVENMEYIN
 *     - Toz karistirici/pompa + yikama valfi icin D0-D3 YETERSIZ (6 aktuator
 *       icin 4 pin) -- fotografta gorunen genisletme karti muhtemelen
 *       cozum, Enver'e sorulmali
 *     - SIM800L hala kartta (D12/D13 = Rx/Tx) -- WiFi'ye gecise ragmen
 *       kullanilacak mi belirsiz, firmware KULLANMIYOR (bilerek)
 *
 * Kaynaklar:
 *   - Karar esikleri ve sensor imzalari: PROJE_BRIEF.md SS4.2 / SS6
 *   - Debi sensoru kalibrasyon orani: YF-S201 tipi hall-effect debi
 *     sensorlerinin yaygin datasheet degeri (7.5 Hz / (L/dak) => 450 pals/litre)
 *   - Deneyap Kart 1A v2 pin haritasi: bu ortamda kurulu
 *     `esp32:esp32:deneyapkart1Av2` board paketinin pins_arduino.h dosyasi
 *
 * Tarih:  2026-09-01 (Deneyap Kart 1A v2 + tek-kart mimarisi: 2026-09-25)
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_CONFIG_H
#define AQUAGUARD_CONFIG_H

// ============================================================================
// 1) CIHAZ KIMLIGI / ZON SAYISI
// ============================================================================

#define CIHAZ_ADI "AquaGuard-Merkez" // MQTT client-id ve loglarda kullanilir
// ONEMLI (2026-09-25): artik "bu kartin zonu" kavrami YOK -- TEK kart
// TOPLAM_ZON_SAYISI zonun HEPSINI dogrudan yonetiyor (round-robin okuma +
// bagimsiz vana kontrolu). Eskiden burada bir BOLGE_ID vardi, kaldirildi.
#define TOPLAM_ZON_SAYISI 4

// ============================================================================
// 2) PIN TANIMLARI -- Deneyap Kart 1A v2 SEMBOLIK isimleri (D0.., A0..)
// ============================================================================
// NOT: D0, A4 gibi isimler bu .ino Deneyap Kart 1A v2 (esp32:esp32:
// deneyapkart1Av2) hedefiyle derlendiginde board paketi tarafindan otomatik
// tanimlanir -- burada YENIDEN #define EDILMEZLER, sadece kullanilirlar.

// --- DOGRULANMIS (Enver'in notundan BIREBIR alindi) ---
#define PIN_SICAKLIK_SENSOR   A0   // "sicaklik" -- YENI, kullanilip kullanilmayacagi DOGRULANMADI (bkz. 4b)
#define PIN_TURBIDITE_SENSOR  A1   // "bulaniklik"
#define PIN_EC_SENSOR         A3   // "iletkenlik"
#define PIN_PH_SENSOR         A4   // "pH"

#define PIN_VANA1             A5   // Zon 1 vanasi
#define PIN_VANA2             A6   // Zon 2 vanasi
#define PIN_VANA3             A7   // Zon 3 vanasi
#define PIN_VANA4             A2   // Zon 4 vanasi

// D0-D3: notta "pompa" olarak isaretli, HANGI pompanin HANGI pine bagli
// oldugu BELIRTILMEMIS. Asagidaki esleme UZMAN TAHMINIDIR (notta yazilma
// sirasiyla asit/klor/besin-sivi eslestirildi) -- ENVER DOGRULAMADAN
// GERCEK DONANIMDA GUVENILMEMELI, yanlis pompa tetiklenebilir.
#define PIN_POMPA_ASIT        D0   // UZMAN TAHMINI -- DOGRULANMADI
#define PIN_POMPA_KLOR        D1   // UZMAN TAHMINI -- DOGRULANMADI
#define PIN_POMPA_BESIN_SIVI  D2   // UZMAN TAHMINI -- DOGRULANMADI
// D3: 4. pompa neyin icin belirsiz (yikama valfi mi, toz karistirici mi) --
// asagida PIN_SERVO_YIKAMA olarak varsayildi (en olasi -- yikama zaten
// var olan bir aktuator, toz ise zaten ayri sorunlu, bkz. asagisi).
#define PIN_SERVO_YIKAMA      D3   // UZMAN TAHMINI -- DOGRULANMADI

// D12/D13: notta "Rx"/"Tx" olarak SIM800L'e (GSM modulu, kartta hala fiziksel
// olarak takili -- bkz. fotograf) baglandigi belirtiliyor. Firmware WiFi'ye
// gectigi icin (2026-09-23) BU PINLER KULLANILMIYOR -- sadece dokumantasyon
// icin burada tutuluyor, hicbir yerde referans edilmiyor.
// #define PIN_SIM800L_RX     D12  (KULLANILMIYOR)
// #define PIN_SIM800L_TX     D13  (KULLANILMIYOR)

// --- HALA BILINMIYOR: Enver'in notunda YOK, TAHMIN EDILMEDI ---
// KRITIK: debi + basinc, tikanma tespitinin ASIL sinyalidir (PROJE_BRIEF
// SS6) -- Enver dogrulamadan gercek donanimda anlamli bir teshis YAPILAMAZ.
// Asagidaki numaralar Deneyap Kart 1A v2'nin GUVENLI (Deneyap'in kendi
// D-serisi genel-amacli, flash/PSRAM ile CATISMAYAN) ama HENUZ fiziksel
// olarak dogrulanmamis pinleri -- eski klasik-ESP32 numaralari (GPIO27/36
// vb.) BILEREK KULLANILMADI, S3'te o numaralar flash/PSRAM'e ayrilmis
// olabilir (derleme hatasi vermez ama kart ACILMAYABILIR/cokebilir).
#warning "PIN_DEBI_SENSOR/PIN_BASINC_SENSOR Enver'in notunda YOK -- D4/A8 gecici/dogrulanmamis, gercek donanimda GUVENMEYIN"
#define PIN_DEBI_SENSOR       D4   // GECICI/DOGRULANMAMIS -- darbe cikisli, kesme destekli pin GEREKIR
#define PIN_BASINC_SENSOR     A8   // GECICI/DOGRULANMAMIS -- bu kartta kalan TEK bos analog kanal

// ORP: A0-A8 (9 analog kanal) Enver'in notundaki 4 sensor + 4 vana + yukaridaki
// gecici basinc atamasiyla TAMAMEN DOLU -- bu kartta ORP icin FIZIKSEL
// OLARAK bos analog pin KALMADI. Ya harici bir ADC genisletici (fotografta
// gorunen PWM/I2C karti PWM CIKISI icin, ADC GIRISI degil -- bunu ayri
// dogrulayin) gerekiyor ya da ORP bu prototipte YOK. Pin TANIMLANMADI --
// sensors.h/decision_engine.h ORP'siz DERLENIR, orpOku() sabit/notr bir
// deger doner (bkz. sensors.h). Enver'e SORULMALI.
#warning "PIN_ORP_SENSOR TANIMLANMADI -- bu kartta bos analog pin kalmadi, ORP donanimi/genisletici Enver'e SORULMALI"

// Besin toz dozlama (Faz 3): 2 ayri aktuator (karistirici + pompa) gerekir
// ama D0-D3 asit/klor/besin-sivi/yikama tarafindan TUKETILDI. Fotografta
// gorunen genisletme karti (PWM/I2C) muhtemelen cozum -- Enver'e sorulmadan
// pin ATANAMIYOR. Toz dozlama BU HALIYLE firmware'de calismaz (derlenir
// ama pin sabitleri asagida GECICI olarak D3 ile ayni -- CAKISMA riski,
// kullanilmamali) -- bkz. DONANIM_KONTROL_LISTESI.md.
#warning "PIN_KARISTIRICI_TOZ/PIN_POMPA_BESIN_TOZ icin pin YOK (D0-D3 doldu) -- toz dozlama Enver'in genisletme karti cevabini bekliyor"
#define PIN_KARISTIRICI_TOZ   D3   // CAKISMA -- PIN_SERVO_YIKAMA ile AYNI, GERCEK DONANIMDA KULLANMAYIN
#define PIN_POMPA_BESIN_TOZ   D3   // CAKISMA -- yukaridaki ikisiyle AYNI, GERCEK DONANIMDA KULLANMAYIN

// --- SD kart (SPI) -- Deneyap Kart 1A v2'nin kendi SDCS/SDMO/SDMI/SDCK
//     sembolleri var, SPI.h + SD.h bunlari varsayilan olarak kullanir.
#define PIN_SD_CS              SDCS

// --- RTC modulu I2C uzerinden calisir -- kartin kendi SDA/SCL sembolleri.
#define PIN_I2C_SDA            SDA
#define PIN_I2C_SCL            SCL

// --- WiFi (Deneyap Kart / ESP32 dahili radyo, ek modul gerekmez) ---
// 2026-09-23: mimari SIM800L/GSM'den WiFi'ye TASINDI (ekip karari -- saha
// yerine fuar/sunum ortaminda WiFi daha guvenilir; SIM800L donanimi kartta
// kalabilir ama firmware artik onu KULLANMIYOR). Eski GSM/GPRS pin ve APN
// tanimlari kaldirildi, bkz. mqtt_handler.h.
#define WIFI_SSID              "AGINIZI_BURAYA_YAZIN"   // YER TUTUCU
#define WIFI_SIFRE             "SIFRENIZI_BURAYA_YAZIN" // YER TUTUCU

// ============================================================================
// 3) SENSOR KALIBRASYON SABITLERI (YER TUTUCU -- saha kalibrasyonu bekliyor)
// ============================================================================
// Tum analog sensorler AYNI YONTEMLE kalibre edilir: iki referans noktasi
// (bilinen iki fiziksel deger + bu degerlerde olculen voltaj) kullanilarak
// dogrusal (linear) bir "egim * voltaj + ofset" formulu turetilir.
// Asagidaki degerler, sensor imzalari tablosundaki "normal" degerlere kabaca
// karsilik gelecek sekilde secilmis BASLANGIC degerleridir.

// pH: notr (pH 7.0) noktasinda tipik voltaj ~2.5V, tipik egim ~ -0.18 V/pH birimi
#define PH_KALIBRASYON_OFSET   7.00f
#define PH_KALIBRASYON_EGIM    (-5.556f)   // (1 / -0.18) -- voltaj sapmasini pH birimine cevirir
#define PH_KALIBRASYON_NOTR_V  2.50f       // pH 7.0'a denk gelen voltaj

// EC (mS/cm): dogrusal yaklasim -- gercek DFRobot/Gravity EC formulu sicaklik
// telafili ve dogrusal olmayabilir, saha kalibrasyonunda duzeltilmelidir.
#define EC_KALIBRASYON_OFSET   0.10f
#define EC_KALIBRASYON_EGIM    1.05f       // mS/cm per volt (yaklasik)

// ORP (mV): op-amp devresi voltaj kazancina gore olceklenir
#define ORP_KALIBRASYON_OFSET_V 1.50f      // ORP=0mV'a denk gelen voltaj
#define ORP_KALIBRASYON_KAZANC  250.0f     // mV per volt

// Turbidite (NTU): temiz suda ~4.2V, bulanik suda voltaj duser (sensore gore degisir)
#define TURBIDITE_KALIBRASYON_TEMIZ_V  4.20f
#define TURBIDITE_KALIBRASYON_EGIM     40.0f  // NTU per volt dususu

// Diferansiyel basinc (bar): 0.5-4.5V -> 0-BASINC_MAKS_BAR araligi (yaygin
// endustriyel basinc transduser cikisi)
#define BASINC_MAKS_BAR         1.00f
#define BASINC_MIN_VOLTAJ       0.50f
#define BASINC_MAKS_VOLTAJ      4.50f

// Debi (LPM): darbe/litre orani. YF-S201 tipi sensorler icin yaygin deger.
// Farkli bir debi sensoru kullanilirsa BU DEGER DEGISTIRILMELIDIR.
#define DEBI_PALS_PER_LITRE     450.0f

// ADC referans voltaji (ESP32 varsayilan 3.3V, 12-bit cozunurluk)
#define ADC_REFERANS_VOLTAJ     3.30f
#define ADC_COZUNURLUK          4095.0f

// GERILIM BOLUCU ORANLARI (Y1 -- KRITIK DONANIM AYARI)
// ESP32 ADC pini EN FAZLA 3.3 V okur; ustundeki giris kartin ADC girisine
// ZARAR VERIR ve okuma kirpilir. Basinc transduseri (0.5-4.5 V) ve turbidite
// modulu (~4.2 V) 3.3 V'u ASAR: bu ikisi icin sensor ile ADC pini arasina
// iki direncli bir gerilim bolucu KONMALIDIR. Oran = V_pin / V_sensor:
//   R1 (ust) = 10k, R2 (alt) = 20k  ->  oran = 20/(10+20) = 0.6667
// Firmware, okunan pin voltajini bu orana bolerek SENSOR tarafi voltaji geri
// hesaplar; kalibrasyon sabitleri SENSOR tarafi voltajla tanimlidir.
// 1.0 = bolucu YOK (sensor cikisi zaten <= 3.3 V ise, orn. pH/EC/ORP
// modulleri). GERCEK direnc degerlerinizi olcup burayi guncelleyin.
#define PH_BOLUCU_ORANI          1.0f
#define EC_BOLUCU_ORANI          1.0f
#define ORP_BOLUCU_ORANI         1.0f
#define TURBIDITE_BOLUCU_ORANI   0.6667f   // 10k/20k bolucu VARSAYIMI
#define BASINC_BOLUCU_ORANI      0.6667f   // 10k/20k bolucu VARSAYIMI

// Sensorlerin BEKLENEN EN YUKSEK cikis voltajlari (derleme zamani guvenlik
// kontrolu icin -- bkz. sensors.h static_assert). Modul datasheet'inden girin.
#define PH_MAKS_CIKIS_V          3.00f
#define EC_MAKS_CIKIS_V          3.00f
#define ORP_MAKS_CIKIS_V         3.00f
#define TURBIDITE_MAKS_CIKIS_V   4.50f
#define BASINC_MAKS_CIKIS_V      BASINC_MAKS_VOLTAJ

// ============================================================================
// 4) FIZIKSEL SINIRLAR (sensors.h'de disari tasan degerleri kirpmak icin)
// ============================================================================

#define PH_MIN            4.0f
#define PH_MAKS            10.0f
#define EC_MIN             0.3f
#define EC_MAKS            4.5f
#define ORP_MIN           -50.0f
#define ORP_MAKS           500.0f
#define TURBIDITE_MIN      0.0f
#define TURBIDITE_MAKS     60.0f
#define DEBI_MIN           0.2f
#define DEBI_MAKS          5.0f
#define DELTA_BASINC_MIN   0.02f
#define DELTA_BASINC_MAKS  1.0f

// ============================================================================
// 5) KARAR ESIKLERI
//    !!! python/aquaguard_karar_motoru.py ile BIREBIR AYNI OLMALI !!!
// ============================================================================

#define REFERANS_DEBI        4.0f    // Normal calisma debisi (LPM)
#define DEBI_DUSUS_ESIGI      1.5f    // LPM -- bu kadar dusus tikanma isareti
#define BASINC_ARTIS_ESIGI    0.36f   // bar
#define TURBIDITE_ESIGI       12.0f   // NTU
#define GUVEN_ESIGI           50.0f   // % -- altinda "belirsiz" kabul edilir

// --- Tur skorlama icin sensor imzalari (ortalama, std) -- SS6 tablosu ---
// pH, EC, ORP degerleri (kimyasal / biyolojik / fiziksel)
#define IMZA_KIMYASAL_PH_ORT    8.30f
#define IMZA_KIMYASAL_PH_STD    0.30f
#define IMZA_KIMYASAL_EC_ORT    2.75f
#define IMZA_KIMYASAL_EC_STD    0.45f
#define IMZA_KIMYASAL_ORP_ORT   310.0f
#define IMZA_KIMYASAL_ORP_STD   40.0f

#define IMZA_BIYOLOJIK_PH_ORT   6.60f
#define IMZA_BIYOLOJIK_PH_STD   0.35f
#define IMZA_BIYOLOJIK_EC_ORT   1.50f
#define IMZA_BIYOLOJIK_EC_STD   0.30f
#define IMZA_BIYOLOJIK_ORP_ORT  175.0f
#define IMZA_BIYOLOJIK_ORP_STD  45.0f

#define IMZA_FIZIKSEL_PH_ORT    7.00f
#define IMZA_FIZIKSEL_PH_STD    0.30f
#define IMZA_FIZIKSEL_EC_ORT    1.15f
#define IMZA_FIZIKSEL_EC_STD    0.20f
#define IMZA_FIZIKSEL_ORP_ORT   350.0f
#define IMZA_FIZIKSEL_ORP_STD   40.0f

// ============================================================================
// 6) ZAMANLAMA SABITLERI (tumu millis() tabanli, non-blocking)
// ============================================================================

#define OKUMA_ARALIGI_MS          5000UL   // Sensor okuma periyodu (5 sn)
#define MQTT_GONDERIM_ARALIGI_MS 10000UL   // MQTT veri yayin periyodu (10 sn)
#define LOG_ARALIGI_MS             5000UL   // SD karta kayit periyodu (5 sn)

// --- Tedavi sureleri (YER TUTUCU -- saha testleriyle ayarlanmali) ---
#define TEDAVI_ASIT_SURESI_MS    30000UL   // Asit dozlama pompasi calisma suresi
#define TEDAVI_KLOR_SURESI_MS    30000UL   // Klor enjeksiyon pompasi calisma suresi
#define TEDAVI_YIKAMA_SURESI_MS  60000UL   // Yuksek basincli yikama suresi
#define DURULAMA_SURESI_MS       45000UL   // Her tedavi sonrasi zorunlu durulama

// --- Besin/takviye dozlama sureleri (Faz 3, YER TUTUCU) ---
#define TEDAVI_BESIN_SIVI_SURESI_MS  30000UL   // 3. sivi pompasi calisma suresi
// Toz: KARISTIRMA (su+toz karisir) tamamlaninca POMPALAMA (ana hatta
// itme) baslar -- iki fazli, bkz. treatment.h _aktuatoruAyarla(TEDAVI_BESIN_TOZ).
#define BESIN_TOZ_KARISTIRMA_SURESI_MS  20000UL   // Karistirici calisma suresi
#define BESIN_TOZ_POMPALAMA_SURESI_MS   20000UL   // Pompa calisma suresi (karistirmadan SONRA)
#define TEDAVI_BESIN_TOZ_SURESI_MS \
  (BESIN_TOZ_KARISTIRMA_SURESI_MS + BESIN_TOZ_POMPALAMA_SURESI_MS)

// --- Uzaktan/sureli sulama (2026-09-24) ---
// Ciftci uygulamadan "X dakika sula" diye baslatabilir (bkz. ana_vana.h
// anaVanayiSureliAc). Yanlislikla/kotu niyetle asiri uzun bir sure
// girilirse (orn. 5000 dakika) bu deger su israfina/kontrolsuz suren bir
// akisa karsi UST SINIR olarak kirpar. Flutter tarafi da AYNI degeri
// kullanir (config/ayarlar_sabitleri.dart) -- kullaniciya girmeden once
// uyari gosterilir, tek kaynak ilkesi.
#define SULAMA_MAKS_SURE_DK      180UL   // 3 saat

// ============================================================================
// 7) MQTT AYARLARI (YER TUTUCU -- gercek broker bilgisiyle degistirilmeli)
// ============================================================================

#define MQTT_BROKER_ADRESI   "test.mosquitto.org"  // Gelistirme/test icin genel broker
#define MQTT_BROKER_PORT     1883
#define MQTT_KULLANICI_ADI   ""     // Broker kimlik dogrulama gerektiriyorsa doldurulur
#define MQTT_SIFRE           ""

// Konu (topic) semasi -- python/aquaguard_mock_yayinci.py ve Flutter uygulamasi
// ile BIREBIR AYNI tutulmalidir (bkz. mqtt_handler.h basindaki JSON sema aciklamasi)
#define MQTT_KONU_VERI        "aquaguard/zone%d/veri"
#define MQTT_KONU_DURUM       "aquaguard/zone%d/durum"

// Operator komut konusu -- SADECE mobil uygulamadan cihaza (cihaz buna
// ABONE olur, yayinlamaz). Manuel mudahale ("belirsiz" durumda operatorun
// tedavi secmesi veya aktif bir tedaviyi erken durdurmasi) icin kullanilir.
// bkz. mqtt_handler.h _komutMesajGeldiginde() ve Flutter tarafinda
// AyarlarSabitleri.komutKonusu() / providers/uygulama_durumu.dart
#define MQTT_KONU_KOMUT       "aquaguard/zone%d/komut"

// Komut sonucu (ACK/NACK) -- CIHAZDAN uygulamaya. Govde:
//   {"komut_id":"...","durum":"tamamlandi"|"reddedildi"}
// Uygulama her komuta "komut_id" ekler; yanit gelmezse 30 sn sonra
// "zaman asimi" gosterir. Flutter: AyarlarSabitleri.komutDurumuKonusu().
#define MQTT_KONU_KOMUT_DURUMU "aquaguard/zone%d/komut_durumu"

// PubSubClient paket siniri (bayt). Varsayilan 256, telemetri JSON'u icin YETERSIZ.
#define MQTT_PAKET_BOYUTU     768

// Donanim watchdog zaman asimi (ms). Ana dongu bu surede ilerlemezse (kilitlenme,
// beklenmedik bloklama) kart YENIDEN BASLATILIR -- yeniden baslatma pompa
// pinlerini LOW yapar (tedaviSistemBaslat), yani hata durumunda kimyasal
// dozlama GUVENLI yone (durma) duser. WiFi.begin() kendisi bloklamaz (arka
// planda baglanir), ama _mqttClient.connect() TCP baglanti kurana kadar
// bekler -- kotu sinyalde birkac saniye surebilir. GSM doneminden kalma
// genis 120 sn'lik marj WiFi ile de guvenli oldugu icin KORUNDU.
#define WATCHDOG_ZAMAN_ASIMI_MS 120000UL

#endif // AQUAGUARD_CONFIG_H
