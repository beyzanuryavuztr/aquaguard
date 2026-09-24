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
 * ONEMLI - SAHA KALIBRASYONU GEREKLI:
 *   Bu dosyadaki PIN numaralari, Deneyap Kart'in ADC1 kanallarina (GPIO 32-39)
 *   ve genel amacli dijital pinlerine gore YER TUTUCU olarak secilmistir.
 *   Enver, gercek Deneyap Kart pinout diyagrami ve fiziksel kablo baglantisina
 *   gore bu pin numaralarini DOGRULAMALI/GUNCELLEMELIDIR.
 *
 *   Sensor kalibrasyon sabitleri (EGIM/OFSET) de yer tutucudur. Gercek
 *   degerler, standart kalibrasyon cozeltileriyle (pH 4.01/6.86/9.18 tampon,
 *   EC 1.413/12.88 mS/cm, ORP 225/475 mV) saha kalibrasyonu yapildiktan
 *   sonra buraya girilmelidir. Karar esikleri (§KARAR ESIKLERI) ise
 *   python/aquaguard_karar_motoru.py ile BIREBIR AYNI tutulmalidir -- o
 *   dosyada bir esik degisirse burasi da guncellenmelidir.
 *
 * Kaynaklar:
 *   - Karar esikleri ve sensor imzalari: PROJE_BRIEF.md SS4.2 / SS6
 *   - Debi sensoru kalibrasyon orani: YF-S201 tipi hall-effect debi
 *     sensorlerinin yaygin datasheet degeri (7.5 Hz / (L/dak) => 450 pals/litre)
 *
 * Tarih:  2026-09-01
 * Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
 */

#ifndef AQUAGUARD_CONFIG_H
#define AQUAGUARD_CONFIG_H

// ============================================================================
// 1) BOLGE / CIHAZ KIMLIGI
// ============================================================================

#define BOLGE_ID 1                  // Bu Deneyap Kart'in izledigi zon numarasi
#define CIHAZ_ADI "AquaGuard-Zone1" // MQTT client-id ve loglarda kullanilir

// Sistemdeki TOPLAM zon sayisi (1..TOPLAM_ZON_SAYISI numaralandirilir).
// Zon-bazli dozlama izolasyonu icin gerekli (bkz. mqtt_handler.h
// "digerZonlarinVanasiniAyarla" -- ekip karari 2026-09-25: dozlama
// pompalari ORTAK ana hatta enjekte ediyor, zon vanalari damlama
// hatlarini ayiriyor. Bir zona dozlama yapilirken DIGER zonlarin
// vanalari GECICI kapatilir, aksi halde ilac paylasimli hatta karisip
// TUM zonlara gider).
#define TOPLAM_ZON_SAYISI 4

// ============================================================================
// 2) PIN TANIMLARI (YER TUTUCU -- Enver dogrulamali)
// ============================================================================

// --- Analog sensorler (ESP32 ADC1 kanallari, WiFi/BT ile catismaz) ---
#define PIN_PH_SENSOR         34   // ADC1_CH6
#define PIN_EC_SENSOR         35   // ADC1_CH7
#define PIN_ORP_SENSOR        32   // ADC1_CH4
#define PIN_TURBIDITE_SENSOR  33   // ADC1_CH5
#define PIN_BASINC_SENSOR     36   // ADC1_CH0 (VP)

// --- Debi sensoru (darbe cikisli, kesme/interrupt destekli pin) ---
#define PIN_DEBI_SENSOR       27

// --- Tedavi aktuatorleri ---
#define PIN_POMPA_ASIT        25   // Asit dozlama pompasi (DC motor surucu/role)
#define PIN_POMPA_KLOR        26   // Klor enjeksiyon pompasi (DC motor surucu/role)
#define PIN_SERVO_YIKAMA      14   // Yuksek basincli yikama valfi (servo motor, PWM)

// --- Ana sulama vanasi (operator MQTT komutuyla acar/kapatir -- bkz.
//     mqtt_handler.h "sulama_durdur"/"sulama_baslat", TEDAVI aktuatorlerinden
//     BAGIMSIZ: zonun butun sulamasini keser, tedavi/teshis akisiyla ilgisi
//     yoktur, sahada sizinti supheci/bakim gibi durumlar icindir) ---
#define PIN_ANA_VANA          13   // Role uzerinden ana su hatti solenoidi

// --- SD kart (SPI) ---
#define PIN_SD_CS              5

// --- RTC modulu I2C uzerinden calisir: varsayilan Wire pinleri (SDA=21, SCL=22)
//     Deneyap Kart revizyonuna gore farkli olabilir, Wire.begin() cagrisinda
//     ozel pin verilmek istenirse burada tanimlanabilir.
#define PIN_I2C_SDA            21
#define PIN_I2C_SCL            22

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
