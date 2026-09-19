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
  İletişim); eski genel API'yi koruyan geçici bir facade üzerinden
  76 tüketici dosya değiştirilmeden çalışmaya devam ediyor.
  Performans: en dar kapsamlı 3 ekran (PIN kilidi, bildirim geçmişi,
  tarla notları) doğrudan ilgili alt provider'ı izleyecek şekilde
  taşındı.
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
- Test paketi: 391 Flutter testi + Python `pytest` paketi.

### Güvenlik

- MQTT kullanıcı adı/parola desteği: parola cihazın güvenli deposunda saklanır,
  arayüzde geri gösterilmez; TLS kapalıyken uyarı gösterilir.
- PIN oturum zaman aşımı: uygulama 5 dakikadan uzun arka planda kalırsa PIN
  ekranı yeniden mevcut ekranın üstüne biner.
- Kimyasal dozlama (asit/klor) başlatma onayına, yanlışlıkla dokunmayı
  zorlaştıran 3 saniyelik geri sayım eklendi.
- MQTT bağlantısı için opsiyonel TLS desteği (varsayılan halen düz
  bağlantı — bkz. Bilinen Sınırlamalar).

### Bilinen Sınırlamalar

- MQTT varsayılan olarak genel test broker'ı (`test.mosquitto.org`)
  üzerinden düz TCP ile çalışır. Kimlik doğrulama desteklenir ama varsayılan
  kapalıdır; üretimde kendi TLS+kimlik doğrulamalı broker'ınızı kullanın.
- i18n sadece Ayarlar > Görünüm bölümünde etkin; uygulamanın geri
  kalanı sabit Türkçe metin içerir.
- Firmware (`firmware/`) bu geliştirme ortamında derlenip gerçek
  donanımda doğrulanamamıştır — sadece kod incelemesiyle yazılmıştır.
- Erişilebilirlik: ana durum/sensör/kontrol widget'larında ekran okuyucu
  etiketleri var; uygulamanın tamamı henüz taranmadı.
- README'deki ekran görüntüleri bölümü henüz gerçek görsellerle
  doldurulmadı (`docs/screenshots/` — manuel olarak eklenecek).
