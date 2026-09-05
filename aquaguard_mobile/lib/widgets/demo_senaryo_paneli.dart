/// AquaGuard - Demo Senaryo Tetikleme Paneli
/// =============================================
///
/// Amac:
///   Jüri/izleyici önünde, uygulamanın rastgele demo akışını beklemek
///   yerine, TEK DOKUNUŞLA istenen senaryoyu (sağlıklı / kimyasal /
///   biyolojik / fiziksel / mutex kilidi gösterimi) hemen tetiklemeyi
///   sağlar. Mevcut operatör-müdahalesi altyapısını (bkz.
///   providers/uygulama_durumu.dart demoSenaryosuTetikle) kullanır.
///
///   Ayrıca veri üretim HIZINI (bkz. models/demo_hizi.dart) ayarlayan bir
///   seçici içerir -- varsayılan "Normal" (1.5sn) jüri sunumu için sabit
///   3sn'den çok daha uygundur; "Turbo" (0.2sn) sadece BURADAN erişilir.
///
///   SADECE Demo Modu açıkken anlamlıdır (gerçek donanımda "senaryo
///   tetikleme" diye bir şey yoktur — cihaz gerçek sensör okur); bu yüzden
///   bu widget'ı gösterip göstermeyeceğine karar vermek çağıran ekranın
///   sorumluluğundadır (bkz. genel_bakis_ekrani.dart, sadece
///   durum.demoModuAktif iken eklenir).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/demo_hizi.dart';
import '../providers/uygulama_durumu.dart';

class DemoSenaryoPaneli extends StatelessWidget {
  const DemoSenaryoPaneli({super.key});

  static const _senaryolar = [
    (
      DemoSenaryosu.saglikli,
      'Sağlıklı',
      Icons.check_circle_outline,
      'Tüm zonları normale döndürür',
    ),
    (
      DemoSenaryosu.kimyasal,
      'Kimyasal',
      Icons.diamond_outlined,
      'Zon 2\'de kimyasal tıkanma + asit dozlama tedavisi',
    ),
    (
      DemoSenaryosu.biyolojik,
      'Biyolojik',
      Icons.coronavirus_outlined,
      'Zon 1\'de biyolojik tıkanma + klor enjeksiyonu tedavisi',
    ),
    (
      DemoSenaryosu.fiziksel,
      'Fiziksel',
      Icons.grain,
      'Zon 3\'te fiziksel tıkanma + yüksek basınçlı yıkama',
    ),
    (
      DemoSenaryosu.mutexKilidi,
      'Mutex Kilidi',
      Icons.lock_outline,
      'Zon 2 + Zon 4 aynı anda farklı tedavilerle, her zonun kilidi bağımsız çalışır',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 16,
                color: onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo Senaryosu Tetikle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in _senaryolar)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: s.$4,
                      child: ActionChip(
                        avatar: Icon(s.$3, size: 16),
                        label: Text(s.$2),
                        onPressed: () => durum.demoSenaryosuTetikle(s.$1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.speed_outlined, size: 16, color: onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Demo Hızı',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<DemoHizi>(
            segments: DemoHizi.values
                .map((h) => ButtonSegment(value: h, label: Text(h.etiket)))
                .toList(),
            selected: {durum.demoHizi},
            showSelectedIcon: false,
            onSelectionChanged: (secim) =>
                durum.demoHiziniAyarla(secim.first),
          ),
        ],
      ),
    );
  }
}
