/// AquaGuard - Ana Kabuk (Duyarli Navigasyon)
/// ===============================================
///
/// Amac:
///   Uygulamanin 4 ana bolumunu (Genel Bakış, Tarlalar, İstatistikler,
///   Ayarlar) birbirine baglar. IndexedStack kullanilir ki sekmeler arasi
///   gecişte her ekranin durumu (scroll pozisyonu, form girdileri vb.)
///   KORUNSUN -- her sekme degisiminde sifirdan olusturulmasin.
///
///   DUYARLI DAVRANIS: brief "once web/Chrome test" diyor -- yani birincil
///   yuzey genis bir masaustu tarayici penceresidir. Dar (mobil) ekranda alt
///   navigasyon cubugu (NavigationBar), genis (masaustu) ekranda ise SOL
///   NAVIGASYON RAYI (NavigationRail) gosterilir -- bu, Material 3'un
///   resmi "adaptive navigation" onerisidir ve masaustu web
///   dashboard'larinin standart deseni (VS Code, Notion, Linear vb.).
///   Mobil bir uygulamanin genis pencerede uzayip gitmesi yerine, genis
///   ekranda GERCEKTEN masaustu icin tasarlanmis gibi gorunur.
///
/// Tarih:  2026-09-01 (guncelleme: 2026-09-02 -- duyarli rayli navigasyon)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../widgets/duyarli_icerik.dart';
import 'ayarlar_ekrani.dart';
import 'genel_bakis_ekrani.dart';
import 'istatistikler_ekrani.dart';
import 'tarla_secim_ekrani.dart';

class _SekmeTanimi {
  final Widget ekran;
  final IconData ikon;
  final IconData seciliIkon;
  final String etiket;

  const _SekmeTanimi({
    required this.ekran,
    required this.ikon,
    required this.seciliIkon,
    required this.etiket,
  });
}

class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key});

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

class _AnaKabukState extends State<AnaKabuk> {
  int _seciliSekme = 0;

  static const _sekmeler = [
    _SekmeTanimi(
      ekran: GenelBakisEkrani(),
      ikon: Icons.dashboard_outlined,
      seciliIkon: Icons.dashboard,
      etiket: 'Genel Bakış',
    ),
    _SekmeTanimi(
      ekran: TarlaSecimEkrani(),
      ikon: Icons.grass_outlined,
      seciliIkon: Icons.grass,
      etiket: 'Tarlalar',
    ),
    _SekmeTanimi(
      ekran: IstatistiklerEkrani(),
      ikon: Icons.bar_chart_outlined,
      seciliIkon: Icons.bar_chart,
      etiket: 'İstatistikler',
    ),
    _SekmeTanimi(
      ekran: AyarlarEkrani(),
      ikon: Icons.settings_outlined,
      seciliIkon: Icons.settings,
      etiket: 'Ayarlar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final icerik = IndexedStack(
      index: _seciliSekme,
      children: [for (final s in _sekmeler) s.ekran],
    );

    if (genisEkranMi(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _seciliSekme,
              onDestinationSelected: (index) => setState(() => _seciliSekme = index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'AquaGuard',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              destinations: [
                for (final s in _sekmeler)
                  NavigationRailDestination(
                    icon: Icon(s.ikon),
                    selectedIcon: Icon(s.seciliIkon),
                    label: Text(s.etiket),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: icerik),
          ],
        ),
      );
    }

    return Scaffold(
      body: icerik,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSekme,
        onDestinationSelected: (index) => setState(() => _seciliSekme = index),
        destinations: [
          for (final s in _sekmeler)
            NavigationDestination(icon: Icon(s.ikon), selectedIcon: Icon(s.seciliIkon), label: s.etiket),
        ],
      ),
    );
  }
}
