/// AquaGuard - 6 Sensor Tanimi (Tek Kaynak)
/// =============================================
///
/// Amac:
///   AquaGuard'in 6 sensorunun (pH, EC, ORP, Türbidite, Debi, ΔBasınç)
///   goruntuleme meta verisini (baslik/birim/renk/ikon/deger secici/esik
///   cizgileri) TEK bir yerde tanimlar -- Zon Detay ekrani (Asama 3'te
///   eklendi) ve Trend Analizi ekrani (Oncelik 9) AYNI listeyi kullanir,
///   6 sensor tanimi iki yerde elle kopyalanmaz (bkz. proje hafizasindaki
///   "Schema single source of truth" ilkesi).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';

import '../config/sensor_imzalari.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/sensor_trend_grafigi.dart';
import 'sensor_okuma.dart';

class SensorTanimi {
  final String baslik;
  final String birim;
  final Color renk;
  final IconData ikon;
  final double Function(SensorOkuma) secici;
  final List<EsikCizgisi> esikler;
  // sensorImzalari (config/sensor_imzalari.dart) haritasindaki anahtarla
  // BIREBIR ayni -- sensor saglik degerlendirmesi (arıza tespiti) bu
  // sensorun 'normal' sinif std sapmasini burdan bulur.
  final String anahtar;
  // Gauge gostergesinin (widgets/sensor_gauge_widget.dart) gorsel alt/ust
  // siniri -- fiziksel olarak MUMKUN olan gercekci bir aralik (dort sinif
  // imzasinin da rahatca sigdigi, asiri genis olmayan bir bant). Karar
  // esikleriyle (esikler) KARISTIRILMAMALI -- bu sadece gauge'in cizim
  // araligidir.
  final double minDeger;
  final double maxDeger;

  const SensorTanimi({
    required this.baslik,
    required this.birim,
    required this.renk,
    required this.ikon,
    required this.secici,
    required this.anahtar,
    required this.minDeger,
    required this.maxDeger,
    this.esikler = const [],
  });
}

final sensorTanimlari = <SensorTanimi>[
  SensorTanimi(
    baslik: 'pH',
    birim: '',
    renk: const Color(0xFF6D4C41),
    ikon: Icons.science,
    secici: (o) => o.ph,
    anahtar: 'ph',
    minDeger: 0,
    maxDeger: 14,
  ),
  SensorTanimi(
    baslik: 'EC',
    birim: 'mS/cm',
    renk: const Color(0xFF00838F),
    ikon: Icons.bolt,
    secici: (o) => o.ec,
    anahtar: 'ec',
    minDeger: 0,
    maxDeger: 5,
  ),
  SensorTanimi(
    baslik: 'ORP',
    birim: 'mV',
    renk: const Color(0xFF6A1B9A),
    ikon: Icons.swap_vert,
    secici: (o) => o.orp,
    anahtar: 'orp',
    minDeger: 0,
    maxDeger: 600,
  ),
  SensorTanimi(
    baslik: 'Türbidite',
    birim: 'NTU',
    renk: const Color(0xFFEF6C00),
    ikon: Icons.blur_on,
    secici: (o) => o.turbidite,
    anahtar: 'turbidite',
    minDeger: 0,
    maxDeger: 50,
    esikler: [
      EsikCizgisi(
        deger: turbiditeEsigi,
        etiket: 'Eşik ${turbiditeEsigi.toStringAsFixed(0)} NTU',
        renk: DurumRenkleri.tespitEdildi,
      ),
    ],
  ),
  SensorTanimi(
    baslik: 'Debi',
    birim: 'LPM',
    renk: const Color(0xFF1565C0),
    ikon: Icons.water,
    secici: (o) => o.debi,
    anahtar: 'debi',
    minDeger: 0,
    maxDeger: 6,
    esikler: [
      EsikCizgisi(
        deger: referansDebi - debiDususEsigi,
        etiket:
            'Alt sınır ${(referansDebi - debiDususEsigi).toStringAsFixed(1)} LPM',
        renk: DurumRenkleri.tespitEdildi,
      ),
    ],
  ),
  SensorTanimi(
    baslik: 'ΔBasınç',
    birim: 'bar',
    renk: const Color(0xFFC62828),
    ikon: Icons.speed,
    secici: (o) => o.deltaBasinc,
    anahtar: 'delta_basinc',
    minDeger: 0,
    maxDeger: 1,
    esikler: [
      EsikCizgisi(
        deger: basincArtisEsigi,
        etiket: 'Üst sınır ${basincArtisEsigi.toStringAsFixed(2)} bar',
        renk: DurumRenkleri.tespitEdildi,
      ),
    ],
  ),
];
