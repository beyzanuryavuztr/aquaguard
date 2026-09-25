/// AquaGuard - Ayarlar Kategorisi (Katlanir Ust Grup)
/// =========================================================
///
/// Amac:
///   ACIMASIZ DENETIM (2026-09-25): Ayarlar ekrani 15 ayri bolumu TEK,
///   duz ve uzun bir listede gosteriyordu ("MQTT ayarini degistir" ile
///   "zon ismini degistir" ayni listede yan yana) -- kullanicinin
///   "arayuz karmasik" hissinin en buyuk kaynaklarindan biriydi, cunku
///   istedigi ayari bulmak icin surekli asagi kaydirmasi gerekiyordu.
///
///   Bu widget, ilgili bolumleri TEK bir katlanir (ExpansionTile) ust
///   kategori altinda toplar -- ic icerik (her bolumun kendi karti/
///   BolumBasligi'i) HICBIR SEKILDE degistirilmedi, sadece bir ust
///   gruplama katmani eklendi. Varsayilan olarak KAPALI: kullanici
///   Ayarlar'i actiginda sadece 5 kategori basligini gorur, istedigine
///   dokunup genisletir.
library;

import 'package:flutter/material.dart';

class AyarlarKategorisi extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final List<Widget> children;

  const AyarlarKategorisi({
    super.key,
    required this.baslik,
    required this.ikon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(ikon, color: Theme.of(context).colorScheme.primary),
          title: Text(
            baslik,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
