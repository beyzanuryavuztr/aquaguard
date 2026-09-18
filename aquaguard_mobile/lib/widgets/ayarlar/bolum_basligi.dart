/// AquaGuard - Ayarlar Bolum Basligi
/// =====================================
///
/// Amac:
///   Ayarlar ekranindaki her kart grubunun ustunde tekrarlanan kucuk,
///   vurgulu baslik metni. `ayarlar_ekrani.dart`'in A6 (bolunme) fazinda
///   `lib/widgets/ayarlar/` altindaki tum bolum widget'lari bunu paylasir.
library;

import 'package:flutter/material.dart';

class BolumBasligi extends StatelessWidget {
  final String baslik;
  const BolumBasligi({super.key, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        baslik,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
