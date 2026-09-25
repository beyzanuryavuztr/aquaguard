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

### Acımasız Denetim — Faz 1-3 üzerinde bulunan 3 gerçek hata (2026-09-25)

Faz 1-3'ü teslim ettikten hemen sonra istenen ek bir "acımasızca incele"
turunda, kendi yazdığım koda karşı üç gerçek (küçük ama gerçek) hata
bulundu ve düzeltildi:

- **Süreli sulamada yanıltıcı başarı mesajı:** kullanıcı 180 dakika üst
  sınırından fazla bir süre girdiğinde (örn. 500), provider/firmware bunu
  sessizce 180'e kırpıyordu ama ekran hâlâ "500 dakikalık sulama
  başlatıldı" diyordu — kullanıcı gerçekte ne kadar süreceğini yanlış
  bilirdi. Artık ekran gerçekte çalışacak (kırpılmış) süreyi gösteriyor ve
  kırpma olduysa bunu açıkça belirtiyor.
- **Python mock'ta besin dozlaması erken durdurulunca sahte sensör kayması:**
  `tedavi_durdur` komutu, besin dozlaması sürerken gelirse en son GERÇEK
  tıkanma türünü (`guncel_tur`, besin dozlamayla hiç güncellenmeyen bir
  alan) kullanıp durulama fazında var olmayan bir kimyasal/biyolojik/
  fiziksel kaymaya doğru interpolasyon yapıyordu. Artık besin dozlaması
  doğru tespit edilip "normal"den "normal"e (kaymasız) durulama yapılıyor.
- **Mutex Kilit Göstergesi, besin dozlaması sürerken yanıltıcıydı:** widget
  sadece asit/klor/yıkama'yı biliyor; besin dozlaması aktifken 3 kanalın da
  "kilitli" göründüğü ama HİÇBİRİNİN "aktif" görünmediği, açıklamasız bir
  durum oluşuyordu. Artık besin dozlaması sürerken nedenini açıklayan bir
  not gösteriliyor.

**Dokümante edilmiş, düzeltilmemiş bir mimari sınırlama:** `firmware/config.h`
`TOPLAM_ZON_SAYISI=4` sabiti, zon-izolasyonunun (Faz 2) kaç zonu kapsayacağını
belirliyor — uygulamadaki çiftlik/zon modeli ise serbest metin/sayı kabul
ediyor. Sistemde gerçekte 4'ten fazla zon veya 1-4 dışında numaralandırılmış
bir zon varsa, izolasyon o zonları KAPSAMAZ. Şu anki varsayılan kurulum
(4 zon, 1-4 numaralı) için sorun yok; bkz. `firmware/DONANIM_KONTROL_LISTESI.md`.

### Firmware Denetimi — SD Kart Günlüğü (2026-09-25)

- Baştan sona yeniden okunan firmware kodunda bulunan bir gerçek eksiklik
  düzeltildi: **manuel komutla** (otonom teşhis olmadan) başlatılan HER
  tedavi — asit/klor/yıkama ve Faz 3'teki besin sıvı/toz dahil — SD karttaki
  denetim günlüğüne (`tedaviLogla`) hiç yazılmıyordu; yalnızca otonom
  teşhisle tetiklenen tedaviler loglanıyordu. Artık manuel tedaviler de
  `guven=0`/tür kaydı olmadan (bu, satırın otonom değil manuel olduğunun
  CSV kuralı) loglanıyor. arduino-cli ile yeniden derlendi (%78 flash, %15
  RAM — önceki derlemelerle tutarlı).

### Ekran Görüntüleri (2026-09-25)

- README'deki ekran görüntüleri artık gerçek (canlı GitHub Pages
  dağıtımından Playwright ile alınmış) görseller — Genel Bakış, Tedavi
  Geçmişi, Trend Analizi, Ayarlar. Zon Detay ekran görüntüsü, canlı demonun
  bildirim SnackBar'larının zon kartlarının üzerine gelmesi nedeniyle
  otomatik olarak güvenilir şekilde alınamadı; bu eksiklik README'de açıkça
  belirtildi (uydurulmadı). Ayrıca MQTT veri şeması örneğindeki eski
  camelCase alan adları (`tespitEdildi` vb.) gerçek kablo formatı olan
  snake_case (`tespit_edildi` vb.) ile düzeltildi.

### Hava Durumu Tabanlı Basit Sulama Önerisi (2026-09-25) — Faz 4

