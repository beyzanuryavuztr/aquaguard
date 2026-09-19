# AquaGuard — Kod Denetim Raporu

**Tarih:** 2026-09-19 · **Kapsam:** `aquaguard_mobile/`, `firmware/`, `python/`, CI, belgeler
**Yöntem:** hedefli tarama + üç dil arası otomatik tutarlılık betiği + derleme/test çalıştırma.
**Sınırlar (dürüstlük notu):** 136 Dart dosyasının her satırı okunmadı; risk odaklı
tarama yapıldı. Gerçek donanım, Android SDK ile release derleme ve iOS erişimi
olmadığı için o alanlar **doğrulanamadı** (aşağıda "Doğrulanamayanlar").

Durum sütunu: **AÇIK** = düzeltilmedi · **DÜZELTİLDİ** = bu denetimde giderildi.

---

## KRİTİK (güvenlik / yanlış güvence)

| # | Bulgu | Kanıt | Etki | Öneri | Durum |
|---|---|---|---|---|---|
| K1 | **Acil Durdur, gerçek modda doğrulanmıyor ve yanlış güvence veriyor.** Komutlar "gönder ve unut"; bağlantı yoksa kuyruğa alınır, **5 dakika sonra sessizce silinir**. Buna rağmen ekran "tüm tedaviler ve sulama durduruldu" der ve vanaları yerelde "kapalı" işaretler. | `cihaz_iletisim_provider.dart` `acilDurdurmaTetikle` (~652), `acil_durdurma_fab.dart:102`, `ayarlar_sabitleri.dart:84` | Operatör durdu sanır, cihaz çalışmaya devam edebilir. | Gerçek modda ACK bekle; bağlantı yoksa "GÖNDERİLEMEDİ, cihaza gidin" uyarısı; acil komutların kuyruk süresi dolmasın ya da kullanıcıya açıkça bildirilsin. | AÇIK |
| K2 | **Firmware komut onayı (ACK/NACK) yayınlamıyor.** Uygulama `komut_id` ekleyip `komut_durumu` bekliyor; firmware ikisini de bilmiyor. Sonuç: `tedavi_baslat` gerçek modda **her zaman 30 sn sonra "zaman aşımı"** çıkar, cihaz komutu uygulamış olsa bile. Vana kapalıyken reddedilen komut da sessiz. | `mqtt_handler.h` `_komutMesajGeldiginde`; `ayarlar_sabitleri.dart:78`; `DONANIM_KONTROL_LISTESI.md` §4 | Hızlı Eylemler dahil tüm elle komutlar gerçek donanımda güvenilmez geri bildirim verir. | Firmware'e `komut_id` okuma + `komut_durumu` yayını ekle (Python mock zaten yapıyor). | AÇIK |
| K3 | **Bloklayıcı ağ çağrıları pompa çalışırken.** `gprsConnect` ve `PubSubClient.connect` ana döngüyü onlarca saniye bloklayabilir; bu sırada `tedaviGuncelle()` çalışmaz, **pompa süresini aşabilir**. Kodun "hiçbir yerde delay() yok, non-blocking" iddiası bu açıdan doğru değil. **Watchdog yok.** | `mqtt_handler.h` `mqttBaglantiyiSagla` (~205-245), `aquaguard_main.ino` `loop()` | Kimyasal dozlamanın kontrolsüz uzaması. | Tedavi/durulama sürerken yeniden bağlanma denemesini ertele; donanım watchdog'u ekle; pompa için üst süre sınırı. | AÇIK |
| K4 | **Kimlik doğrulamasız genel broker + komut konusu.** Varsayılan `test.mosquitto.org`, kimlik yok; herkes `aquaguard/zoneN/komut`'a yayınlayıp **kimyasal dozlama başlatabilir/vanayı kapatabilir** ve sahte veri basabilir. GSM hattında TLS yok; firmware kimlik bilgisi derleme zamanı sabiti. | `config.h` (MQTT_BROKER_ADRESI/KULLANICI), README güvenlik notu | Yetkisiz fiziksel kontrol. | Demo dışında zorunlu: kendi broker + kullanıcı/parola + ACL. Komutlara imza/nonce düşün. | AÇIK (README uyarıyor, varsayılan tehlikeli) |
| K5 | **Android release'te `INTERNET` izni yoktu** (yalnızca debug/profile manifestlerinde). Release APK hiçbir ağ bağlantısı kuramazdı (MQTT, harita, TLS). | `android/app/src/main/AndroidManifest.xml` | Release build çalışmazdı. | İzin ana manifeste eklendi. | **DÜZELTİLDİ** (release APK ile doğrulanmadı) |

