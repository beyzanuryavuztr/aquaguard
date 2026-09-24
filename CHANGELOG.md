# Değişiklik Günlüğü

Bu dosya, AquaGuard projesindeki önemli değişiklikleri belgeler. Biçim
[Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) ilkelerine dayanır.

## [0.9.0-beta.1] - 2026-09-18

İlk beta sürümü — final öncesi kod dondurma noktası. Proje henüz
`1.0.0` (üretim) sürümü değil.

### Eklenenler — Çekirdek Sistem

- Çok katmanlı otonom tıkanma teşhis/tedavi mantığı (Katman 1: kural
  bazlı hızlı teşhis, Katman 2: makine öğrenmesi modeli), açıklanabilirlik
  paneli ile birlikte.
- MQTT üzerinden gerçek zamanlı sensör veri akışı (pH, EC, ORP, türbidite,
  debi, diferansiyel basınç), şema v2: komut ACK/NACK, hazne seviyesi
  alanları (donanım henüz yayınlamıyor, altyapı hazır).
- Demo Modu: gerçek donanım olmadan uygulama-içi simülasyon servisi,
  ayarlanabilir hız, tek dokunuşla senaryo tetikleme (sağlıklı/kimyasal/
  biyolojik/fiziksel tıkanma/mutex kilidi gösterimi).
- Operatör manuel müdahale paneli: "Hızlı Eylemler" ile sağlıklı bir zonda
  bile asit/klor/yıkama elle başlatma (onay + 3 sn kimyasal geri sayımı +
  mutex kilidi), belirsiz teşhiste manuel tedavi seçimi, aktif tedaviyi
  erken durdurma, yanlış alarm işaretleme, ana vana
  aç/kapat, acil durdurma (tüm zonlar).

### Eklenenler — Ekranlar ve Kullanıcı Deneyimi

- Genel Bakış (dashboard), Zon Detay/Tıkanma Detay, Tedavi Geçmişi
  (CSV/PDF dışa aktarım), Trend Analizi, Aktivite/Bildirim Geçmişi,
  Ayarlar, Tarla Seçim/Profil/Notlar, Onboarding turu, Giriş ekranı,
  Jüri Sunum Modu, İş Fizibilitesi, Model Performansı, Hakkında.
- Koyu/Açık/Sistem tema desteği, aksan rengi seçimi (teal/toprak), Saha
  Modu (güneş altında okunabilirlik için kontrast artırımı).
  Renk körlüğü uyumlu durum paleti (Ayarlar > Görünüm).
- Bağlamsal yardım butonları, sensör gauge göstergeleri, sistem sağlığı
  göstergesi, zon şeması.
- Tarla GPS konumu ve harita (flutter_map/OpenStreetMap, API anahtarı
  gerektirmez), maliyet takip modülü, istatistiksel trend tahmini
  (lineer regresyon, "tahmin değildir" notuyla).
- Bildirim sistemi: 4 kategorili tercih, öncelik seviyeleri, sessiz
  saatler (kritik hariç), PIN koruması (biyometrik kısayol dahil).
- i18n altyapısı: ARB tabanlı, Ayarlar > Görünüm bölümünde TR/EN pilot
  (tam uygulama geneli migrasyon henüz tamamlanmadı — bkz. Bilinen
  Sınırlamalar).

### Eklenenler — Mimari ve Altyapı

- "God Object" `UygulamaDurumu` provider'ı 6 odaklı alt provider'a
  bölündü (Ayarlar, Tarla, Güvenlik, Bakım, Aktivite/Bildirim, Cihaz
  İletişim). Tüm ekranlar ve widget'lar artık yalnızca ihtiyaç duydukları
  alt provider'ı izliyor; `UygulamaDurumu` yalnızca yaşam döngüsünü
  yöneten kompozisyon kökü olarak kalıyor. Kök `MaterialApp` artık her
  sensör okumasında değil, sadece tema/dil/yazı boyutu değişince yeniden
  çiziliyor. Ayarlar ekranı 11 bağımsız bölüm widget'ına bölündü.
- Repository pattern ile depolama katmanı soyutlandı; SharedPreferences
  yerine SQLite'a (drift) geçildi — sensör geçmişi, aktivite/bildirim
  geçmişi ve tarla notları artık pratik bir üst sınırı olmayan (10.000
  kayıt / 7 gün, hangisi önce dolarsa) bir veritabanında tutuluyor.
  Web dahil tüm platformlarda gerçek SQLite (sqlite3.wasm + Web Worker).
  Mevcut kullanıcı verisi tek seferlik, güvenli bir migrasyon adımıyla
  taşınıyor.
- Global hata yakalama (`runZonedGuarded` + `FlutterError.onError`) ve
  cihaz-yerel hata günlüğü (üçüncü parti bir servise gönderilmez).
- CI/CD: GitHub Actions üzerinde `flutter analyze --fatal-infos`,
  `flutter test --coverage`, `flutter build web --release`; Python
  katmanı için ayrı `pytest` işi.
