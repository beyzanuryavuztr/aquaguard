/// AquaGuard - Besin Takviyesi Ekrani (Faz 3)
/// ===============================================
///
/// Amac:
///   Operatorun, tikanma teshisinden TAMAMEN BAGIMSIZ olarak (orn. bir
///   ziraatcinin onerdigi demir eksikligi takviyesi gibi) bir sivi veya
///   toz maddeyi ana sulama hattina vermesini saglar. Bu ekran, Uzaktan
///   Sulama ekraniyla AYNI tarla+coklu-zon secim desenini kullanir, ama
///   sure girme YOK -- besin dozlama sureleri firmware'de SABIT
///   (config.h TEDAVI_BESIN_SIVI_SURESI_MS/TEDAVI_BESIN_TOZ_SURESI_MS).
///
///   GUVENLIK: her zon, kendi mutex kilidine tabidir (asit/klor/yikama ile
///   AYNI kilit) -- bir zon zaten bir tedavi/durulama surduruyorsa bu
///   dozlama REDDEDILIR (cihazIletisimProvider.besinDozlamaBaslat bunu
///   otomatik yonetir, bu ekran sadece sonucu gosterir).
///
/// Tarih:  2026-09-25
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bekleyen_komut.dart';
import '../models/sensor_okuma.dart';
import '../providers/cihaz_iletisim_provider.dart';
import '../providers/tarla_provider.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/yardim_butonu.dart';

class BesinTakviyesiEkrani extends StatefulWidget {
  const BesinTakviyesiEkrani({super.key});

  @override
  State<BesinTakviyesiEkrani> createState() => _BesinTakviyesiEkraniState();
}

class _BesinTakviyesiEkraniState extends State<BesinTakviyesiEkrani> {
  String? _seciliTarlaId;
  final Set<int> _seciliZonlar = {};
  bool _baslatiliyor = false;

  @override
  Widget build(BuildContext context) {
    final tarlaProvider = context.watch<TarlaProvider>();
    final tarlalar = tarlaProvider.tarlalar;

    final seciliTarla = tarlalar.isEmpty
        ? null
        : (tarlalar.where((t) => t.id == _seciliTarlaId).firstOrNull ??
              tarlalar.first);
    if (seciliTarla != null && _seciliTarlaId != seciliTarla.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _seciliTarlaId = seciliTarla.id);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Besin Takviyesi'),
        actions: const [
          YardimButonu(
            ekranAnahtari: 'besin_takviyesi',
            baslik: 'Besin Takviyesi',
          ),
        ],
      ),
      body: DuyarliIcerik(
        child: tarlalar.isEmpty
            ? const Center(child: Text('Henüz kayıtlı bir çiftlik yok'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Bu, tıkanma tedavisinden bağımsız bir işlemdir — örn. '
                      'ziraat mühendisinin önerdiği bir besin takviyesini '
                      'sulama suyuna katmak için kullanılır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text('Çiftlik', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tarla in tarlalar)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tarla.ad),
                              selected: seciliTarla?.id == tarla.id,
                              onSelected: (_) => setState(() {
                                _seciliTarlaId = tarla.id;
                                _seciliZonlar.clear();
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (seciliTarla != null) ...[
                    Text(
                      'Hedef Zon(lar)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final zon in seciliTarla.zonNumaralari)
                          FilterChip(
                            label: Text(tarlaProvider.zonAdiGetir(zon)),
                            selected: _seciliZonlar.contains(zon),
                            onSelected: (secildi) => setState(() {
                              if (secildi) {
                                _seciliZonlar.add(zon);
                              } else {
                                _seciliZonlar.remove(zon);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: (_seciliZonlar.isEmpty || _baslatiliyor)
                          ? null
                          : () => _baslat(context, TedaviTuru.besinSivi),
                      icon: const Icon(Icons.water_drop_outlined),
                      label: const Text('Sıvı Takviye Başlat'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: (_seciliZonlar.isEmpty || _baslatiliyor)
                          ? null
                          : () => _baslat(context, TedaviTuru.besinToz),
                      icon: const Icon(Icons.grain_outlined),
                      label: const Text('Toz Takviye Başlat'),
                    ),
                    if (_seciliZonlar.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Önce hedef zon(lar)ı seçin',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _baslat(BuildContext context, TedaviTuru tedavi) async {
    setState(() => _baslatiliyor = true);
    final cihaz = context.read<CihazIletisimProvider>();
    final zonlar = List<int>.from(_seciliZonlar);
    var basariliSayisi = 0;
    for (final zon in zonlar) {
      final sonuc = await cihaz.besinDozlamaBaslat(zon, tedavi);
      if (sonuc == KomutSonucu.uygulandi) basariliSayisi++;
    }

    if (!context.mounted) return;
    setState(() => _baslatiliyor = false);

    final mesaj = basariliSayisi == zonlar.length
        ? '${tedaviEtiketi(tedavi)}: $basariliSayisi zonda başlatıldı'
        : '${tedaviEtiketi(tedavi)}: ${zonlar.length} zondan sadece '
              '$basariliSayisi tanesinde başlatılabildi (diğerleri meşgul '
              'olabilir, bağlantı olmayabilir)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
    setState(_seciliZonlar.clear);
  }
}
