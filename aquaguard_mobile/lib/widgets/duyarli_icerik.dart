/// AquaGuard - Duyarli (Responsive) Icerik Sarici
/// ===================================================
///
/// Amac:
///   TUM ekranlarin ortak sorunu: brief acikca "once web/Chrome test"
///   diyor, yani birincil gorunum genis bir masaustu tarayici penceresidir
///   -- ama icerik mobil genislikte tasarlanmisti. 1440px genis bir
///   pencerede kartlar kenardan kenara gerilip devasa bos alanlar
///   birakiyordu (ucuz/yarim kalmis izlenimi veriyordu).
///
///   Bu widget, genis ekranlarda icerigi MAKUL bir maksimum genislikte
///   ortalar (profesyonel web dashboard'larinin -- Stripe, Linear, Notion
///   vb. -- hepsinin yaptigi gibi); dar (mobil) ekranlarda ise hicbir
///   fark yaratmaz, icerik zaten tam genislikte kalir.
///
/// Tarih:  2026-09-02
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

class DuyarliIcerik extends StatelessWidget {
  final Widget child;
  final double maksimumGenislik;

  const DuyarliIcerik({
    super.key,
    required this.child,
    this.maksimumGenislik = 900,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maksimumGenislik),
        child: child,
      ),
    );
  }
}

/// Genis ekran esigi: bu genislikten itibaren masaustu duzeni (yan
/// navigasyon rayi, ortalanmis icerik) devreye girer.
const double genisEkranEsigi = 900;

bool genisEkranMi(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= genisEkranEsigi;
