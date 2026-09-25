# AquaGuard Firmware — Donanım Entegrasyon Kontrol Listesi

## 🔴 2026-09-25 BÜYÜK GÜNCELLEME — Enver'in pin notu + kart fotoğrafı analiz edildi

Enver elle yazılmış bir pin ataması notu ve kartın fotoğrafını gönderdi. Bu,
projenin başından beri süregelen İKİ büyük varsayımı çürüttü:

1. **Kart modeli artık KESİN**: Deneyap Kart 1A v2 (ESP32-**S3** tabanlı,
   klasik ESP32 DEĞİL). Bu ortamda kurulu board paketlerinin `pins_arduino.h`
   dosyaları karşılaştırılarak doğrulandı — Enver'in notundaki A0-A7 (8 analog
   kanal) + D12/D13, SADECE bu varyantta mevcut. Eski pin numaraları
   (GPIO32-39) klasik ESP32 için seçilmişti; S3'te bu numaralar flash/PSRAM'e
   ayrılmış olabilir (gerçek fiziksel risk, sadece "yanlış okuma" değil).
2. **Mimari düzeltmesi**: önceki kod "4 ayrı Deneyap Kart, her biri kendi
   zonunu izliyor, MQTT ile koordine oluyor" varsayıyordu. **Kullanıcıdan
   DOĞRULANDI**: gerçekte **TEK kart 4 zonu DOĞRUDAN yönetiyor** (4 vana aynı
   kartta), sensörler de zon-bazlı DEĞİL — TEK ortak set, vana sırayla açılıp
   o zonun suyu okunuyor.

Firmware bu iki bulguya göre **tamamen yeniden yazıldı** (`config.h`,
`ana_vana.h`, `treatment.h`, `mqtt_handler.h`, `aquaguard_main.ino`,
`logger.h`, `sensors.h`). Artık `esp32:esp32:deneyapkart1Av2` hedefine göre
derleniyor (%77 flash, %15 RAM) — önceki gibi jenerik `esp32:esp32:esp32`
DEĞİL, gerçek kart tanımına karşı derlenen İLK sürüm bu.

### 🟡 Hâlâ Enver'e sorulması gereken, TAHMİN EDİLMEYEN sorular

Kod bu sorular cevaplanmadan **gerçek donanıma flaşlanmamalı**. Her biri
`config.h`'de derleme sırasında görünen bir `#warning` ile işaretli:

1. **Debi ve basınç sensör pinleri notta YOK** — bunlar tıkanma tespitinin
   ASIL sinyali (aşağıdaki §6/PROJE_BRIEF). `config.h`'de D4/A8 GEÇİCİ
   olarak atandı (Deneyap'ın güvenli/genel-amaçlı pinleri, eski
   klasik-ESP32 numaraları BİLEREK kullanılmadı) — gerçek pin Enver'den
   gelmeden bu değerlere güvenmeyin.
2. **ORP sensörü için bu kartta fiziksel olarak boş analog pin KALMADI**
   (A0-A8 = 9 kanal, 4 sensör + 4 vana + geçici basınç ataması ile tamamen
   dolu). Ya harici bir ADC genişletici gerekiyor (fotoğraftaki PWM/I2C
   kartı PWM ÇIKIŞI için, ADC GİRİŞİ değil — ayrıca doğrulanmalı) ya da bu
   prototipte ORP yok. `orpOku()` şu an sabit bir nötr değer döndürüyor
   (bkz. `sensors.h`) — gerçek okuma DEĞİL.
3. **4 "pompa" pininin (D0-D3) hangi kimyasala gittiği notta belirtilmemiş**
   — `config.h`'deki asit/klor/besin-sıvı/yıkama eşlemesi **UZMAN
   TAHMİNİDİR**, doğrulanmadan güvenilmemeli.