- Kullanıcının doğrudan talebi üzerine: Uzaktan Sulama ekranına, seçili
  çiftliğin GPS konumu (harita özelliğiyle eklenen `enlem`/`boylam` alanı)
  varsa **Open-Meteo**'dan (API anahtarı gerektirmeyen, ücretsiz, küçük
  ölçekli kullanım için tasarlanmış bir servis) yarının hava tahminini
  çeken ve bitki türüne göre basit, kural tabanlı bir sulama önerisi
  ("erteleyebilirsiniz" / "normal" / "artırabilirsiniz") gösteren bir kart
  eklendi. Bu özellik daha önce "güvenilmez/anahtarlı harici API'den kaçın"
  ilkesi gereğince ertelenmişti; Open-Meteo bu varsayımı değiştirdiği için
  yeniden değerlendirildi.
- **Dürüstlük notu (istatistiksel trend tahmini ile aynı disiplin):** bu,
  gerçek bir agronomik model (evapotranspirasyon/Penman-Monteith, toprak
  nem sensörü, bitki gelişim evresi) DEĞİLDİR — yarınki yağış ihtimali +
  sıcaklık + kaba bitki türü kategorisine göre basit bir yön verir. Kart
  her zaman "basit, kural tabanlı bir öneridir — profesyonel tarım
  danışmanlığının yerine geçmez" notuyla gösterilir.
- Çiftlikte GPS konumu yoksa API HİÇ çağrılmaz, sadece konum ekleme daveti
  gösterilir. Ağ hatası/zaman aşımı/bozuk yanıt durumunda servis her zaman
  `null` döner ve uygulama ÇÖKMEDEN "şu an alınamadı" mesajı gösterir —
  hiçbir zaman sahte/varsayılan bir öneri uydurulmaz.
- Yeni `BitkiTuru` alanı (sebze/meyve ağacı/tarla bitkisi/diğer), çiftlik
  profiline eklendi; operatör kartın üzerindeki seçiciyle değiştirebilir.
- Yeni bağımlılık: `http` paketi (`package:http/testing.dart`
  `MockClient` ile ağa hiç çıkmadan test edildi). 5 yeni test dosyası —
  model round-trip, JSON ayrıştırma (eksik/bozuk veriye karşı dayanıklılık),
  öneri kural mantığının tüm dalları, servisin 4 ağ senaryosu (başarı/HTTP
  hatası/bozuk JSON/bağlantı istisnası), widget entegrasyonu.

### Jüri Sunum Modu Düzeltmesi (2026-09-25)

- "Bu Adımı Tetikle" butonuna basınca ekranda hiçbir görsel değişiklik
  olmuyordu — bu ekranda canlı bildirim SnackBar'ları bilerek bastırıldığı
  için (Geri/İleri butonlarının üstüne binmesin diye), buton aslında
  çalışıyor ama sunucuya "hiçbir şey olmadı" hissi veriyordu. Artık
  butonun altında "Tetiklendi" onayı görünüyor.
- Sunum senaryosuna eksik bir adım eklendi: Uzaktan Sulama/Besin
  Takviyesi/Hava Durumu Önerisi (Faz 1-4) hiç sunum akışında yer
  almıyordu — Mutex Kilidi ile Rapor ve Analiz adımları arasına
  "Uzaktan/Manuel Kontrol" adımı eklendi.

### Gerçek Kullanıcı Hesabı — E-posta/Şifre Girişi (2026-09-25)

- Onboarding'den sonra, e-posta/şifre ile **gerçek** kayıt/giriş ekranı
  eklendi (Firebase Authentication). Önceki "Giriş Ekranı" (marka + Demo
  Modu seçimi) gerçek bir kimlik doğrulama akışı DEĞİLDİ — bu, ilk kez
  gerçek bir hesap sistemi ekliyor.
- **Dürüstlük notu:** hesap sistemi SADECE giriş/çıkışı yönetir — çiftlik/
  sensör/tedavi verisi hâlâ cihazda yerel olarak tutulur, hesaplar arası
  veri ayrımı veya bulut senkronizasyonu YOKTUR. Bu, ekranda da açıkça
  belirtiliyor.
- **Kurulum bekliyor:** Firebase projesinin kendisi, sadece Beyzanur'un
  kendi Google hesabıyla yapabileceği, dışarıdaki bir adım (bkz.
  `docs/FIREBASE_KURULUM.md`) — bu tamamlanana kadar
  `config/firebase_secenekleri.dart`'taki değerler yer tutucu kalır ve
  giriş/kayıt ekranı HİÇ gösterilmez, uygulama bugünkü gibi çalışmaya
  devam eder (firmware'in `WIFI_SSID` yer tutucusuyla aynı disiplin).
- **Jüri demosu güvenliği:** giriş ekranında "Misafir olarak devam et"
  seçeneği var — saha Wi-Fi'sinde bir sorun çıkarsa (Firebase Auth ağ
  gerektirir) demo asla bloklanmaz.
