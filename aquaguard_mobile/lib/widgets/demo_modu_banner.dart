/// AquaGuard - Demo Modu Bilgi Seridi
/// ======================================
///
/// Amac:
///   Demo modu aktifken ekranin ustunde surekli gorunen, gosterilen
///   verilerin SIMULE EDILMIS oldugunu acikca belirten bir serit. Bu,
///   demo verisinin yanlislikla gercek saha verisi sanilmasini onler --
///   hem kullanici hem jüri icin seffaflik onemlidir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

class DemoModuBanner extends StatelessWidget {
  final VoidCallback onAyarlaraGit;

  const DemoModuBanner({super.key, required this.onAyarlaraGit});

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;

    return Material(
      color: renkSemasi.tertiaryContainer,
      child: InkWell(
        onTap: onAyarlaraGit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: renkSemasi.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DEMO MODU — gösterilen veriler simüle edilmiştir, gerçek sensör verisi değildir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: renkSemasi.onTertiaryContainer,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: renkSemasi.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
