/// AquaGuard - Ana Kabuk (Alt Navigasyon)
/// ==========================================
///
/// Amac:
///   Uygulamanin 4 ana bolumunu (Genel Bakış, Tarlalar, İstatistikler,
///   Ayarlar) alt navigasyon cubugu ile birbirine baglar. IndexedStack
///   kullanilir ki sekmeler arasi gecişte her ekranin durumu (scroll
///   pozisyonu, form girdileri vb.) KORUNSUN -- her sekme degisiminde
///   sifirdan olusturulmasin.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import 'ayarlar_ekrani.dart';
import 'genel_bakis_ekrani.dart';
import 'istatistikler_ekrani.dart';
import 'tarla_secim_ekrani.dart';

class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key});

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

class _AnaKabukState extends State<AnaKabuk> {
  int _seciliSekme = 0;

  static const _ekranlar = [
    GenelBakisEkrani(),
    TarlaSecimEkrani(),
    IstatistiklerEkrani(),
    AyarlarEkrani(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _seciliSekme, children: _ekranlar),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSekme,
        onDestinationSelected: (index) => setState(() => _seciliSekme = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Genel Bakış'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass), label: 'Tarlalar'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'İstatistikler'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