## YÜKSEK

| # | Bulgu | Kanıt | Öneri | Durum |
|---|---|---|---|---|
| Y1 | **ADC voltaj uyumsuzluğu.** ESP32 ADC en çok 3,3 V okur; kod basınç için 0,5–4,5 V, türbidite için ~4,2 V varsayıyor, **bölücü oranı sabiti yok**. Pinler ve kalibrasyon sabitleri "yer tutucu"; hiç donanım testi yok. | `config.h` (ADC_REFERANS_VOLTAJ, BASINC_*, TURBIDITE_*) | Gerçek modül çıkışlarını ölç, bölücü + firmware'de geri ölçekleme ekle; kalibrasyon yap. | AÇIK |
| Y2 | **Veri saklama sınırı ile "7g/30g" görünümleri çelişiyor.** Sınır: zon başına **10.000 satır veya 7 gün**. Gerçek cihaz 10 sn'de bir yayınlar → 10.000 satır ≈ **28 saat**; demo (1,5 sn) ≈ 4 saat. "30g" seçeneği 7 günlük saklamayla zaten ulaşılamaz. Tedavi sayaçları, başarı oranı ve maliyet özeti bu kısa pencereden hesaplanıyor → **yanıltıcı olabilir**. | `drift_sensor_okuma_repository.dart`, `sensor_trend_grafigi.dart:29` (TrendDonemi) | Kademeli saklama (örn. dakikalık özet), ya da UI'de "mevcut veri aralığı" göster ve 30g'yi kaldır. | AÇIK |
| Y3 | **Vana durumu cihazdan raporlanmıyor.** MQTT JSON'da vana alanı yok; uygulama vana durumunu kendi tahminiyle tutuyor (K1 ile birleşince uyumsuzluk). | `mqtt_handler.h` JSON alanları, `sensor_okuma.dart` | JSON şemasına `ana_vana_acik` ekle (3 yerde senkron). | AÇIK |
| Y4 | **GitHub Pages (https) + varsayılan `ws://` (8080):** tarayıcı karışık içeriği engeller, gerçek mod Pages'te ancak TLS (WSS 8081) açıksa çalışır. | `mqtt_istemci_web.dart`, `ayarlar_sabitleri.dart` | Web'de TLS'i zorunlu kıl/uyar. | AÇIK |
| Y5 | Release imzası **debug anahtarıyla**; `POST_NOTIFICATIONS`/`USE_BIOMETRIC` izinlerinin manifestte olup olmadığı doğrulanmadı (Android 13+ bildirim çalışmayabilir). | `android/app/build.gradle.kts:32` | Gerçek keystore; izinleri kontrol et. | AÇIK |

## ORTA

