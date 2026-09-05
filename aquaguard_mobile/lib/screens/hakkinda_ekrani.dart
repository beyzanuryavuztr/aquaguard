/// AquaGuard - Hakkında Ekranı
/// ================================
///
/// Amac:
///   Uygulamanın kimliğini (sürüm, proje, takım, danışman, üniversite),
///   kullandığı açık kaynak kütüphaneleri (Flutter'ın standart
///   `showLicensePage`'i ile) ve tek cümlelik mottosunu gösteren, Ayarlar
///   ekranının en altındaki "Hakkında" bağlantısından açılan sade bir
///   bilgi ekranı.
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';

import '../widgets/aquaguard_logosu.dart';
import '../widgets/duyarli_icerik.dart';
import 'giris_ekrani.dart' show aquaGuardSurumMetni;

class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: DuyarliIcerik(
        maksimumGenislik: 560,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: AquaGuardLogosu(boyut: 72)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'AquaGuard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                aquaGuardSurumMetni,
                style: TextStyle(color: onSurfaceVariant, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),
            _BilgiKarti(
              baslik: 'Proje',
              satirlar: const [
                'TEKNOFEST 2026 Tarım Teknolojileri Yarışması',
                'Kategori 3.3 — Toprak Altı Sulama Sistemleri',
              ],
            ),
            const SizedBox(height: 16),
            _BilgiKarti(
              baslik: 'Takım',
              satirlar: const ['Arge-T HydroLab (Takım No: 993372)'],
            ),
            const SizedBox(height: 16),
            _BilgiKarti(
              baslik: 'Üyeler',
              satirlar: const [
                'Beyzanur Yavuz — Yazılım',
                'Enver [Soyad] — Donanım',
              ],
            ),
            const SizedBox(height: 16),
            _BilgiKarti(
              baslik: 'Danışman',
              satirlar: const ['Dr. Öğr. Üyesi Tuğçem Partal'],
            ),
            const SizedBox(height: 16),
            _BilgiKarti(
              baslik: 'Üniversite',
              satirlar: const ['Recep Tayyip Erdoğan Üniversitesi'],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Lisanslar'),
                subtitle: const Text('Kullanılan açık kaynak kütüphaneleri'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'AquaGuard',
                  applicationVersion: aquaGuardSurumMetni,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Doğru Teşhis, Doğru Tedavi, Sürdürülebilir Sulama',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BilgiKarti extends StatelessWidget {
  final String baslik;
  final List<String> satirlar;

  const _BilgiKarti({required this.baslik, required this.satirlar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            for (final satir in satirlar)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(satir),
              ),
          ],
        ),
      ),
    );
  }
}
