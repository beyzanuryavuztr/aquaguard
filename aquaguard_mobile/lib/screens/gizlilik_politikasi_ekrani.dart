/// AquaGuard - Gizlilik Politikası Ekranı
/// ============================================
///
/// Amac:
///   Operatörün onboarding sırasında onayladığı, hangi verinin toplandığını
///   ve nerede saklandığını AÇIK ve DOĞRU şekilde anlatan bilgi ekranı --
///   bkz. onboarding_ekrani.dart (_BaslaSayfasi, onay kutusu) ve
///   ayarlar_ekrani.dart (Ayarlar'dan da erişilebilir).
///
///   Metin BİLEREK abartısız/dürüst tutuldu: bu proje gerçekten
///   offline-first çalışıyor (bkz. proje genelindeki ayrım), bu yüzden
///   "hiçbir veri sunucuya gönderilmez" gibi güçlü ama YANLIŞ bir iddiada
///   bulunmuyoruz -- MQTT komutları broker üzerinden cihaza gider, harita
///   karoları OpenStreetMap'ten çekilir. Metin bu ikisini AÇIKÇA ayırıyor.
///
/// Tarih:  2026-09-18
library;

import 'package:flutter/material.dart';

import '../widgets/duyarli_icerik.dart';

class GizlilikPolitikasiEkrani extends StatelessWidget {
  const GizlilikPolitikasiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: DuyarliIcerik(
        maksimumGenislik: 640,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            _Bolum(
              baslik: 'Hangi veriyi topluyoruz?',
              icerik:
                  'AquaGuard; sensör okumaları (pH, EC, ORP, türbidite, debi, '
                  'basınç), tarla/zon bilgileri, isterseniz eklediğiniz tarla '
                  'konumu ve fotoğrafı, işletme/operatör profiliniz, bakım ve '
                  'tedavi geçmişi ile maliyet parametrelerini saklar. Bunların '
                  'hepsi SİZİN girdiğiniz veya cihazınızdan/sisteminizden gelen '
                  'verilerdir.',
            ),
            SizedBox(height: 20),
            _Bolum(
              baslik: 'Bu veri nerede saklanır?',
              icerik:
                  'Tüm veriler YALNIZCA bu cihazda, yerel bir SQLite '
                  'veritabanında saklanır. AquaGuard\'ın kendi sunucusu YOKTUR '
                  've bu verileri hiçbir sunucuya göndermez. PIN kodu ayrıca '
                  'şifrelenmiş bir güvenli depoda tutulur.',
            ),
            SizedBox(height: 20),
            _Bolum(
              baslik: 'Ağ üzerinden neler gidip geliyor?',
              icerik:
                  'İki durumda cihaz dışına veri çıkar, ikisi de sunucumuza '
                  'DEĞİL: (1) Gerçek donanım modunda, sensör verisi ve '
                  'komutlar MQTT broker\'ı üzerinden sulama sisteminizle '
                  'değiş tokuş edilir -- bu, uygulamanın çalışması için '
                  'gerekli bir haberleşme kanalıdır. (2) Tarla haritası '
                  'gösterilirken, görüntülenen bölgenin harita karoları '
                  'OpenStreetMap\'ten indirilir. Demo Modu\'nda ağ üzerinden '
                  'HİÇBİR veri alışverişi yapılmaz.',
            ),
            SizedBox(height: 20),
            _Bolum(
              baslik: 'Verinizi nasıl silersiniz?',
              icerik:
                  'Uygulamayı cihazınızdan kaldırmak tüm yerel verileri siler. '
                  'Tarla, not ve geçmiş kayıtlarını uygulama içinden tek tek '
                  'de silebilirsiniz.',
            ),
            SizedBox(height: 20),
            _Bolum(
              baslik: 'Hata günlüğü',
              icerik:
                  'Uygulama beklenmedik bir hatayla karşılaşırsa, teşhis '
                  'amaçlı bir kayıt SADECE cihazınızda tutulur (bkz. Ayarlar > '
                  'Tanılama). Bu günlük otomatik olarak hiçbir yere '
                  'gönderilmez; isterseniz Ayarlar\'dan dışa aktarıp kendiniz '
                  'paylaşabilirsiniz.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Bolum extends StatelessWidget {
  final String baslik;
  final String icerik;

  const _Bolum({required this.baslik, required this.icerik});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(icerik, style: const TextStyle(height: 1.4)),
      ],
    );
  }
}