| # | Bulgu | Kanıt / Not | Öneri | Durum |
|---|---|---|---|---|
| O1 | **Model Performansı ekranında sabit "%89.9 ± %2.3".** Modeli yeniden eğitince 5-fold CV **%89.9 ± %1.5**, test seti %90.8 çıkıyor (ortalama tutuyor, std tutmuyor). Görseller statik PNG. | `model_performansi_ekrani.dart:37` | Sayıyı güncel çıktıyla eşitle (ya da PNG'yi yeniden üret). | AÇIK |
| O2 | **Model doğruluğu sentetik veriden**, ve veri kural motorunun kullandığı imzalardan üretiliyor → ölçüm kısmen döngüsel. Ekranda "sentetik" notu var; sahada doğruluk **bilinmiyor**. | `aquaguard_veri_uretici.py` | Sunumda bu sınırı açıkça söyle; mümkünse gerçek veriyle doğrula. | AÇIK (bilinçli/dokümante) |
| O3 | Sıcaklık sensörü yok (bilinçli); pH/EC ölçümleri sıcaklık telafisiz → doğruluk sınırı. | `PROJE_BRIEF.md:50`, `config.h` EC notu | Belgeye sınırlama olarak yaz. | AÇIK |
| O4 | CI firmware'i derlemiyor. Artık derlenebiliyor (arduino-cli, genel ESP32). | `.github/workflows/ci.yml` | Genel ESP32 derleme işi ekle (Deneyap tanımı ayrı doğrulanır). | AÇIK |
| O5 | iOS hiç derlenmedi/denenmedi (Info.plist izinleri var ama doğrulanmadı). | `aquaguard_mobile/ios/` | Mac'te dene ya da kapsam dışı yaz. | AÇIK |
| O6 | Depo kökünde rastgele adlı 6,7 MB PDF: `BwL3XfOWsM5o7zUlVY8gJxe6H11gJvso (3).pdf` (ilk commit). | `git ls-files` | İçeriği kontrol et; anlamlı ada taşı ya da kaldır. | AÇIK |
| O7 | i18n yalnızca Ayarlar > Görünüm/Dil; erişilebilirlik (Semantics) kısmi. | CHANGELOG "Bilinen Sınırlamalar" | Belgeli; final sonrası. | AÇIK |
| O8 | 2 testte kalan "database already closed" log gürültüsü (hata değil). | A5 sonrası | İzle. | AÇIK |
| O9 | `DurumRenkleri.renkKorluguModu` statik global durum (testler arası sızma riski; testler sıfırlıyor). | `durum_renkleri.dart` | Bilinen ödünleşim. | AÇIK |
| O10 | Facade (`UygulamaDurumu`) 38 test için hâlâ giriş noktası. | uygulama_durumu.dart | Bilinçli; belgelendi. | AÇIK |

## DÜŞÜK

| # | Bulgu | Durum |
|---|---|---|
| D1 | `lib/widgets/mini_trend_grafigi.dart` hiçbir yerden referans almıyordu (ölü kod). | **DÜZELTİLDİ** (silindi) |
| D2 | README'de ekran görüntüleri yok; Pages henüz açılmadı. | AÇIK (kullanıcı adımı) |
| D3 | 3 adet `// ignore` yorumu (zararsız; `prefer_initializing_formals`, web-only kütüphaneler). | Kabul |

---

## Doğrulananlar (temiz çıkanlar)

- **Eşikler ve sensör imzaları** Python ↔ Dart ↔ firmware'de **birebir aynı** (otomatik betikle karşılaştırıldı, 0 fark).
- **MQTT sözleşmesi tutarlı:** durum/tür/tedavi metinleri (`tespit_edildi`, `asit_dozlama` …) firmware ve uygulamada eşleşiyor; uygulamanın gönderdiği 5 komutun 5'i firmware'de karşılanıyor.
- **Firmware derleniyor** (genel ESP32, arduino-cli; %31 flash, %7 RAM, projeden uyarı yok).
- **Testler:** Flutter 391, Python 43; `flutter analyze --fatal-infos` temiz; web build başarılı; skip'li test ve TODO/FIXME yok.
- **Gizli veri:** PIN ve MQTT parolası güvenli depoda; depoda keystore/.env yok.

## Doğrulanamayanlar (donanım/araç gerektirir)

- Pinlerin, kalibrasyonun, sensör okumalarının ve GSM bağlantısının **gerçek Deneyap Kart'ta** çalışması.
- Deneyap Kart'ın kendi kart tanımıyla derleme (yalnızca genel ESP32 ile derlendi).
- Android release APK'nın gerçekten ağ kurabildiği (izin eklendi, APK üretilmedi).
- iOS davranışı.
- Hızlı Eylemler / kimlik doğrulama / PIN zaman aşımının gerçek cihazla uçtan uca davranışı.

## Önerilen sıra

1. **K2 + K1 + Y3:** ACK'yi firmware'e ekle; acil durdurmayı "doğrulanmış/doğrulanmamış" olarak göster; vana durumunu şemaya ekle.
2. **K3:** bağlanma denemelerini tedavi sırasında ertele + watchdog.
3. **Y1:** gerilim bölücü/ölçekleme + kalibrasyon (donanımla).
4. **Y2:** saklama/görünüm tutarlılığı (30g'yi kaldır ya da kademeli saklama).
5. **K4:** kendi broker + kimlik; **Y4/Y5** yayın öncesi.
6. **O1, O4, O6:** hızlı temizlikler.
