/// AquaGuard - Aktivite Kaydi Veri Modeli
/// ==========================================
///
/// Amac:
///   Uygulama genelinde ("Genel Bakış" ekraninda) gosterilen, tum
///   zonlardaki onemli olaylarin (durum degisikligi, tedavi baslangici/
///   bitisi) KALICI (uygulama acikken bellekte tutulan) kaydidir. Transient
///   SnackBar bildirimlerinden farkli olarak, bu liste bir ekranda
///   goruntulenip geriye donup incelenebilir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

enum AktiviteTuru { tespit, belirsiz, normaleDonus, tedaviBaslangic, tedaviBitis }

class AktiviteKaydi {
  final DateTime zaman;
  final int zone;
  final String mesaj;
  final AktiviteTuru tur;

  const AktiviteKaydi({
    required this.zaman,
    required this.zone,
    required this.mesaj,
    required this.tur,
  });

  IconData get ikon {
    switch (tur) {
      case AktiviteTuru.tespit:
        return Icons.warning_amber;
      case AktiviteTuru.belirsiz:
        return Icons.help_outline;
      case AktiviteTuru.normaleDonus:
        return Icons.check_circle_outline;
      case AktiviteTuru.tedaviBaslangic:
        return Icons.build_circle_outlined;
      case AktiviteTuru.tedaviBitis:
        return Icons.water_drop_outlined;
    }
  }

  Color renkGetir(BuildContext context) {
    switch (tur) {
      case AktiviteTuru.tespit:
        return const Color(0xFFC62828);
      case AktiviteTuru.belirsiz:
        return const Color(0xFFF9A825);
      case AktiviteTuru.normaleDonus:
        return const Color(0xFF2E7D32);
      case AktiviteTuru.tedaviBaslangic:
      case AktiviteTuru.tedaviBitis:
        return const Color(0xFF1565C0);
    }
  }

  Map<String, dynamic> toJson() => {
        'zaman': zaman.toIso8601String(),
        'zone': zone,
        'mesaj': mesaj,
        'tur': tur.name,
      };

  factory AktiviteKaydi.fromJson(Map<String, dynamic> json) => AktiviteKaydi(
        zaman: DateTime.tryParse(json['zaman'] as String? ?? '') ?? DateTime.now(),
        zone: (json['zone'] as num?)?.toInt() ?? 0,
        mesaj: json['mesaj'] as String? ?? '',
        tur: AktiviteTuru.values.firstWhere(
          (e) => e.name == json['tur'],
          orElse: () => AktiviteTuru.normaleDonus,
        ),
      );
}
