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
  final bool sulamaDurdurulduMu;
  final VoidCallback onTap;

  /// Zonun gosterilecek adi (opsiyonel takma ad). Verilmezse "Zon N".
  final String? zonAdi;

  const ZonDurumKarti({
    super.key,
    required this.zonNumarasi,
    required this.okuma,
    required this.cevrimici,
    this.sulamaDurdurulduMu = false,
    required this.onTap,
    this.zonAdi,
  });

  @override
  Widget build(BuildContext context) {
    final renk = DurumRenkleri.renkGetir(okuma: okuma, cevrimici: cevrimici);
    final ikon = DurumRenkleri.ikonGetir(okuma: okuma, cevrimici: cevrimici);
    final ozet = DurumRenkleri.ozetMetniGetir(
      okuma: okuma,
      cevrimici: cevrimici,
    );
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
                                  zonAdi ?? 'Zon $zonNumarasi',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (okuma != null &&
                                    okuma!.durum == TeshisDurumu.tespitEdildi &&
                                    cevrimici) ...[
                                  const SizedBox(width: 8),
                                  _GuvenRozeti(guven: okuma!.guven, renk: renk),
                                ],
                                if (sulamaDurdurulduMu) ...[
                                  const SizedBox(width: 8),
                                  const _SulamaDurdurulduRozeti(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: gecisSuresi,
                              style: TextStyle(
                                color: renk,
                                fontWeight: FontWeight.w600,
                              ),
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

class _SulamaDurdurulduRozeti extends StatelessWidget {
  const _SulamaDurdurulduRozeti();

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme.onTertiaryContainer;
    return Tooltip(
      message: 'Sulama manuel olarak durduruldu',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline, size: 12, color: renk),
            const SizedBox(width: 4),
            Text(
              'Sulama Kapalı',
              style: TextStyle(
                color: renk,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
        style: TextStyle(
          color: renk,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