- Hata mesajları Firebase'in İngilizce kodlarından (email-already-in-use,
  wrong-password, network-request-failed vb.) doğrudan okunabilir
  Türkçe metne çevrilir.
- Yeni bağımlılıklar: `firebase_core`, `firebase_auth`. 16 yeni test
  (provider'ın sahte bir `KimlikDogrulamaServisi` ile — gerçek Firebase'e
  hiç çıkmadan — tüm giriş/kayıt/çıkış/misafir senaryoları, form
  doğrulama, hata banner'ı, Ayarlar'daki Çıkış Yap kartı).

### Keşfedilebilirlik Düzeltmesi — Sulama Başlat (2026-09-25)

- Uzaktan Sulama ve Besin Takviyesi'ne erişim daha önce SADECE AppBar'daki
  etiketsiz "⋮" (Daha fazla) menüsündeydi — kullanıcı gerçek uygulamada
  denedi ve özelliği bulamadı ("hâlâ yok" olarak bildirdi, iki kez). Kod
  hiçbir zaman bozuk değildi; menü dar telefon genişliğinde 4 diğer
  ikonun (Yardım/Bildirim/Jüri Sunum/Çiftlikler) arkasında hiçbir görsel
  ipucu vermeden duruyordu. Artık Genel Bakış'ın gövdesinde, yazılı iki
  büyük buton olarak duruyor. Eski "⋮" menüsü tamamen kaldırıldı.

### Acımasız UI/UX Denetimi — 6 Parçalı Sadeleştirme (2026-09-25)

Kullanıcının "arayüz çok karmaşık geliyor" geri bildirimine yanıt olarak,
gerçek ekran görüntüleriyle (360×800 telefon genişliği, Playwright)
doğrulanan 6 ayrı sorun düzeltildi:

- **Bildirim gösterim mimarisi değişti**: canlı aktivite bildirimleri
  artık alttan `SnackBar` değil, üstten (AppBar'ın hemen altında)
  `MaterialBanner` olarak gösteriliyor. Bu oturumda iki kez gerçek bug
  olarak karşımıza çıkan "bildirim alttaki interaktif kontrollerin
  üzerine biniyor" sorununu kökten çözüyor — bir üst-banner hiçbir zaman
  ekranın altındaki içerikle çakışmaz.
- **Genel Bakış'taki üçlü tekrar sadeleştirildi**: zon durum kırılımı
  (Normal/Belirsiz/Tespit) daha önce Sistem Sağlığı göstergesinin metni +
  ayrı bir rozet satırı + Zon Şeması olmak üzere üç kez gösteriliyordu.
  Rozet satırı artık Sistem Sağlığı kartının içinde, ayrı blok kaldırıldı.
- **Ayarlar 15 düz bölümden 5 katlanır kategoriye gruplandı** (Hesap ve
  Profil / Bağlantı / Sistem Yapılandırması / Bildirim ve Güvenlik /
  Diğer), varsayılan kapalı.
- **ACİL DURDUR yüzen bir buton olmaktan çıkarıldı** — sayfa kısaldıkça
  alttaki Hızlı Eylem butonlarının üzerine binmeye başlamıştı. Artık
  ekranın kaydırılabilir alanının hemen altında, sabit, tam genişlikte
  bir şerit.
- **Trend Analizi grafiklerinde tekrarlayan y-ekseni etiketi düzeltildi**
  (örn. "7.2" üst üste iki kez görünüyordu) — açık bir eksen aralığı
  verilerek.
- **Pil/WiFi rozetine görsel ayraç eklendi** — iki ayrı metrik arasında
  sınır yoktu, pilin uyarı rengi WiFi metnine aitmiş gibi okunabiliyordu.

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
- Firebase projesi henüz kurulmadı (`config/firebase_secenekleri.dart`
  yer tutucu) — kurulana kadar giriş/kayıt ekranı gösterilmez (bkz.
  `docs/FIREBASE_KURULUM.md`). Hesap sistemi kurulduktan sonra bile
  çiftlik/sensör verisini hesaba göre AYIRMAZ, sadece giriş/çıkışı yönetir.
- Erişilebilirlik: ana durum/sensör/kontrol widget'larında ekran okuyucu
  etiketleri var; uygulamanın tamamı henüz taranmadı.
- README'deki Zon Detay ekran görüntüsü eksik (canlı demonun SnackBar
  bildirimleri zon kartlarının üzerine geldiği için otomatik alınamadı —
  bkz. "Ekran Görüntüleri" bölümü yukarıda). Diğer 4 ekran görüntüsü gerçek.
