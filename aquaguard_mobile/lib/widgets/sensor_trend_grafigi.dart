/// AquaGuard - Sensor Trend Grafigi (Esik Cizgili, Donem Sekmeli)
/// ====================================================================
///
/// Amac:
///   Zon Detay'da SECILI sensorun buyutulmus trend grafigini gosterir.
///   24 saat / 7 gün / 30 gün dönem sekmeleriyle veriyi zamana göre
///   filtreler ve (varsa) o sensör için KRİTİK EŞİK ÇİZGİSİNİ (referans
///   debi/basınç/türbidite -- config/sensor_imzalari.dart TEK KAYNAĞINDAN)
///   grafiğin üzerine çizer -- operatör "bu değer ne zaman eşiği geçti"
///   sorusunu görsel olarak cevaplayabilir.
///
///   NOT: dönem seçimi sadece ELDEKİ veriyi ZAMANA göre filtreler; "30 gün"
///   seçilse bile gerçekte sadece GecmisVeriUreticisi'nin üretebildiği kadar
///   (bkz. gunSayisi=12) geçmiş veri varsa o kadarı gösterilir -- veri
///   UYDURULMAZ (aynı "yeterli veri yoksa olduğu gibi göster" ilkesi,
///   bkz. MiniTrendGrafigi'ndeki "yeterli veri birikince" notu).
///
/// Tarih:  2026-09-04
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';

enum TrendDonemi { saat24, gun7, gun30 }

extension TrendDonemiX on TrendDonemi {
  Duration get pencere => switch (this) {
    TrendDonemi.saat24 => const Duration(hours: 24),
    TrendDonemi.gun7 => const Duration(days: 7),
    TrendDonemi.gun30 => const Duration(days: 30),
  };

  String get etiket => switch (this) {
    TrendDonemi.saat24 => '24s',
    TrendDonemi.gun7 => '7g',
    TrendDonemi.gun30 => '30g',
  };
}

/// Grafiğe çizilecek yatay bir eşik/referans çizgisi.
class EsikCizgisi {
  final double deger;
  final String etiket;
  final Color renk;

  const EsikCizgisi({
    required this.deger,
    required this.etiket,
    required this.renk,
  });
}

class SensorTrendGrafigi extends StatefulWidget {
  final String baslik;
  final String birim;
  final Color renk;

  /// UygulamaDurumu.gecmis(zone) formatında, EN YENİ ÖNCE sıralı.
  final List<SensorOkuma> gecmisEnYeniOnce;
  final double Function(SensorOkuma) secici;
  final List<EsikCizgisi> esikler;

  /// Verilirse dönem DIŞARIDAN kontrol edilir (kendi SegmentedButton'ını
  /// GÖSTERMEZ) -- Trend Analizi ekranında 6 grafiğin TEK bir paylaşılan
  /// dönem seçiciye bağlı olması için (Zon Detay'daki tek-grafik kullanımı
  /// bunu vermez, kendi iç durumunu yönetmeye devam eder -- geriye dönük
  /// uyumlu).
  final TrendDonemi? donem;

  const SensorTrendGrafigi({
    super.key,
    required this.baslik,
    required this.birim,
    required this.renk,
    required this.gecmisEnYeniOnce,
    required this.secici,
    this.esikler = const [],
    this.donem,
  });

  @override
  State<SensorTrendGrafigi> createState() => _SensorTrendGrafigiState();
}

class _SensorTrendGrafigiState extends State<SensorTrendGrafigi> {
  TrendDonemi _icDonem = TrendDonemi.saat24;

  bool get _disaridanKontrol => widget.donem != null;
  TrendDonemi get _etkinDonem => widget.donem ?? _icDonem;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final simdi = DateTime.now();
    final sinir = simdi.subtract(_etkinDonem.pencere);
    final kronolojik = widget.gecmisEnYeniOnce
        .where((o) => o.zaman.isAfter(sinir))
        .toList()
        .reversed
        .toList();
    final degerler = kronolojik.map(widget.secici).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.baslik} Eğilimi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_disaridanKontrol)
                  SegmentedButton<TrendDonemi>(
                    segments: TrendDonemi.values
                        .map(
                          (d) =>
                              ButtonSegment(value: d, label: Text(d.etiket)),
                        )
                        .toList(),
                    selected: {_icDonem},
                    showSelectedIcon: false,
                    onSelectionChanged: (secim) =>
                        setState(() => _icDonem = secim.first),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: degerler.length < 2
                  ? Center(
                      child: Text(
                        'Bu dönem için yeterli veri yok',
                        style: TextStyle(color: onSurfaceVariant),
                      ),
                    )
                  : _grafik(degerler),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grafik(List<double> degerler) {
    final tumDegerler = [...degerler, ...widget.esikler.map((e) => e.deger)];
    final minDeger = tumDegerler.reduce(math.min);
    final maxDeger = tumDegerler.reduce(math.max);
    final pay = (maxDeger - minDeger) * 0.15 + 0.01;

    return LineChart(
      LineChartData(
        minY: minDeger - pay,
        maxY: maxDeger + pay,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (deger, meta) => Text(
                deger.toStringAsFixed(deger.abs() < 10 ? 1 : 0),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: widget.esikler
              .map(
                (esik) => HorizontalLine(
                  y: esik.deger,
                  color: esik.renk,
                  strokeWidth: 1.5,
                  dashArray: const [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: esik.renk,
                    ),
                    labelResolver: (_) => esik.etiket,
                  ),
                ),
              )
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < degerler.length; i++)
                FlSpot(i.toDouble(), degerler[i]),
            ],
            isCurved: true,
            color: widget.renk,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: widget.renk.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