4. **Toz dozlama (karıştırıcı + pompa) için hiç pin kalmadı** — D0-D3
   diğer 4 aktüatör tarafından tüketildi. Fotoğraftaki genişletme kartı
   muhtemelen çözüm. **Bu doğrulanana kadar toz dozlama firmware'de
   BİLEREK REDDEDİLİYOR** (`treatment.h` `tedaviBaslat()` — pin çakışması
   riski nedeniyle).
5. **SIM800L hâlâ kartta fiziksel olarak takılı** (D12/D13 = Rx/Tx, notta
   yazılı) — WiFi'ye geçişe rağmen kullanılacak mı, yoksa sökülecek mi
   belirsiz. Firmware WiFi kullanıyor, SIM800L'e HİÇ dokunmuyor.
6. **Sıcaklık sensörü (A0) gerçekten kullanılacak mı** yoksa boşta duran
   bir pin mi? Firmware artık ham voltajını okuyup yayınlıyor
   (`sicaklik_ham_voltaj`, KALİBRE EDİLMEDİ, santigrat DEĞİL) ama
   pH/EC teşhisine KATMIYOR — bu, projenin daha önce "sıcaklık sensörü
   yok" kararıyla çelişiyor, netleştirilmeli.

**2026-09-23 mimari değişikliği (hâlâ geçerli)**: İletişim SIM800L/GSM'den
WiFi'ye taşındı. **Önemli kısıt**: WiFi menzili sınırlıdır (yönlendiriciden
birkaç on metre).

## 1) Pin Bağlantı Doğrulaması

`firmware/config.h`'deki pin isimleri artık **Deneyap Kart 1A v2'nin kendi
sembolik isimleri** (`D0`, `A4` gibi) — ham GPIO numarası değil, board paketi
doğru GPIO'ya kendisi çevirir. Aşağıdaki tablo Enver'in notundan DOĞRUDAN
alınanları ✅, hâlâ tahmin/belirsiz olanları 🟡 ile işaretler.

| Bileşen | Pin (config.h) | Durum |
|---|---|---|
| Sıcaklık sensörü | `A0` | ✅ Enver'in notundan, ama kullanımı §6 sorusu |
| Türbidite (bulanıklık) sensörü | `A1` | ✅ Enver'in notundan |
| EC (iletkenlik) sensörü | `A3` | ✅ Enver'in notundan |
| pH sensörü | `A4` | ✅ Enver'in notundan |
| Zon 1 vanası | `A5` | ✅ Enver'in notundan |
| Zon 2 vanası | `A6` | ✅ Enver'in notundan |
| Zon 3 vanası | `A7` | ✅ Enver'in notundan |
| Zon 4 vanası | `A2` | ✅ Enver'in notundan |
| Asit dozlama pompası | `D0` | 🟡 UZMAN TAHMİNİ — hangi pompa D0-D3'ten hangisi belirsiz |
| Klor enjeksiyon pompası | `D1` | 🟡 UZMAN TAHMİNİ |
| Besin sıvı dozlama pompası | `D2` | 🟡 UZMAN TAHMİNİ |
| Yüksek basınçlı yıkama valfi (servo) | `D3` | 🟡 UZMAN TAHMİNİ |
| Debi sensörü | `D4` | 🟡 GEÇİCİ — notta yok, kesme destekli pin gerekir |
| Basınç sensörü | `A8` | 🟡 GEÇİCİ — notta yok, kartta kalan tek boş analog kanal |
| ORP sensörü | *(tanımsız)* | 🔴 Bu kartta boş analog pin kalmadı, bkz. §🟡2 |
| Toz karıştırıcı motoru | `D3` (ÇAKIŞMA) | 🔴 Pin yok, `treatment.h` bu tedaviyi REDDEDİYOR |
| Toz pompası | `D3` (ÇAKIŞMA) | 🔴 Pin yok, `treatment.h` bu tedaviyi REDDEDİYOR |
| SD kart (SPI CS) | `SDCS` (kartın kendi sembolü) | ✅ |
| RTC (I2C) | `SDA`/`SCL` (kartın kendi sembolleri) | ✅ |
| WiFi | dahili radyo, ek pin yok | ✅ SSID/şifre `config.h` `WIFI_SSID`/`WIFI_SIFRE` |
| SIM800L Rx/Tx (KULLANILMIYOR) | `D12`/`D13` | Bilgi amaçlı, koddan referans edilmiyor |

