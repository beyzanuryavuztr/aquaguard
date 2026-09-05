/// AquaGuard - Trend Analizi Ekrani (Ekran 5)
/// =================================================
///
/// Amac:
///   Tek bir zon + tarih araligi secimine bagli olarak, o zonun 6
///   sensorunun TAMAMINI ayni sayfada, ayni zaman penceresinde gosterir.
///   Zon Detay ekranindaki `_SensorAnaliziBolumu` (Asama 3) TEK SEFERDE
///   bir sensore odaklanir (sekme secip buyutulmus grafigi gorursunuz);
///   bu ekran ise tum sensorleri YAN YANA (dikey listede) karsilastirmali
///   incelemek icindir -- operatorun "bu zon genelinde son 7 gunde ne
///   degisti" sorusuna tek bakista cevap vermesi hedeflenir.
///
///   `SensorTrendGrafigi`'nin PAYLASILAN dis-kontrol modu kullanilir (bkz.
///   widgets/sensor_trend_grafigi.dart -- `donem` parametresi verilirse
///   kendi ic SegmentedButton'ini gizler), boylece TEK bir donem secici
///   6 grafigin tamamini birlikte kontrol eder. Sensor tanimlari (baslik/
///   renk/esik) `models/sensor_tanimi.dart`'tan gelir -- Zon Detay ile
///   AYNI tek kaynak, iki yerde elle kopyalanmaz.
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../models/sensor_tanimi.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/sensor_trend_grafigi.dart';

class TrendAnaliziEkrani extends StatefulWidget {
  const TrendAnaliziEkrani({super.key});

  @override
  State<TrendAnaliziEkrani> createState() => _TrendAnaliziEkraniState();
}

class _TrendAnaliziEkraniState extends State<TrendAnaliziEkrani> {
  int? _seciliZon;
  TrendDonemi _donem = TrendDonemi.saat24;

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final tumZonlar = durum.tumZonNumaralari;
    final zon = _seciliZon != null && tumZonlar.contains(_seciliZon)
        ? _seciliZon!
        : (tumZonlar.isEmpty ? null : tumZonlar.first);
    final gecmisEnYeniOnce = zon == null
        ? const <SensorOkuma>[]
        : durum.gecmis(zon);

    return Scaffold(
      appBar: AppBar(title: const Text('Trend Analizi')),
      body: DuyarliIcerik(
        child: tumZonlar.isEmpty
            ? const Center(child: Text('Henüz izlenen bir zon yok'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Zon', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final z in tumZonlar)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(durum.zonAdiGetir(z)),
                              selected: zon == z,
                              onSelected: (_) =>
                                  setState(() => _seciliZon = z),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tarih Aralığı',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TrendDonemi>(
                    segments: TrendDonemi.values
                        .map(
                          (d) =>
                              ButtonSegment(value: d, label: Text(d.etiket)),
                        )
                        .toList(),
                    selected: {_donem},
                    showSelectedIcon: false,
                    onSelectionChanged: (secim) =>
                        setState(() => _donem = secim.first),
                  ),
                  const SizedBox(height: 20),
                  for (final tanim in sensorTanimlari) ...[
                    SensorTrendGrafigi(
                      key: ValueKey('${zon}_${tanim.baslik}'),
                      baslik: tanim.baslik,
                      birim: tanim.birim,
                      renk: tanim.renk,
                      gecmisEnYeniOnce: gecmisEnYeniOnce,
                      secici: tanim.secici,
                      esikler: tanim.esikler,
                      donem: _donem,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
      ),
    );
  }
}
