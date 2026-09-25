/// AquaGuard - Ayarlar Ekrani
/// ==============================
///
/// Amac:
///   Demo modu, MQTT broker baglanti bilgilerini (adres/port) ve bildirim
///   tercihini yonetir. Degisiklikler kaydedilince ilgili provider
///   otomatik olarak ilgili baglantiyi (simulasyon veya gercek MQTT)
///   yeniden kurar.
///
///   A6 (2026-09-18): bu dosya eskiden 1200+ satirlik TEK bir StatefulWidget
///   olarak `context.watch<UygulamaDurumu>()` (facade) izliyordu. Her bolum
///   (Profil/Gorunum+Dil/Veri Kaynagi/MQTT/Bildirimler/Zon Isimleri/
///   Maliyet/Kalibrasyon+Esikler/Bakim Takvimi/Guvenlik) artik
///   `lib/widgets/ayarlar/` altinda AYRI bir widget dosyasi -- her biri
///   SADECE ihtiyaci olan alt provider'i (AyarlarProvider/
///   CihazIletisimProvider/TarlaProvider/BakimProvider/GuvenlikProvider)
///   dogrudan izler. Bu ekran artik SADECE bu bolumleri sirayla dizen ince
///   bir iskelet -- kendi basina hicbir provider okumuyor.
///
/// Tarih:  2026-09-01 (bolunme: 2026-09-18)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../config/firebase_secenekleri.dart';
import '../config/tarih_bicimleri.dart';
import '../services/disa_aktarma_factory.dart';
import '../services/hata_gunlugu_servisi.dart';
import '../widgets/ayarlar/bakim_takvimi_karti.dart';
import '../widgets/ayarlar/bildirimler_karti.dart';
import '../widgets/ayarlar/bolum_basligi.dart';
import '../widgets/ayarlar/gorunum_dil_karti.dart';
import '../widgets/ayarlar/guvenlik_karti.dart';
import '../widgets/ayarlar/hesap_karti.dart';
import '../widgets/ayarlar/kalibrasyon_esik_kartlari.dart';
import '../widgets/ayarlar/kullanici_profili_karti.dart';
import '../widgets/ayarlar/maliyet_parametreleri_karti.dart';
import '../widgets/ayarlar/mqtt_baglanti_karti.dart';
import '../widgets/ayarlar/veri_kaynagi_karti.dart';
import '../widgets/ayarlar/zon_isimleri_karti.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/yardim_butonu.dart';
import 'gizlilik_politikasi_ekrani.dart';
import 'hakkinda_ekrani.dart';

class AyarlarEkrani extends StatelessWidget {
  const AyarlarEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        actions: const [
          YardimButonu(ekranAnahtari: 'ayarlar', baslik: 'Ayarlar'),
        ],
      ),
      body: DuyarliIcerik(
        maksimumGenislik: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (firebaseYapilandirildiMi) ...[
              const BolumBasligi(baslik: 'Hesap'),
              const HesapKarti(),
              const SizedBox(height: 24),
            ],
            const BolumBasligi(baslik: 'Kullanıcı Profili'),
            const KullaniciProfiliKarti(),
            const SizedBox(height: 24),
            // i18n PILOT (kisitli kapsam -- bkz. lib/l10n/app_tr.arb dosya
            // basi notu): SADECE Gorunum+Dil kartlari AppLocalizations
            // uzerinden cekilir, uygulamanin geri kalani hala sabit
            // Turkce metin kullanir.
            const GorunumDilKartlari(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Veri Kaynağı'),
            const VeriKaynagiKarti(),
            const SizedBox(height: 24),
            const MqttBaglantiKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Bildirimler'),
            const BildirimlerKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Zon İsimleri'),
            const ZonIsimleriKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Maliyet Parametreleri'),
            const MaliyetParametreleriKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Sensör Kalibrasyonu'),
            const KalibrasyonKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Eşik Değerleri'),
            const EsikDegerleriKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Bakım Takvimi'),
            const BakimTakvimiKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Güvenlik'),
            const GuvenlikKarti(),
            const SizedBox(height: 24),
            const BolumBasligi(baslik: 'Tanılama'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Hata Günlüğünü Dışa Aktar'),
                subtitle: const Text(
                  'Uygulama içinde yakalanan hatalar cihazınızda saklanır, '
                  'hiçbir sunucuya gönderilmez',
                ),
                onTap: () => _hataGunlugunuDisaAktar(context),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik Politikası'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GizlilikPolitikasiEkrani(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HakkindaEkrani()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [DisaAktarmaServisi]'nin CSV disa aktarma mekanizmasini (platforma
  /// gore dosya sistemi/tarayici indirmesi) YENIDEN KULLANIR -- hata
  /// gunlugu CSV formatinda olmasa da, "metni platforma uygun bir konuma
  /// yaz/indir" islemi BIREBIR ayni; ikinci bir platform-kosullu ithalat
  /// cifti (io/web) yazmak gereksiz tekrar olurdu.
  Future<void> _hataGunlugunuDisaAktar(BuildContext context) async {
    final icerik = HataGunluguServisi.metinOlarakBirlestir();
    if (icerik.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hata günlüğü boş')));
      return;
    }
    final zamanDamgasi = TarihBicimleri.dosyaAdi.format(DateTime.now());
    final dosyaAdi = 'aquaguard_hata_gunlugu_$zamanDamgasi.log';
    final konum = await csvKaydet(dosyaAdi, icerik);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hata günlüğü dışa aktarıldı: $konum')),
    );
  }
}
