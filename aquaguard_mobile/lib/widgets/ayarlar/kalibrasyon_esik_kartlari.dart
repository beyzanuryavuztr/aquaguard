/// AquaGuard - Kalibrasyon + Esik Degerleri Kartlari (Ayarlar bolumu)
/// ========================================================================
///
/// Amac:
///   Salt-okunur sabitler (sensor kalibrasyonu + karar motoru esikleri) --
///   hicbir provider'a bagimli DEGILDIR, `config/kalibrasyon_sabitleri.dart`
///   ve `config/sensor_imzalari.dart`'taki sabitleri dogrudan gosterir.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi.
library;

import 'package:flutter/material.dart';

import '../../config/kalibrasyon_sabitleri.dart';
import '../../config/sensor_imzalari.dart';

class KalibrasyonKarti extends StatelessWidget {
  const KalibrasyonKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salt okunur -- kalibrasyon Deneyap Kart üzerinde saha tampon '
              'çözeltileriyle (pH 4.01/6.86/9.18, EC 1.413/12.88 mS/cm, '
              'ORP 225/475 mV) yapılır.',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _degerSatiri('pH ofset', KalibrasyonSabitleri.phOfset.toString()),
            _degerSatiri('pH eğim', KalibrasyonSabitleri.phEgim.toString()),
            _degerSatiri(
              'pH nötr voltaj',
              '${KalibrasyonSabitleri.phNotrVoltaj} V',
            ),
            const Divider(height: 20),
            _degerSatiri('EC ofset', KalibrasyonSabitleri.ecOfset.toString()),
            _degerSatiri('EC eğim', KalibrasyonSabitleri.ecEgim.toString()),
            const Divider(height: 20),
            _degerSatiri(
              'ORP ofset voltaj',
              '${KalibrasyonSabitleri.orpOfsetVoltaj} V',
            ),
            _degerSatiri(
              'ORP kazanç',
              '${KalibrasyonSabitleri.orpKazanc} mV/V',
            ),
            const Divider(height: 20),
            _degerSatiri(
              'Türbidite temiz su voltajı',
              '${KalibrasyonSabitleri.turbiditeTemizVoltaj} V',
            ),
            _degerSatiri(
              'Türbidite eğim',
              '${KalibrasyonSabitleri.turbiditeEgim} NTU/V',
              sonSatir: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _degerSatiri(String etiket, String deger, {bool sonSatir = false}) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: sonSatir ? 0 : 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                etiket,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(deger, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class EsikDegerleriKarti extends StatelessWidget {
  const EsikDegerleriKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salt okunur -- Katman 1 (kural tabanlı) karar motorunun '
              'kullandığı sabit eşikler.',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _esikSatiri(context, 'Referans debi', '$referansDebi LPM'),
            _esikSatiri(context, 'Debi düşüş eşiği', '$debiDususEsigi LPM'),
            _esikSatiri(context, 'Basınç artış eşiği', '$basincArtisEsigi bar'),
            _esikSatiri(context, 'Türbidite eşiği', '$turbiditeEsigi NTU'),
            _esikSatiri(
              context,
              'Güven eşiği (belirsiz sınırı)',
              '%$guvenEsigi',
              sonSatir: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _esikSatiri(
    BuildContext context,
    String etiket,
    String deger, {
    bool sonSatir = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: sonSatir ? 0 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              etiket,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
