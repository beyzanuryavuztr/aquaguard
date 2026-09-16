/// AquaGuard - Sensor Gauge (Tekil Sensor Dairesel Gostergesi)
/// =================================================================
///
/// Amac:
///   Zon Detay'da secilen sensorun GUNCEL degerini, `SistemSagligiGostergesi`
///   (Genel Bakis'taki dairesel gosterge) ile AYNI cizim deseninde
///   (`CircularProgressIndicator` + `TweenAnimationBuilder`, YENI bir
///   CustomPainter DEGIL -- var olan desen tekrar kullanilir) gosterir.
///   Ham sayilar (orn. "pH: 7.2") bir ciftci icin soyut kalir; bu gosterge
///   degerin kendi olasi araliginda NEREDE oldugunu gorsellestirir.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/material.dart';

import 'durum_renkleri.dart';

class SensorGaugeWidget extends StatelessWidget {
  final double deger;
  final double minDeger;
  final double maxDeger;
  final String birim;
  final Color renk;
  final double boyut;

  const SensorGaugeWidget({
    super.key,
    required this.deger,
    required this.minDeger,
    required this.maxDeger,
    required this.birim,
    required this.renk,
    this.boyut = 96,
  });

  @override
  Widget build(BuildContext context) {
    final aralik = maxDeger - minDeger;
    final oran = aralik == 0
        ? 0.0
        : ((deger - minDeger) / aralik).clamp(0.0, 1.0);

    return SizedBox(
      width: boyut,
      height: boyut,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: boyut,
            height: boyut,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: oran),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 8,
                backgroundColor: renk.izTonu,
                color: renk,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                deger.toStringAsFixed(deger.abs() < 10 ? 2 : 0),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
              if (birim.isNotEmpty)
                Text(
                  birim,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
