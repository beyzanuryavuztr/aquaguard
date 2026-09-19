/// AquaGuard - Model Performansi Ekrani
/// ========================================
///
/// Amac:
///   python/aquaguard_karar_motoru.py'nin egitim/dogrulama surecinde
///   urettigi 5 gorseli (karisiklik matrisi, capraz dogrulama grafigi,
///   ozellik onemi, sinif bazli performans tablosu, sensor dagilimlari)
///   uygulama icinde gosterir -- daha once bu gorseller SADECE
///   python/gorseller/ klasorunde duruyordu, juri uygulamayi actiginda
///   "%89.9 dogruluk" iddiasinin GERCEK kanitini gormuyordu.
///
///   DURUSTLUK NOTU (tikanma_detay_ekrani.dart -> _KararKatmaniEtiketi ile
///   BIREBIR AYNI cumle): bu gorseller Katman 2'nin (Random Forest) OFFLINE
///   dogrulama performansini gosterir -- bu model hicbir CANLI uygulamada
///   (bu Dart demosu dahil) calismaz, sahadaki tum kararlar Katman 1
///   (kural tabanli) tarafindan anlik verilir.
///
///   Gorseller STATIKTIR (assets/model_gorselleri/), uygulama tarafindan
///   uretilmez -- model yeniden egitilirse python/aquaguard_karar_motoru.py
///   calistirilip PNG'ler elle guncellenmelidir (bkz. pubspec.yaml notu).
///
/// Tarih:  2026-09-15
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../widgets/duyarli_icerik.dart';

class ModelPerformansiEkrani extends StatelessWidget {
  const ModelPerformansiEkrani({super.key});

  static const _gorseller = [
    (
      'assets/model_gorselleri/cv_dogruluk_grafigi.png',
      'Çapraz Doğrulama Doğruluğu',
      '5-fold çapraz doğrulama sonucu: %89.9 ± %1.5 doğruluk (PROJE_BRIEF.md hedefi: ~%90).',
    ),
    (
      'assets/model_gorselleri/karisiklik_matrisi.png',
      'Karışıklık Matrisi',
      '4 sınıf (normal / kimyasal / biyolojik / fiziksel) arasındaki sınıflandırma performansı.',
    ),
    (
      'assets/model_gorselleri/performans_tablosu.png',
      'Sınıf Bazlı Performans',
      'Her sınıf için precision, recall ve F1 skoru.',
    ),
    (
      'assets/model_gorselleri/ozellik_onemi.png',
      'Özellik Önemi',
      'Hangi sensörün sınıflandırmada en belirleyici olduğu (Random Forest özellik önemi).',
    ),
    (
      'assets/model_gorselleri/sensor_dagilimlari.png',
      'Sensör Dağılımları',
      'Her sensörün sınıf bazlı dağılımı — sensör imzalarının (pH/EC/ORP/türbidite/debi/ΔP) görsel kanıtı.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Model Performansı')),
      body: DuyarliIcerik(
        maksimumGenislik: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İki Katmanlı Karar Motoru',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Katman 1 (kural tabanlı eşik mantığı) sahada canlı '
                      'çalışan birincil karar katmanıdır. Katman 2 (Random '
                      'Forest sınıflandırıcı), sentetik veri setiyle eğitilip '
                      '5-fold çapraz doğrulamayla test edilen bir OFFLINE '
                      'doğrulama katmanıdır.',
                      style: TextStyle(color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yapay zeka (Katman 2) yalnızca çevrimdışı doğrulama '
                      'içindir, canlı teşhiste kullanılmaz.',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final gorsel in _gorseller) ...[
              _GorselKarti(
                yol: gorsel.$1,
                baslik: gorsel.$2,
                aciklama: gorsel.$3,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _GorselKarti extends StatelessWidget {
  final String yol;
  final String baslik;
  final String aciklama;

  const _GorselKarti({
    required this.yol,
    required this.baslik,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              aciklama,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.asset(yol, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
