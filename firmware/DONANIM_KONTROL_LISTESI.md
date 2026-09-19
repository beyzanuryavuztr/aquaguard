# AquaGuard Firmware — Donanım Entegrasyon Kontrol Listesi

Bu liste Enver için hazırlandı: `firmware/` kodu 2026-09-19'da arduino-cli (ESP32 çekirdeği 3.x, genel
`esp32:esp32:esp32` kartı; TinyGSM 0.12, PubSubClient 2.8, ArduinoJson 7.4,
ESP32Servo 3.1, RTClib 2.1) ile DERLENDİ (%31 flash, %7 RAM). Kalan uyarılar: ArduinoJson 7'de
`StaticJsonDocument` kullanımdan kalkma uyarısı (kod v6 API'siyle yazıldı;
v6.21.x sabitlemek uyarıyı kaldırır). Aşağıdaki "MQTT paket boyutu" maddesine bakın.
Bu yalnızca sözdizimi/kütüphane uyumunu doğrular: Deneyap Kart'a özgü kart
tanımıyla derleme, pin doğruluğu ve sensör davranışı gerçek donanımda
ilk kez çalıştırılmadan önce aşağıdaki adımlarla doğrulanmalı.

## 1) Pin Bağlantı Doğrulaması

`firmware/config.h`'deki tüm pin numaraları **yer tutucudur** — gerçek Deneyap
Kart pinout diyagramına ve fiziksel kablolamaya göre doğrulanmalı/gerekirse
güncellenmelidir.

| Bileşen | Pin (config.h) | Not |
|---|---|---|
| pH sensörü | GPIO 34 (ADC1_CH6) | Analog |
| EC sensörü | GPIO 35 (ADC1_CH7) | Analog |
| ORP sensörü | GPIO 32 (ADC1_CH4) | Analog |
| Türbidite sensörü | GPIO 33 (ADC1_CH5) | Analog |
| Basınç sensörü | GPIO 36 (ADC1_CH0 / VP) | Analog |
| Debi sensörü | GPIO 27 | Darbe çıkışlı, kesme (interrupt) destekli pin olmalı |
| Asit dozlama pompası | GPIO 25 | Röle/motor sürücü |
| Klor enjeksiyon pompası | GPIO 26 | Röle/motor sürücü |
| Yüksek basınçlı yıkama valfi | GPIO 14 | Servo (PWM) |
| Ana sulama vanası | GPIO 13 | Röle üzerinden solenoid |
| SD kart (SPI CS) | GPIO 5 | |
| RTC (I2C) | SDA=21, SCL=22 | Deneyap Kart revizyonuna göre değişebilir |
| SIM800L (UART2) | RX=16, TX=17 | |

**Kritik**: analog sensör pinleri **ADC1 kanallarından** seçilmiştir (ADC2,
WiFi aktifken güvenilir çalışmaz) — bu kısıtlama Deneyap Kart'ın hangi
revizyonu kullanıldığında da geçerlidir, pin değiştirilecekse mutlaka ADC1
kanalından seçilmelidir.

## 2) Sensör Kalibrasyonu

Tüm analog sensörler aynı yöntemle kalibre edilir: iki bilinen referans
noktasında ölçülen voltajdan doğrusal (`eğim × voltaj + ofset`) bir formül
türetilir. Referans çözeltiler (Flutter tarafında Ayarlar > Sensör
Kalibrasyonu kartında da gösterilir — tek kaynak, `config/kalibrasyon_sabitleri.dart`):

- **pH**: tampon çözeltiler pH 4.01 / 6.86 / 9.18
- **EC**: referans çözeltiler 1.413 / 12.88 mS/cm
- **ORP**: referans çözeltiler 225 / 475 mV
- **Türbidite**: temiz su (0 NTU) + bilinen bulanıklıkta bir referans

Adımlar:
1. Her sensörü ilgili referans çözeltiye daldırıp gerçek voltaj çıkışını ölçün.
2. `config.h`'deki `*_KALIBRASYON_OFSET`/`*_KALIBRASYON_EGIM` (veya ORP için
   `_OFSET_V`/`_KAZANC`, türbidite için `_TEMIZ_V`/`_EGIM`) sabitlerini bu
   ölçümlere göre güncelleyin.
3. Debi sensörü farklı bir model ise `DEBI_PALS_PER_LITRE` sabitini yeni
   sensörün datasheet değerine göre değiştirin (şu an YF-S201 tipi sensörler
   için yaygın olan 450 darbe/litre varsayılıyor).
4. **Kalibrasyon sabitleri değiştiğinde**, Flutter tarafındaki
   `aquaguard_mobile/lib/config/kalibrasyon_sabitleri.dart` dosyası da AYNI
   değerlerle elle güncellenmelidir (tek kaynak ilkesi — bu iki dosya bayt
   bayt aynı sayıları taşımalı).

## 3) İlk Çalıştırma Duman Testi Sırası

Kod flaşlandıktan sonra, karmaşık senaryolara (otonom tedavi vb.) geçmeden
önce şu sırayla doğrulayın:

1. **Seri port çıktısı**: `Serial.println` mesajlarının (sistem başlatma,
   sensör okuma, teşhis) düzgün göründüğünü doğrulayın.
