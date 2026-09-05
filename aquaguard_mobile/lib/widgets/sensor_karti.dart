/// AquaGuard - Sensor Karti (Secilebilir Ozet Kart)
/// =====================================================
///
/// Amac:
///   Zon Detay ekraninda her sensor icin ayirt edici ikon+renkle GUNCEL
///   degeri gosteren, dokunulabilir kompakt bir kart. Secili olan kart,
///   altinda buyutulmus SensorTrendGrafigi'nin HANGI sensore ait oldugunu
///   belirler (bkz. tikanma_detay_ekrani.dart _SensorAnaliziBolumu) --
///   onceki surumdeki 6 kucuk sparkline'lik sabit izgaranin (_SensorTrendIzgarasi)
///   yerini, "one one, sonra detaya bak" akisiyla bu kartlar + tek buyuk
///   grafik alir.
///
/// Tarih:  2026-09-04
library;

import 'package:flutter/material.dart';

class SensorKarti extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String birim;
  final double deger;
  final Color renk;
  final bool secili;
  final VoidCallback onTap;

  const SensorKarti({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.birim,
    required this.deger,
    required this.renk,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: secili
            ? renk.withValues(alpha: 0.14)
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: secili ? renk : Theme.of(context).colorScheme.outlineVariant,
          width: secili ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ikon, color: renk, size: 22),
                const SizedBox(height: 6),
                Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${deger.toStringAsFixed(deger.abs() < 10 ? 2 : 0)}'
                  '${birim.isNotEmpty ? ' $birim' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: renk,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
