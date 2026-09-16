/// AquaGuard - Baglamsal Yardim Butonu
/// ========================================
///
/// Amac:
///   AppBar.actions'a eklenebilecek tek bir "?" ikonu -- dokununca
///   `models/yardim_metinleri.dart`'taki ilgili ekranin aciklamasini bir
///   `showModalBottomSheet` ile gosterir. Teknik olmayan (ciftci) bir
///   operatorun her yeni ekranda "bu ne demek?" sorusuna karsilik verir.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/material.dart';

import '../models/yardim_metinleri.dart';

class YardimButonu extends StatelessWidget {
  final String ekranAnahtari;
  final String baslik;

  const YardimButonu({
    super.key,
    required this.ekranAnahtari,
    required this.baslik,
  });

  @override
  Widget build(BuildContext context) {
    final metin = yardimMetinleri[ekranAnahtari];
    if (metin == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Bu ekran hakkında',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(metin, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