**Derleme hedefi artık `esp32:esp32:deneyapkart1Av2`** (önceden jenerik
`esp32:esp32:esp32`) — ADC1/ADC2 ayrımı ESP32-S3'te klasik ESP32'den
FARKLI çalışır, yukarıdaki pinlerin hepsi zaten ADC1 aralığında (GPIO1-10)
seçildi.

## 1b) Gerilim Bölücü (ADC 3,3 V sınırı) — KRİTİK

ESP32 ADC pini **en fazla 3,3 V** okur. Basınç transduseri (0,5–4,5 V) ve
türbidite modülü (~4,2 V) bunu aşar; bu iki sensörün çıkışı ile ADC pini
arasına iki dirençli gerilim bölücü konmalıdır (örn. üst 10 kΩ / alt 20 kΩ →
oran 0,6667). `config.h`'deki `*_BOLUCU_ORANI` değerleri firmware'e bu oranı
söyler; yanlış/eksik ayar **derleme hatası** verir (`sensors.h`
static_assert) — böylece 4,5 V'luk çıkış bölücüsüz bağlanacak bir yapılandırma
derlenemez. pH/EC/ORP modülleri genelde ≤ 3 V verir (oran 1,0); **modül
datasheet'inden doğrulayın**. Kalibrasyon sabitleri SENSÖR tarafı voltajla
tanımlıdır (firmware bölücüyü geri alır).

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

0. **WiFi bilgilerini girin**: `config.h`'deki `WIFI_SSID`/`WIFI_SIFRE` hâlâ
   yer tutucu metinse ("AGINIZI_BURAYA_YAZIN") kart hiçbir ağa bağlanamaz.
   Flaşlamadan önce gerçek ağ adı/şifresiyle değiştirin.
1. **Seri port çıktısı**: `Serial.println` mesajlarının (sistem başlatma,
   sensör okuma, teşhis) düzgün göründüğünü doğrulayın.
2. **Zon vanaları (4 tanesi)**: MQTT üzerinden her zon için ayrı ayrı
   `sulama_durdur`/`sulama_baslat` (`aquaguard/zone{N}/komut`) komutlarını
   gönderip İLGİLİ vananın fiziksel olarak açılıp kapandığını, DİĞER 3
   vananın ETKİLENMEDİĞİNİ gözlemleyin.
3. **Sensör okumaları + zon isolasyonu**: SADECE bir zonun vanasını açıp
   diğerlerini kapatarak, yayınlanan MQTT mesajındaki pH/EC/turbidite
   değerlerinin makul aralıkta olduğunu doğrulayın. Ardından birden fazla
   zonu AYNI ANDA açıp paylaşımlı sensörün ne okuduğunu gözlemleyin (bkz.
   `aquaguard_main.ino` dosya başı notu — bu durumda okuma hangi zona
   ait olduğu belirsizleşir, sahada tek-seferde-tek-zon sulama ÖNERİLİR).
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

