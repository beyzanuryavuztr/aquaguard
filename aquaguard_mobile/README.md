# AquaGuard Mobil

AquaGuard'ın Flutter mobil/web uygulaması — TEKNOFEST 2026 Tarım Teknolojileri
Yarışması, Arge-T HydroLab takımı.

Toprak altı damla sulama (SDI) sistemlerinde damlatıcı tıkanmasını türüne göre
(kimyasal / biyolojik / fiziksel) otonom teşhis eden ve tedavi eden AquaGuard
sisteminin mobil izleme arayüzüdür. Deneyap Kart'tan (veya henüz donanım
hazır değilse uygulama içi **Demo Modu**'ndan) MQTT üzerinden gelen sensör ve
teşhis verisini görselleştirir.

Projenin tam teknik özeti için depo kökündeki `PROJE_BRIEF.md` dosyasına bakın.

## Klasör yapısı

```
lib/
├── config/       Sensör imzaları, tema, kalibrasyon sabitleri (Python/firmware ile tutarlı tutulmalı)
├── models/       Veri modelleri (SensorOkuma, Tarla, AktiviteKaydi, BakimGorevi, ...)
├── services/     MQTT istemcisi, PDF rapor, bildirim, PIN/güvenli depolama, yerel depolama
├── providers/    UygulamaDurumu -- tek durum kaynağı (Provider/ChangeNotifier)
├── screens/      Ekranlar (Genel Bakış, Tedavi Geçmişi, Trend Analizi, Ayarlar, ...)
└── widgets/      Tekrar kullanılan bileşenler
```

## Çalıştırma

```bash
flutter pub get
flutter run -d chrome   # web (önerilen ilk test ortamı)
flutter run              # bağlı bir Android cihaz/emülatörde
```

Uygulama ilk açılışta **Demo Modu**'nda başlar (gerçek donanım henüz
bağlanmamışsa) ve tamamen simüle edilmiş, gerçekçi bir tıkanma senaryosu
gösterir — hiçbir ağ bağlantısı gerekmez. Gerçek Deneyap Kart'a bağlanmak
için Ayarlar sekmesinden Demo Modu'nu kapatıp MQTT broker bilgilerini girin.

## Testler

```bash
flutter analyze
flutter test
```
