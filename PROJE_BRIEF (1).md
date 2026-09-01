# AquaGuard — Proje Brief
## TEKNOFEST 2026 Tarım Teknolojileri Yarışması | Kategori 3.3: Toprak Altı Sulama Sistemleri
**Takım:** Arge-T HydroLab | **Başvuru No:** 5227105 | **Takım No:** 993372  
**Durum:** FİNALİST — Şanlıurfa, 30 Eylül – 4 Ekim 2026  
**Hedef:** Birincilik

---

## 1. PROJE TANIMI

AquaGuard, toprak altı damla sulama (SDI) sistemlerinde damlatıcı tıkanmasını türüne göre otomatik teşhis eden ve uygun tedaviyi otonom biçimde uygulayan bir sistemdir.

Tıkanma 3 kategoride gerçekleşir:
- **Kimyasal:** CaCO₃ ve demir tuzlarının çökelmesi → tedavi: asit dozlama
- **Biyolojik:** Bakteri, alg ve biyofilm gelişimi → tedavi: klor enjeksiyonu
- **Fiziksel:** Kum, sediman ve partikül birikimi → tedavi: yüksek basınçlı yıkama

Sahada tıkanma türünü doğrudan belirleyecek bir yöntem literatürde tanımlanmamıştır (Lequette vd., 2022). AquaGuard bu boşluğu doldurmayı hedefler.

**Özgünlük:** Sensör tabanlı tıkanma türü teşhisi + türe özgü otonom tedavi kararı + otomatik müdahale → tek bir kapalı karar döngüsünde bütünleştirilmesi. Bu kombinasyon ne ticari üründe ne de akademik prototipte mevcut değildir.

---

## 2. TAKIM YAPISI

| Rol | Sorumluluk |
|-----|-----------|
| Beyzanur | Yazılım, ML modeli, Flutter mobil uygulama, sunum |
| Enver | Donanım, sensör entegrasyonu, prototip inşası |
| Dr. Öğr. Üyesi Tuğçem Partal | Danışman (bilimsel rehberlik, aktif iş yok) |

---

## 3. DONANIM MİMARİSİ (Enver'in sorumluluğu — referans bilgi)

- **Mikrodenetleyici:** Deneyap Kart (T3 Vakfı, yerli üretim)
- **6 sensör:** pH, EC (mS/cm), ORP (mV), türbidite (NTU), debi (LPM), diferansiyel basınç (bar)
- **3 tedavi kanalı:**
  - Asit dozlama pompası (DC motor) → kimyasal tıkanma
  - Klor enjeksiyon pompası (DC motor) → biyolojik tıkanma
  - Yüksek basınçlı yıkama valfi (servo motor) → fiziksel tıkanma
- **Güvenlik:** Mutex kilidi — asit ve klor aynı anda çalışamaz (toksik gaz riski). Her tedavi sonrası zorunlu durulama.
- **İletişim:** SIM800L GSM modülü, MQTT protokolü
- **Kayıt:** SD kart + RTC modülü (zaman damgalı loglama)
- **Enerji:** Güneş paneli + LiPo pil
- **Prototip:** 3+1 bölmeli şeffaf akrilik test düzeneği

### KRİTİK UYARILAR:
- ❌ ESP32 YAZMA — her yerde "Deneyap Kart" kullan
- ❌ Sıcaklık sensörü YOK — sistemden kalıcı olarak çıkarıldı
- ❌ 7 sensör YAZMA — her yerde "6 sensör" kullan
- ❌ React Native YAZMA — her yerde "Flutter" kullan

---

## 4. YAZILIM MİMARİSİ (Beyzanur'un sorumluluğu)

### 4.1. Sentetik Veri Üretici (Python)
**Dosya:** `python/aquaguard_veri_uretici.py`  
**Çıktı:** `python/aquaguard_dataset.csv`

- 2000 örneklik etiketli sensör veri seti üretir
- 4 sınıf dağılımı (Abuzaid vd. 2024): normal %10, kimyasal %22, biyolojik %37, fiziksel %31
- %12 atipik/örtüşen vaka (sınıf sınırlarında belirsiz örnekler)
- Neden sentetik: etiketli kamuya açık SDI tıkanma veri seti dünyada mevcut değil
- seed=42 ile tekrarlanabilir
- Çalıştırıldığında sınıf bazlı ortalama tablosu yazdırır