- Test paketi: 409 Flutter testi + Python `pytest` paketi.

### Veri Bütünlüğü (2026-09-19 denetimi)

- **Demo ve gerçek veri artık AYRI veritabanlarında.** Önceden uygulama, modu ne
  olursa olsun ilk açılışta 12 günlük sentetik geçmiş üretip kalıcı yazıyordu;
  gerçek moddaki kullanıcı sahte tıkanma/tedavi/istatistikle karışık veri
  görürdü. Artık sentetik veri yalnızca Demo Modu'nda üretilir ve gerçek veriye
  karışmaz. **Not:** bu sürümden önce oluşmuş veritabanı "gerçek" depo sayılır;
  o depoda eski karışık veri olabilir (beta öncesi kurulumlarda uygulama
  verisini temizleyin).
- Sensör geçmişi dakikada bir kayıt (durum değişimleri anında) ile 7 gün
  saklanır; bellekteki geçmişin ilk canlı okumada 100 kayda kırpılması hatası
  giderildi. Kullanılamayan "30g" seçenekleri kaldırıldı.
- "Tıkanma olayı" dağılımı artık ardışık tespit okumalarını TEK olay sayar.
- Ana vana durumu cihazdan raporlanır (`ana_vana_acik`), acil durdurma
  iletilemeyen komutları açıkça bildirir, komut onayı (ACK) firmware'de var.

### Güvenlik

- MQTT kullanıcı adı/parola desteği: parola cihazın güvenli deposunda saklanır,
  arayüzde geri gösterilmez; TLS kapalıyken uyarı gösterilir.
- PIN oturum zaman aşımı: uygulama 5 dakikadan uzun arka planda kalırsa PIN
  ekranı yeniden mevcut ekranın üstüne biner.
- Kimyasal dozlama (asit/klor) başlatma onayına, yanlışlıkla dokunmayı
  zorlaştıran 3 saniyelik geri sayım eklendi.
- MQTT bağlantısı için opsiyonel TLS desteği (varsayılan halen düz
  bağlantı — bkz. Bilinen Sınırlamalar).

- Broker adresi genel test broker'ıysa ve web + https + TLS kapalıysa
  Ayarlar'da uyarı gösterilir. Android release için `android/key.properties`
  ile imza, `POST_NOTIFICATIONS`/`USE_BIOMETRIC` izinleri eklendi (Android SDK
  bulunmadığından derlenerek doğrulanmadı). Firmware için CI derleme işi eklendi.
- Model Performansı ekranındaki doğruluk standart sapması güncel yeniden
  eğitim çıktısıyla eşitlendi (%89.9 ± %1.5).

### İletişim Mimarisi (2026-09-23)

