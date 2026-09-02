/// AquaGuard - Sensor Imzalari (Literatur Tabanli Referans Degerler)
/// =======================================================================
///
/// Amac:
///   PROJE_BRIEF.md SS6 tablosundaki "ortalama +/- std" degerlerinin Dart
///   karsiligi. Simulasyon servisi (demo modu) bu degerleri kullanarak
///   gercekci sensor senaryolari uretir.
///
/// ONEMLI - TEK KAYNAK UYARISI:
///   Bu tablo, ayni sayilarin DORDUNCU kopyasidir:
///     1) python/aquaguard_veri_uretici.py  -> SENSOR_IMZALARI
///     2) python/aquaguard_karar_motoru.py  -> ayni modulden ice aktarilir
///     3) firmware/config.h                 -> IMZA_* sabitleri
///     4) BU DOSYA                          -> Dart/Flutter tarafi
///   Kaynak veri PROJE_BRIEF.md SS6'dir. Biri degisirse DORDU DE guncellenmelidir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

/// Tek bir sensorun (ortalama, standart sapma) cifti.
class SensorImzasi {
  final double ortalama;
  final double std;
  const SensorImzasi(this.ortalama, this.std);
}

/// Sinif adi -> {sensor adi -> imza} haritasi.
const Map<String, Map<String, SensorImzasi>> sensorImzalari = {
  'normal': {
    'ph': SensorImzasi(7.00, 0.30),
    'ec': SensorImzasi(1.15, 0.20),
    'orp': SensorImzasi(375, 40),
    'turbidite': SensorImzasi(3, 1.2),
    'debi': SensorImzasi(4.0, 0.25),
    'delta_basinc': SensorImzasi(0.10, 0.03),
  },
  'kimyasal': {
    'ph': SensorImzasi(8.30, 0.30),
    'ec': SensorImzasi(2.75, 0.45),
    'orp': SensorImzasi(310, 40),
    'turbidite': SensorImzasi(10, 3),
    'debi': SensorImzasi(2.6, 0.35),
    'delta_basinc': SensorImzasi(0.40, 0.09),
  },
  'biyolojik': {
    'ph': SensorImzasi(6.60, 0.35),
    'ec': SensorImzasi(1.50, 0.30),
    'orp': SensorImzasi(175, 45),
    'turbidite': SensorImzasi(20, 5.5),
    'debi': SensorImzasi(3.0, 0.30),
    'delta_basinc': SensorImzasi(0.32, 0.07),
  },
  'fiziksel': {
    'ph': SensorImzasi(7.00, 0.30),
    'ec': SensorImzasi(1.15, 0.20),
    'orp': SensorImzasi(350, 40),
    'turbidite': SensorImzasi(35, 8),
    'debi': SensorImzasi(1.8, 0.45),
    'delta_basinc': SensorImzasi(0.60, 0.12),
  },
};

const List<String> sensorSirasi = [
  'ph',
  'ec',
  'orp',
  'turbidite',
  'debi',
  'delta_basinc',
];

// --- Katman 1 kural esikleri -- config.h / aquaguard_karar_motoru.py ile ayni ---
const double referansDebi = 4.0;
const double debiDususEsigi = 1.5;
const double basincArtisEsigi = 0.36;
const double turbiditeEsigi = 12.0;
const double guvenEsigi = 50.0;
