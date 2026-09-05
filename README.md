# AquaGuard

**Toprak altı damla sulama (SDI) sistemlerinde damlatıcı tıkanmasını türüne
göre (kimyasal / biyolojik / fiziksel) otonom teşhis eden ve tedavi eden bir
tıkanma yönetim sistemi.**

Sahada tıkanma türünü doğrudan belirleyecek bir yöntem literatürde
tanımlanmamıştır. AquaGuard; 6 sensörden (pH, EC, ORP, türbidite, debi,
diferansiyel basınç) gelen veriyi iki katmanlı bir karar motoruyla
(kural tabanlı birincil katman + Random Forest ile offline doğrulama)
değerlendirir, tıkanmanın türünü belirler ve 3 tedavi kanalından
(asit dozlama / klor enjeksiyonu / yüksek basınçlı yıkama) uygun olanını
otonom olarak devreye alır.

TEKNOFEST 2026 Tarım Teknolojileri Yarışması, Kategori 3.3 (Toprak Altı
Sulama Sistemleri) kapsamında Arge-T HydroLab takımı tarafından geliştirildi.

## Mimari

```
firmware/ (Deneyap Kart)
  6 sensör → Karar Motoru (Katman 1: kural tabanlı, cihaz üzerinde)
  → 3 tedavi kanalı (asit / klor / yüksek basınçlı yıkama)
        │
        │  MQTT (aynı JSON şeması)
        ▼
aquaguard_mobile/ (Flutter kontrol paneli)          python/
  web / Android / Windows                             sentetik veri üretimi
  Demo Modu ile donanımsız da çalışır                  RF model eğitimi (Katman 2,
                                                        offline doğrulama)
                                                        MQTT mock yayıncı
```

Sensör okuma JSON şeması (`guven_kimyasal`/`guven_biyolojik`/`guven_fiziksel`
dahil) firmware, Python ve Flutter tarafında **bayt bayt aynı** tutulur —
üçü de aynı karar mantığının bağımsız birer uygulamasıdır, tek kaynak üç
yerde senkron tutulur.

## Klasör yapısı

| Klasör | İçerik |
|---|---|
| `firmware/` | Deneyap Kart C++ firmware — sensör okuma, karar motoru (Katman 1), 3 tedavi kanalı, MQTT haberleşme |
| `python/` | Sentetik veri üretici, Random Forest karar motoru (Katman 2, offline doğrulama), MQTT mock yayıncı, pytest test paketi |
| `aquaguard_mobile/` | Flutter kontrol paneli (web/Android/Windows) — Demo Modu, gerçek zamanlı izleme, tedavi geçmişi, trend analizi |
| `PROJE_BRIEF.md` | Projenin tam teknik özeti (donanım mimarisi, sensör eşikleri, tedavi kuralları) |

## Kurulum ve çalıştırma

### Flutter mobil/web uygulaması

```bash
cd aquaguard_mobile
flutter pub get
flutter run -d chrome   # web (önerilen ilk test ortamı)
```

Uygulama ilk açılışta **Demo Modu**'nda başlar — gerçek donanım
bağlanmamışsa bile tamamen simüle edilmiş, gerçekçi bir tıkanma senaryosu
gösterir, hiçbir ağ bağlantısı gerekmez. Gerçek Deneyap Kart'a bağlanmak
için Ayarlar'dan Demo Modu'nu kapatıp MQTT broker bilgilerini girin.

Testler:

```bash
flutter analyze
flutter test
```

### Python (karar motoru / veri üretimi)

```bash
cd python
pip install -r requirements.txt
python aquaguard_veri_uretici.py       # sentetik veri seti üretir
python aquaguard_karar_motoru.py       # RF modelini eğitir, doğrular
pytest                                  # test paketini çalıştırır
```

### Firmware

`firmware/aquaguard_main.ino` Deneyap Kart IDE ile derlenip yüklenir.
Pin/kalibrasyon sabitleri `config.h` içindedir.

## Durum

Yazılım (Python karar motoru + Flutter uygulaması) bu depoda geliştirilip
test edilmiştir. Firmware, gerçek donanımda (Deneyap Kart + 6 sensör + 3
tedavi kanalı) doğrulanmayı beklemektedir.

## Takım

Arge-T HydroLab — TEKNOFEST 2026 Tarım Teknolojileri Yarışması, Kategori 3.3.

| Rol | Sorumluluk |
|---|---|
| Beyzanur | Yazılım, karar motoru, Flutter mobil uygulama |
| Enver | Donanım, sensör entegrasyonu, prototip inşası |
| Dr. Öğr. Üyesi Tuğçem Partal | Danışman |
