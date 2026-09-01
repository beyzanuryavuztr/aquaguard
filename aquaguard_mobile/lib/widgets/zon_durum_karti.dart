/// AquaGuard - Zon Durum Karti Widget'i
/// ========================================
///
/// Amac:
///   Dashboard ekraninda her zon icin gosterilen, renk kodlu, tiklanabilir
///   ozet kart. Zon dashboard ekraninin listesinde tekrar tekrar kullanilir
///   (bu yuzden ayri bir widget olarak cikarilmistir -- kod tekrarini onler).
///
///   Durum degistiginde renk/ikon AnimatedContainer ile YUMUSAK GECISLE
///   degisir -- ani/sert renk sicramalari yerine profesyonel bir his verir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_okuma.dart';
import 'durum_renkleri.dart';

class ZonDurumKarti extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma? okuma;
  final bool cevrimici;
  final VoidCallback onTap;

  const ZonDurumKarti({
    super.key,
    required this.zonNumarasi,
    required this.okuma,
    required this.cevrimici,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = DurumRenkleri.renkGetir(okuma: okuma, cevrimici: cevrimici);
    final ikon = DurumRenkleri.ikonGetir(okuma: okuma, cevrimici: cevrimici);
    final ozet = DurumRenkleri.ozetMetniGetir(okuma: okuma, cevrimici: cevrimici);
    const gecisSuresi = Duration(milliseconds: 400);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              AnimatedContainer(
                duration: gecisSuresi,
                width: 6,
                height: 96,
                color: renk,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: gecisSuresi,
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: renk.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ikon, color: renk, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Zon $zonNumarasi',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (okuma != null &&
                                    okuma!.durum == TeshisDurumu.tespitEdildi &&
                                    cevrimici) ...[
                                  const SizedBox(width: 8),
                                  _GuvenRozeti(guven: okuma!.guven, renk: renk),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: gecisSuresi,
                              style: TextStyle(color: renk, fontWeight: FontWeight.w600),
                              child: Text(ozet),
                            ),
                            if (okuma != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Son güncelleme: ${DateFormat('HH:mm:ss').format(okuma!.zaman)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuvenRozeti extends StatelessWidget {
  final double guven;
  final Color renk;

  const _GuvenRozeti({required this.guven, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '%${guven.toStringAsFixed(0)}',
        style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