### 4.2. İki Katmanlı Teşhis Motoru (Python)
**Dosya:** `python/aquaguard_karar_motoru.py`  
**Çıktılar:** `python/model/` (eğitilmiş model), `python/gorseller/` (grafikler)

**Katman 1 — Kural tabanlı eşik mantığı (BİRİNCİL):**
- Tıkanma tespiti tetikleyicileri:
  - Debi düşüşü: normal debi (4.0 LPM) referansına göre ≥1.5 LPM düşüş
  - VEYA basınç artışı: ≥0.36 bar
  - VEYA türbidite: ≥12 NTU
- Tür belirleme: pH, EC, ORP değerlerinden her tür için skor hesapla
- Güven skoru üret (0-100 arası)
- Güven düşükse "belirsiz" çıktısı → operatör bildirimi, tedavi tetiklenmez

**Katman 2 — Random Forest sınıflandırıcı (İKİNCİL):**
- Sentetik veri setiyle eğitilir
- 5-fold cross-validation (hedef: ~%90 doğruluk, mevcut: %89.9 ± %2.3)
- Kural katmanının kararını doğrular
- Belirsiz vakaları çözer
- İki katman çelişirse → kural katmanı kararı korunur, operatör bilgilendirilir

**Üretilecek görseller:**
- Confusion matrix (karışıklık matrisi)
- Sınıf bazlı precision, recall, F1 skoru tablosu
- Cross-validation doğruluk grafiği
- Sensör dağılım grafikleri (her sensör için sınıf bazlı kutu grafik)
- Özellik önem sıralaması (feature importance)

### 4.3. Deneyap Kart Gömülü Yazılım (C++ / Arduino)
**Klasör:** `firmware/`

| Dosya | İçerik |
|-------|--------|
| `aquaguard_main.ino` | Ana döngü: sensör oku → karar ver → tedavi uygula → logla → MQTT gönder |
| `config.h` | Pin tanımları, eşik değerleri, MQTT ayarları, kalibrasyon sabitleri |
| `sensors.h` | 6 sensör okuma fonksiyonları, outlier filtresi, normalizasyon |
| `decision_engine.h` | Kural tabanlı karar motoru (Python versiyonunun C++ karşılığı) |
| `treatment.h` | 3 tedavi kanalı kontrolü, mutex kilidi, zorunlu durulama döngüsü |
| `mqtt_handler.h` | SIM800L üzerinden MQTT bağlantısı, veri gönderme, yeniden bağlanma |
| `logger.h` | SD kart + RTC ile zaman damgalı veri ve tedavi geçmişi kaydı |

### 4.4. Flutter Mobil Uygulama
**Klasör:** `aquaguard_mobile/` (Flutter projesi olarak ayrı oluşturulacak)

- MQTT üzerinden Deneyap Kart'tan canlı sensör verisi alır
- **Ekranlar:**
  - Tarla seçimi (birden fazla tarla desteği)
  - Zone bazlı dashboard (renk kodlu durum: yeşil/sarı/kırmızı)
  - Tıkanma detay ekranı (tür, güven skoru, önerilen tedavi)
  - Aktif tedavi ekranı (ilerleme göstergesi)
  - Geçmiş loglar (tarih bazlı sensör ve tedavi geçmişi)
  - Ayarlar (MQTT bağlantı, bildirim tercihleri)
- Tıkanma ve tedavi bildirimleri
- Çevrimdışı mod: GSM kesilirse son bilinen durumu göster
- Hedef: önce web/Chrome test, sonra Android

---

## 5. KLASÖR YAPISI

```
C:\AquaGuard\
├── PROJE_BRIEF.md          ← bu dosya
├── python\
│   ├── aquaguard_veri_uretici.py
│   ├── aquaguard_karar_motoru.py
│   ├── aquaguard_dataset.csv       (üretilen veri)
│   ├── model\                      (eğitilmiş model .pkl dosyaları)
│   └── gorseller\                  (confusion matrix, grafikler)
├── firmware\
│   ├── aquaguard_main.ino
│   ├── config.h
│   ├── sensors.h
│   ├── decision_engine.h
│   ├── treatment.h
│   ├── mqtt_handler.h
│   └── logger.h
└── aquaguard_mobile\               (Flutter projesi)
```

---

## 6. SENSÖR İMZALARI (Literatüre Dayalı)

Her tıkanma türü su kalitesi parametrelerinde ayrışık bir sinyal bırakır:

