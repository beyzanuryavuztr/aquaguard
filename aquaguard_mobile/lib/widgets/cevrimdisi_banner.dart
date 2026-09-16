/// AquaGuard - Cihaz Cevrimdisi Bilgi Seridi (Offline Mod)
/// ==============================================================
///
/// Amac:
///   Gercek MQTT modunda (Demo Modu KAPALIYKEN) cihazin (telefonun) kendi
///   ag baglantisi YOKKEN gosterilir. `DemoModuBanner` ile AYNI gorsel
///   desen -- ikisi ASLA ayni anda gorunmez (biri demo, digeri gercek
///   moddaki bir aglama sorunu). Bu banner, MQTT broker baglanti
///   durumundan (`_BaglantiDurumSatiri`/`_BaglantiRozeti`) FARKLIDIR --
///   o "brokera bagli miyiz", bu "telefonda internet var mi" sorusuna
///   cevap verir (bkz. UygulamaDurumu.cihazBagliMi dosya ici notu).
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/material.dart';

class CevrimdisiBanner extends StatelessWidget {
  const CevrimdisiBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;

    return Material(
      color: renkSemasi.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              size: 18,
              color: renkSemasi.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'CİHAZ ÇEVRİMDIŞI — komutlar bağlantı gelince gönderilecek, '
                'gösterilen veriler son bilinen durumdur',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: renkSemasi.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