2. **Ana vana**: MQTT üzerinden `sulama_durdur`/`sulama_baslat` komutlarını
   gönderip vananın fiziksel olarak açılıp kapandığını gözlemleyin.
3. **Sensör okumaları**: yayınlanan MQTT mesajındaki pH/EC/ORP/türbidite/
   debi/basınç değerlerinin, sensörleri bilinen bir referans ortamına
   (örn. musluk suyu) koyduğunuzda makul aralıkta olduğunu doğrulayın.
4. **MQTT bağlantısı**: `aquaguard/zone{N}/durum` konusunda `online`
   mesajının retained olarak göründüğünü, cihaz kapatıldığında (veya
   bağlantı koptuğunda) `offline` LWT mesajının geldiğini doğrulayın.
5. **TEK bir manuel tedavi + mutex kilidi**: mobil uygulamadan (Demo Modu
   KAPALI, gerçek cihaza bağlı) `tedavi_baslat` komutuyla TEK bir tedavi
   tetikleyin, ardından AYNI zon için hemen İKİNCİ bir tedavi denemesi
   gönderin — ikincisinin `"[Komut] Operatör: manuel tedavi REDDEDİLDİ
   (mutex meşgul)."` mesajıyla reddedildiğini seri porttan doğrulayın. Bu,
   projenin tek güvenlik garantisinin (asit/klor asla aynı anda çalışamaz)
   gerçek donanımda da geçerli olduğunun ilk kanıtıdır.

## 4) Bilinen Sınırlamalar / Dikkat Edilmesi Gerekenler

Bu proje boyunca yapılan "acımasız hakem" denetim turlarında firmware
**inceleme yoluyla** (derleme olmadan) düzeltildi. Aşağıdaki değişiklik,
mantığı özellikle dikkatli test edilmesi gereken en yeni ve en karmaşık
düzeltme:

- **Durulama zamanlayıcısı (`treatment.h` → `durulamaZamanlayicisiniSifirla()`,
  2026-09-14)**: ana vana, zorunlu durulama SÜRERKEN kapatılırsa, mutex artık
  ANINDA açılmıyor — durulama süresi vana yeniden açıldığında SIFIRDAN
  sayılmaya başlıyor. **Gerçek donanımda mutlaka test edin**: bir tedaviyi
  tamamlayın (durulama fazına geçsin), durulama sürerken ana vanayı MANUEL
  kapatıp hemen yeniden açın, ardından AYNI zon için yeni bir tedavi
  denemesinin `DURULAMA_SURESI_MS` (45 saniye) dolana kadar REDDEDİLDİĞİNİ
  doğrulayın. Bu senaryo sadece kod incelemesiyle doğrulanabildi, gerçek
  zamanlama davranışı saha testinde teyit edilmeli.

Diğer, düşük öncelikli/bilinen sınırlamalar (değiştirilmedi, riski düşük):
- `sensors.h`'deki `noInterrupts()`/`interrupts()` kesme deseni ESP32
  çift-çekirdek mimarisinde kırılgan olabilir — kısa vadede risk düşük.
- `mqtt_handler.h`'nin her yayında yeni `String` nesnesi oluşturması
  (heap fragmentation riski) — ESP32'nin büyük heap'i sayesinde kısa
  vadede sorun çıkarması olası değil.
- **MQTT paket boyutu (2026-09-19, KRİTİK düzeltme)**: PubSubClient'in varsayılan
  paket sınırı 256 bayttır; telemetri JSON'u (~330 bayt) bunu aşar ve
  `publish()` **her seferinde sessizce başarısız olurdu** (firmware hiç veri
  göndermezdi). `mqttBaslat()` artık `setBufferSize(MQTT_PAKET_BOYUTU=768)`
  çağırıyor. Seri portta "[MQTT] UYARI: tampon boyutu ayarlanamadi" görürseniz
  bellek yetersizdir.
- **Komut ACK/NACK (sema v2) -- 2026-09-19'da firmware'e EKLENDİ**: her komuta
  eklenen `komut_id` okunur, sonuç `aquaguard/zone{N}/komut_durumu` konusuna
  `{"komut_id","durum":"tamamlandi"|"reddedildi"}` olarak yayınlanır (Python
  mock ile aynı sözleşme). Ana vana durumu da telemetriyle (`ana_vana_acik`)
  raporlanır. **Gerçek donanımda henüz denenmedi** -- ilk testte bir komut
  gönderip uygulamada "Uygulandı"/"REDDEDİLDİ" (zaman aşımı DEĞİL) çıktığını
  doğrulayın.

## Kaynak / Tek Kaynak Referansları

- Karar eşikleri ve sensör imzaları: `PROJE_BRIEF.md` §4.2/§6,
  `firmware/config.h` §5, `python/aquaguard_karar_motoru.py`,
  `aquaguard_mobile/lib/config/sensor_imzalari.dart` — dördü de birebir aynı
  sayıları taşımalı.
- MQTT JSON şeması: `firmware/mqtt_handler.h` dosya başı yorumu,
  `python/aquaguard_mock_yayinci.py`, `aquaguard_mobile/lib/models/sensor_okuma.dart`.
