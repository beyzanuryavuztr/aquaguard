/// AquaGuard - Bakim Uyari Karti
/// =====================================
///
/// Amac:
///   Genel Bakış'ta, en az bir bakim gorevi GECIKMIS veya YAKLASIYORSA
///   gosterilen uyari karti -- operatoru Ayarlar'daki Bakım Takvimi
///   bölümüne yönlendirir. Hicbir gorev dikkat gerektirmiyorsa hic
///   render edilmez (bkz. cagiran taraftaki `if (durum.bakimUyarisiVarMi)`).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/bakim_gorevi.dart';

class BakimUyariKarti extends StatelessWidget {
  final List<BakimGorevi> gorevler;
  final VoidCallback onAyarlaraGit;

  const BakimUyariKarti({
    super.key,
    required this.gorevler,
    required this.onAyarlaraGit,
  });

  @override
  Widget build(BuildContext context) {
    final gecikmis = gorevler.where((g) => g.durumu() == BakimDurumu.gecikti).length;
    final yaklasanlar = gorevler
        .where((g) => g.durumu() == BakimDurumu.yaklasiyor)
        .length;
    final renk = gecikmis > 0
        ? AquaGuardTema.tehlikeRenk
        : AquaGuardTema.uyariRenk;

    return Card(
      color: renk.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAyarlaraGit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.build_circle_outlined, color: renk, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gecikmis > 0
                          ? 'Bakım Gecikti'
                          : 'Bakım Zamanı Yaklaşıyor',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: renk,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (gecikmis > 0) '$gecikmis gecikmiş görev',
                        if (yaklasanlar > 0) '$yaklasanlar yaklaşan görev',
                      ].join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
