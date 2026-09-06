/// AquaGuard - "Neden Bu Karar?" Aciklanabilirlik Paneli
/// ==========================================================
///
/// Amac:
///   AquaGuard'in rakiplerden temel farki, kural tabanli karar motorunun
///   SADECE bir sonuc degil, ayni zamanda ACIKLANABILIR bir gerekce
///   sunmasidir (bkz. PROJE_BRIEF.md SS8 rakip konumlandirma). Bu panel,
///   karar motorunun pH/EC/ORP degerlerini UC tikanma turunun literatur
///   imzasiyla ne kadar eslesir buldugunu (guven yuzdesi olarak) yan yana
///   gosterir -- "neden kimyasal degil de biyolojik dedi?" sorusunun
///   gorsel cevabidir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';
import 'durum_renkleri.dart';

class AciklanabilirlikPaneli extends StatelessWidget {
  final SensorOkuma okuma;

  const AciklanabilirlikPaneli({super.key, required this.okuma});

  @override
  Widget build(BuildContext context) {
    final girdiler = <(TikanmaTuru tur, double guven, Color renk)>[
      (TikanmaTuru.kimyasal, okuma.guvenKimyasal, const Color(0xFFEF6C00)),
      (TikanmaTuru.biyolojik, okuma.guvenBiyolojik, const Color(0xFF2E7D32)),
      (TikanmaTuru.fiziksel, okuma.guvenFiziksel, const Color(0xFF1565C0)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Neden Bu Karar?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kural motoru, pH/EC/ORP değerlerini her tıkanma türünün literatür '
              'imzasıyla karşılaştırarak bu güven skorlarını üretti:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final girdi in girdiler) ...[
              _GuvenCubugu(
                etiket: turEtiketi(girdi.$1),
                guven: girdi.$2,
                renk: girdi.$3,
                kazananMi: girdi.$1 == okuma.tikanmaTuru,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuvenCubugu extends StatelessWidget {
  final String etiket;
  final double guven;
  final Color renk;
  final bool kazananMi;

  const _GuvenCubugu({
    required this.etiket,
    required this.guven,
    required this.renk,
    required this.kazananMi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  etiket,
                  style: TextStyle(
                    fontWeight: kazananMi ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (kazananMi) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle, size: 14, color: renk),
                ],
              ],
            ),
            Text(
              '%${guven.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: kazananMi ? FontWeight.bold : FontWeight.normal,
                color: kazananMi
                    ? renk
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (guven / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, deger, _) => LinearProgressIndicator(
              value: deger,
              minHeight: 8,
              backgroundColor: renk.izTonu,
              color: kazananMi ? renk : renk.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