- **Watchdog + bağlanma ertelemesi (2026-09-19, WiFi'ye taşındı 2026-09-23)**:
  `WiFi.begin()` bloklamaz (arka planda bağlanır), ama PubSubClient `connect()`
  TCP bağlantısı kurulana kadar **bekler**. Bir pompa çalışırken bu, tedavi
  süresini aşırabilirdi; artık aktif tedavi sürerken yeniden bağlanma
  **ertelenir** (bu sürede veri yayını kesilir). Ayrıca 120 sn'lik donanım
  watchdog'u ana döngü kilitlenirse kartı yeniden başlatır (yeniden başlatma
  pompa pinlerini LOW yapar). Watchdog API'si çekirdek 3.x için derlendi;
  Deneyap Kart paketi 2.x çekirdek kullanıyorsa `#else` yolu **derlenmedi** —
  ilk derlemede kontrol edin.

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
- **Süreli sulama (sema v3) -- 2026-09-24'te firmware'e EKLENDİ**:
  `sulama_baslat` komutu artık opsiyonel `sure_dakika` alanı taşıyabilir
  (`config.h` `SULAMA_MAKS_SURE_DK=180` ile kırpılır). Verilirse vana o süre
  sonunda **kartın kendisi** tarafından (telefon değil) kapatılır --
  `ana_vana.h` `anaVanaZamanlayiciyiGuncelle()`, `loop()` içinde her turda
  çağrılır. Kalan süre `sulama_kalan_saniye` alanıyla yayınlanır. **Gerçek
  donanımda henüz denenmedi** -- ilk testte kısa bir süre (örn. 1 dakika)
  ile sulama başlatıp vananın gerçekten kendiliğinden kapandığını, bu sırada
  ana döngünün (sensör okuma vb.) kilitlenmediğini doğrulayın.
- **Zon-bazlı dozlama izolasyonu — 2026-09-25'te YEREL mimariye BASİTLEŞTİRİLDİ**
  (dozlama pompaları **ortak** ana hatta enjekte ediyor, fiziksel olarak
  doğrulanmalı): bir zon otonom veya manuel olarak bir tedavi başlattığında,
  kart diğer tüm zonların vanasını **doğrudan `digitalWrite` ile** kapatır
  (`ana_vana.h` `digerZonlarinVanasiniAyarla`) — TEK kart tüm 4 vanayı
  yönettiği için (bkz. bu dosyanın başındaki büyük mimari düzeltmesi) artık
  MQTT üzerinden başka cihazlara komut yayınlamaya GEREK YOK, önceki "ateş
  et ve devam et" ağ riski TAMAMEN ORTADAN KALKTI. Tedavi+durulama tamamen
  bitince aynı şekilde yerel olarak geri açılır. `treatment.h`'de HANGİ
  zonun tedavi gördüğü `tedaviZonuGetir()` ile takip edilir.
- **Besin/takviye dozlama (Faz 3, sıvı) — çalışıyor**: tıkanma teşhisinden
  BAĞIMSIZ, operatörün `tedavi_baslat` komutuyla `tedavi_turu:"besin_sivi"`
  göndererek istediği zaman başlatabildiği bir dozlama, aynı mutex+izolasyona
  tabidir. **Toz dozlama (`"besin_toz"`) 2026-09-25'ten itibaren firmware
  tarafından BİLEREK REDDEDİLİYOR** — karıştırıcı/pompa pinleri (D3) yıkama
  valfiyle çakışıyor (bkz. bu dosyanın başı, §🟡4). Enver genişletme kartı
  (fotoğrafta görülen PWM/I2C kartı) veya başka bir pin çözümü sağlayınca
  `treatment.h`'deki ret kuralı kaldırılıp gerçek pinler `config.h`'ye
  girilmeli.

## Kaynak / Tek Kaynak Referansları

- Karar eşikleri ve sensör imzaları: `PROJE_BRIEF.md` §4.2/§6,
  `firmware/config.h` §5, `python/aquaguard_karar_motoru.py`,
  `aquaguard_mobile/lib/config/sensor_imzalari.dart` — dördü de birebir aynı
  sayıları taşımalı.
- MQTT JSON şeması: `firmware/mqtt_handler.h` dosya başı yorumu,
  `python/aquaguard_mock_yayinci.py`, `aquaguard_mobile/lib/models/sensor_okuma.dart`.
  **Bilinen tek sapma (2026-09-25):** firmware artık opsiyonel
  `sicaklik_ham_voltaj` alanını yayınlıyor, Python mock ve Flutter modeli
  HENÜZ bunu bilmiyor (kasıtlı — sensör kalibre değil/amacı belirsiz,
  tüm UI'ya taşımak erken). Zararsız (bilinmeyen alan yoksayılır) ama
  sensörün gerçekliği netleşince üç tarafa da eklenmelidir.
