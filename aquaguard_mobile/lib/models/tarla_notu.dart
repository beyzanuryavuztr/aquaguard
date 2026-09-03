/// AquaGuard - Tarla Notu Veri Modeli
/// ======================================
///
/// Amac:
///   Operatorun bir tarlaya dair SERBEST METIN notlar tutmasini saglar
///   (ornegin "15.09'da gubreleme yapildi", "komsu parselde insaat var,
///   toz/kirlilik artabilir"). AktiviteKaydi'ndan farki: AktiviteKaydi
///   SISTEM tarafindan otomatik uretilir (durum degisikligi, tedavi vb.);
///   TarlaNotu ise TAMAMEN operatorun kendi yazdigi, sensor/teshis
///   verisinden bagimsiz gozlem/hatirlatma kayitlaridir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

class TarlaNotu {
  final String id;
  final String tarlaId;
  final String metin;
  final DateTime zaman;

  const TarlaNotu({
    required this.id,
    required this.tarlaId,
    required this.metin,
    required this.zaman,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tarlaId': tarlaId,
    'metin': metin,
    'zaman': zaman.toIso8601String(),
  };

  factory TarlaNotu.fromJson(Map<String, dynamic> json) => TarlaNotu(
    id: json['id'] as String,
    tarlaId: json['tarlaId'] as String,
    metin: json['metin'] as String,
    zaman: DateTime.tryParse(json['zaman'] as String? ?? '') ?? DateTime.now(),
  );
}