| Parametre | Normal | Kimyasal | Biyolojik | Fiziksel |
|-----------|--------|----------|-----------|----------|
| pH | 7.0 ± 0.3 | **8.3 ± 0.3** ↑ | 6.6 ± 0.35 ↓ | 7.0 ± 0.3 (değişmez) |
| EC (mS/cm) | 1.15 ± 0.2 | **2.75 ± 0.45** ↑ | 1.50 ± 0.3 | 1.15 ± 0.2 (değişmez) |
| ORP (mV) | 375 ± 40 | 310 ± 40 ↓ | **175 ± 45** ↓↓ | 350 ± 40 |
| Türbidite (NTU) | 3 ± 1.2 | 10 ± 3 | 20 ± 5.5 ↑ | **35 ± 8** ↑↑ |
| Debi (LPM) | 4.0 ± 0.25 | 2.6 ± 0.35 ↓ | 3.0 ± 0.3 ↓ | **1.8 ± 0.45** ↓↓ |
| ΔP (bar) | 0.10 ± 0.03 | 0.40 ± 0.09 ↑ | 0.32 ± 0.07 ↑ | **0.60 ± 0.12** ↑↑ |

**Ayrışık imzalar (jüri için ezberle):**
- Biyolojik → ORP çöker (175 mV, anaerobik ortam)
- Kimyasal → pH ve EC birlikte yükselir (8.3 / 2.75)
- Fiziksel → türbidite patlar (35 NTU) ve debi ani düşer (1.8 LPM)

**Kaynaklar:** Lequette vd. (2022), Shen vd. (2022), Moulia vd. (2024)

---

## 7. DOĞRULANMIŞ İSTATİSTİKLER

| İstatistik | Değer | Kaynak |
|-----------|-------|--------|
| Türkiye tarımsal su kullanımı | %79 | T.C. Tarım ve Orman Bakanlığı DSİ, 2024 |
| Basınçlı sulama sistemleri payı | %29 | DSİ, 2024 |
| Tıkanma: biyolojik | %37 | Abuzaid vd. 2024 (Scientific Reports) |
| Tıkanma: fiziksel | %31 | Abuzaid vd. 2024 |
| Tıkanma: kimyasal | %22 | Abuzaid vd. 2024 |
| 5 yılda debi düşüşü | %11.7 | Ma vd. 2025 |
| Tedavisiz sistem ömrü | 8-11 yıl | Ma vd. 2025 |
| Donanım maliyeti (1 zon) | 7.266 ₺ | Takım hesaplaması |
| Hedef satış fiyatı | ~11.200 ₺ | %35 brüt marj |
| Geri ödeme süresi | 3-5 sezon | Takım hesaplaması |
| ML doğruluk (sentetik) | %89.9 ± %2.3 | 5-fold CV |

---

## 8. RAKİP KONUMLANDIRMA

| Özellik | Netafim NetBeat | Rivulis Manna | AquaGuard |
|---------|----------------|---------------|-----------|
| Tespit seviyesi | Hat seviyesi | Makro (sensörsüz) | Zon seviyesi, 6 parametre |
| Tıkanma türü teşhisi | Yok | Yok | pH+EC+ORP+türbidite+hidrolik füzyon |
| Karar mekanizması | Operatör bildirimi | Reçete önerisi | İki katmanlı otonom (kural + RF) |
| Tedavi | Manuel | Manuel | Türe özgü otomatik enjeksiyon |
| Güvenlik | Operatöre bağlı | Yazılımsal öneri | Mutex kilidi + zorunlu durulama |

---

## 9. KOD YAZIM KURALLARI

1. **Dil:** Tüm yorumlar, docstring'ler ve çıktı mesajları Türkçe
2. **Terminoloji:** Deneyap Kart (ESP32 değil), Flutter (React Native değil), 6 sensör (7 değil), sıcaklık sensörü yok
3. **Kalite:** Production-ready, profesyonel, hatasız
4. **Dokümantasyon:** Her dosyanın başında docstring (amaç, kaynaklar, tarih, yazar)
5. **Tekrarlanabilirlik:** random seed=42
6. **Çıktı formatı:** Tüm grafikler PNG olarak `gorseller/` klasörüne kaydedilmeli
7. **Model kayıt:** Eğitilmiş model `model/` klasörüne `.pkl` olarak kaydedilmeli
