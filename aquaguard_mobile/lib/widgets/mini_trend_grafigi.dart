/// AquaGuard - Mini Trend Grafigi (Sparkline)
/// ==============================================
///
/// Amac:
///   Bir sensorun son N okumasini eksen etiketi olmadan, kucuk ve sade bir
///   cizgi grafik (sparkline) olarak gosterir. Tikanma detay ekraninda her
///   sensor icin "son durum nereye gidiyor" hissini verir -- sadece tek bir
///   ani deger degil, kisa vadeli egilim de gorulur.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'durum_renkleri.dart';

class MiniTrendGrafigi extends StatelessWidget {
  final String baslik;
  final String birim;
  final List<double> degerler; // eskiden yeniye siralanmis
  final Color renk;

  const MiniTrendGrafigi({
    super.key,
    required this.baslik,
    required this.birim,
    required this.degerler,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final guncelDeger = degerler.isNotEmpty ? degerler.last : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  baslik,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${guncelDeger.toStringAsFixed(guncelDeger.abs() < 10 ? 2 : 0)} $birim',
                  style: TextStyle(fontWeight: FontWeight.bold, color: renk),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: degerler.length < 2
                  ? Center(
                      child: Text(
                        'Yeterli veri birikince eğilim gösterilecek',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        minY: degerler.reduce((a, b) => a < b ? a : b) * 0.95,
                        maxY:
                            degerler.reduce((a, b) => a > b ? a : b) * 1.05 +
                            0.01,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < degerler.length; i++)
                                FlSpot(i.toDouble(), degerler[i]),
                            ],
                            isCurved: true,
                            color: renk,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: renk.izTonu,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
