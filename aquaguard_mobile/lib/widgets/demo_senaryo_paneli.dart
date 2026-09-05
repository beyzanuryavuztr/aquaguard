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

import '../providers/uygulama_durumu.dart';

class DemoSenaryoPaneli extends StatelessWidget {
  const DemoSenaryoPaneli({super.key});

  static const _senaryolar = [
    (DemoSenaryosu.saglikli, 'Sağlıklı', Icons.check_circle_outline),
    (DemoSenaryosu.kimyasal, 'Kimyasal', Icons.diamond_outlined),
    (DemoSenaryosu.biyolojik, 'Biyolojik', Icons.coronavirus_outlined),
    (DemoSenaryosu.fiziksel, 'Fiziksel', Icons.grain),
    (DemoSenaryosu.mutexKilidi, 'Mutex Kilidi', Icons.lock_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final durum = context.read<UygulamaDurumu>();
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
                    child: ActionChip(
                      avatar: Icon(s.$3, size: 16),
                      label: Text(s.$2),
                      onPressed: () => durum.demoSenaryosuTetikle(s.$1),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
