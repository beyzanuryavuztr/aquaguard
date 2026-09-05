/// AquaGuard - Mutex Kilit Gostergesi
/// =====================================
///
/// Amac:
///   Firmware'deki (treatment.h) gercek guvenlik kuralinin GORSEL karsiligi:
///   asit dozlama, klor enjeksiyonu ve yuksek basincli yikama kanallarindan
///   AYNI ANDA sadece BIRI calisabilir (mutex kilit). Bu widget 3 kanali
///   yan yana gosterip, biri aktifken digerlerini "kilitli" olarak isaretler
///   -- operatorun "neden su an baska bir tedavi baslatamiyorum" sorusuna
///   ekranin kendisinden cevap bulmasini saglar.
///
///   Yeni bir state GEREKMEZ: `okuma.tedaviAktif` zaten hangi kanalin aktif
///   oldugunu bilgilendirmeye yeter.
///
/// Tarih:  2026-09-04
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';
import 'durum_renkleri.dart';

class MutexKilitGostergesi extends StatelessWidget {
  final TedaviTuru aktifTedavi;

  const MutexKilitGostergesi({super.key, required this.aktifTedavi});

  static const _kanallar = [
    (TedaviTuru.asitDozlama, Icons.science_outlined, 'Asit'),
    (TedaviTuru.klorEnjeksiyon, Icons.water_drop_outlined, 'Klor'),
    (
      TedaviTuru.yuksekBasincliYikama,
      Icons.cleaning_services_outlined,
      'Yıkama',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Tedavi Kanalı Kilidi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Güvenlik gereği aynı anda yalnızca bir tedavi kanalı çalışabilir.',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final kanal in _kanallar)
                  Expanded(
                    child: _KanalGostergesi(
                      ikon: kanal.$2,
                      etiket: kanal.$3,
                      aktifMi: kanal.$1 == aktifTedavi,
                      kilitliMi:
                          aktifTedavi != TedaviTuru.yok &&
                          kanal.$1 != aktifTedavi,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KanalGostergesi extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final bool aktifMi;
  final bool kilitliMi;

  const _KanalGostergesi({
    required this.ikon,
    required this.etiket,
    required this.aktifMi,
    required this.kilitliMi,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final renk = aktifMi
        ? DurumRenkleri.tedaviAktif
        : (kilitliMi ? onSurfaceVariant.withValues(alpha: 0.4) : onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: aktifMi
                      ? DurumRenkleri.tedaviAktif.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: renk, size: 22),
              ),
              if (kilitliMi)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            etiket,
            style: TextStyle(
              fontSize: 11,
              fontWeight: aktifMi ? FontWeight.bold : FontWeight.normal,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}