- Firmware iletişimi **SIM800L/GSM'den WiFi'ye taşındı** (ekip kararı —
  sunum/fuar ortamında WiFi, SIM kapsama alanından daha güvenilir).
  `mqtt_handler.h` artık TinyGSM yerine ESP32'nin dahili WiFi kütüphanesini
  kullanıyor; `config.h`'de `GSM_APN`/`SIM800L_*` yerine `WIFI_SSID`/
  `WIFI_SIFRE` var. Genel ESP32 kartıyla arduino-cli ile yeniden derlendi
  (%78 flash, %15 RAM — WiFi/TLS yığını TinyGSM'den daha büyük yer kaplıyor).
  **Bilinçli ödünleşim:** WiFi menzili sınırlıdır (yönlendiriciden birkaç on
  metre); GSM'in "her yerde çeker" garantisi kayboldu — gerçek sahada WiFi
  kapsaması olmayan bir tarlada sistem bağlanamaz.
- Uygulamadaki simüle "GSM sinyal" göstergesi (`EnerjiGostergesi`,
  gerçek telemetri değil) tutarlılık için "WiFi sinyal" olarak yeniden
  adlandırıldı.

### Uzaktan/Süreli Sulama (2026-09-24) — sema v3

- Yeni **"Uzaktan Sulama"** ekranı (Genel Bakış'taki damla ikonu): çiftçi
  bir çiftlik + bir veya birden fazla zon seçip, kaç dakika sulama
  yapılacağını girip tek dokunuşla başlatabiliyor.
- `sulama_baslat` MQTT komutu artık opsiyonel `sure_dakika` alanı taşıyor.
  Zamanlayıcı **kartın kendisinde** çalışıyor (telefonda değil) — uygulama
  kapansa/bağlantı kesilse bile vana süresi dolunca kendiliğinden kapanıyor.
  Üst sınır (`SULAMA_MAKS_SURE_DK`/`sulamaMaksSureDakika` = 180 dakika)
  firmware/Python/Dart'ta aynı değerle kırpılıyor (tek kaynak ilkesi).
  Kalan süre `sulama_kalan_saniye` alanıyla yayınlanıyor.
  Bu sulama sürerken bir tıkanma tespit edilirse otonom teşhis/tedavi
  değişmeden çalışmaya devam ediyor (ek bir entegrasyon gerekmedi).
- **Bilinçli kapsam sınırı:** bu ekran, tıkanma teşhisinden bağımsız,
  operatörün kendi kararıyla tetiklediği bir sulama başlatma aracıdır —
  "hangi zonun ilaç haznesinin diğer zonlardan izole edilmesi" gibi
  çok-zonlu dozlama güvenlik sıralaması ve bitki besleme/gübreleme dozlama
  özelliği (ayrı sıvı/toz hazneleri) **ayrı, sonraki fazlarda** ele alınacak
  — bu sürümde henüz yok.

### Zon-Bazlı Dozlama İzolasyonu (2026-09-25) — Faz 2

- Ekip kararı: dozlama pompaları (asit/klor/vb.) **ortak** bir ana hatta
  enjekte ediyor, her zonun kendi damlama hattı başındaki bir vana suyun/
  ilacın o zona gidip gitmeyeceğini belirliyor. Bu yüzden bir zon tedavi
  (asit/klor/yıkama) başlattığında — otonom teşhisle ya da operatörün
  manuel komutuyla — firmware artık önce **diğer tüm zonların** vanasını
  geçici kapatıyor (mevcut zon-bazlı `sulama_durdur`/`sulama_baslat`
  komutları yeniden kullanılıyor), tedavi+durulama tamamen bitince geri
  açıyor. Acil durdurma bu akışı atladığı için, iki güvenlik çağrı
  noktasında da diğer zonları elle geri açma eklendi.
  **Sadece firmware'de** — arduino-cli ile derlendi, gerçek donanımda
  henüz denenmedi. Bilinçli/dokümante edilmiş sınırlamalar için bkz.
  `firmware/DONANIM_KONTROL_LISTESI.md`.

### Besin/Takviye Dozlama (2026-09-25) — Faz 3

- Yeni **"Besin Takviyesi"** ekranı (Genel Bakış'ın "⋮" menüsünde, Uzaktan
  Sulama'nın yanında): tıkanma tedavisinden tamamen bağımsız, operatörün
  kendi kararıyla (örn. ziraat mühendisinin önerdiği bir takviye) bir sıvı
  veya toz maddeyi sulama suyuna katmasını sağlar. Çiftlik + hedef zon(lar)
  seçilir, "Sıvı" veya "Toz Takviye Başlat" ile tetiklenir — süre sabittir.
- Yeni iki `TedaviTuru`: `besinSivi`, `besinToz` — asit/klor/yıkama ile
  **aynı güvenlik kilidine (mutex) ve zon-izolasyonuna** tabidir, hiçbir
  zaman otonom tetiklenmez (`tedaviTuruBelirle` bunları asla döndürmez).
  Mevcut `tedavi_baslat` MQTT komutu yeniden kullanıldı — yeni bir komut
  eklenmedi.
- **Açıkça işaretlenmiş varsayım:** toz karışımının ana hatta nasıl
  itildiği (ayrı bir pompa mı, yoksa başka bir mekanizma mı) donanım henüz
  netleşmediği için **bilinmiyor** — kod "önce karıştır (20 sn), sonra ayrı
  bir pompayla it (20 sn)" varsayımıyla yazıldı, projenin mevcut "yer
  tutucu pin" disipliniyle tutarlı şekilde `DONANIM_KONTROL_LISTESI.md`'de
  büyük harflerle işaretlendi. Gerçek mekanizma farklıysa `treatment.h`
  güncellenmeli.
- Python mock ve Flutter tarafında da (demo modu dahil) aynı iki tedavi
  türü desteklendi — 54 Python testi, 440 Flutter testi geçiyor.

### Bilinen Sınırlamalar

- Sıcaklık sensörü yok; pH/EC ölçümlerinde sıcaklık telafisi yapılmaz.

- MQTT varsayılan olarak genel test broker'ı (`test.mosquitto.org`)
  üzerinden düz TCP ile çalışır. Kimlik doğrulama desteklenir ama varsayılan
  kapalıdır; üretimde kendi TLS+kimlik doğrulamalı broker'ınızı kullanın.
- i18n sadece Ayarlar > Görünüm bölümünde etkin; uygulamanın geri
  kalanı sabit Türkçe metin içerir.
- Firmware (`firmware/`) genel ESP32 kartı için uyarısız derleniyor
  (arduino-cli), ancak Deneyap Kart tanımıyla derlenmedi ve gerçek
  donanımda hiç çalıştırılmadı; pinler ve kalibrasyon sabitleri yer tutucudur.
- Erişilebilirlik: ana durum/sensör/kontrol widget'larında ekran okuyucu
  etiketleri var; uygulamanın tamamı henüz taranmadı.
- README'deki ekran görüntüleri bölümü henüz gerçek görsellerle
  doldurulmadı (`docs/screenshots/` — manuel olarak eklenecek).
