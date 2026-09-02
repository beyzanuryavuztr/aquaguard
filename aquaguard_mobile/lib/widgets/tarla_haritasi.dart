/// AquaGuard - Gorsel Tarla Haritasi
/// =====================================
///
/// Amac:
///   Tarlalarim ekraninin ikinci gorunum modu: her tarlayi bir "arazi
///   plani" bloku olarak, icindeki zonlari da renk kodlu birer parsel
///   karosu olarak gosterir. Gercek GPS/harita koordinati YOKTUR (proje
///   kapsaminda konum verisi toplanmiyor) -- bu bilincli bir tercihtir:
///   sahte/rastgele koordinatlar uydurmak yaniltici olur. Bunun yerine
///   SEMATIK bir arazi plani sunulur: tarla buyuklugu zon sayisiyla
///   orantili gorunur, her zon karosu tek bakista durumunu (yesil/sari/
///   kirmizi/mavi/gri) gosterir ve dokununca detay ekranina gecilir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';
import '../models/tarla.dart';
import '../providers/uygulama_durumu.dart';
import 'durum_renkleri.dart';

class TarlaHaritasi extends StatelessWidget {
  final List<Tarla> tarlalar;
  final UygulamaDurumu durum;
  final void Function(int zonNumarasi) onZonSecildi;

  const TarlaHaritasi({
    super.key,
    required this.tarlalar,
    required this.durum,
    required this.onZonSecildi,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const _HaritaLejandi(),
        const SizedBox(height: 16),
        for (final tarla in tarlalar) ...[
          _TarlaBloku(tarla: tarla, durum: durum, onZonSecildi: onZonSecildi),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _HaritaLejandi extends StatelessWidget {
  const _HaritaLejandi();

  @override
  Widget build(BuildContext context) {
    const girdiler = [
      (DurumRenkleri.normal, 'Normal'),
      (DurumRenkleri.belirsiz, 'Belirsiz'),
      (DurumRenkleri.tespitEdildi, 'Tespit'),
      (DurumRenkleri.tedaviAktif, 'Tedavide'),
      (DurumRenkleri.cevrimdisi, 'Çevrimdışı'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final girdi in girdiler)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: girdi.$1,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(girdi.$2, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

class _TarlaBloku extends StatelessWidget {
  final Tarla tarla;
  final UygulamaDurumu durum;
  final void Function(int zonNumarasi) onZonSecildi;

  const _TarlaBloku({
    required this.tarla,
    required this.durum,
    required this.onZonSecildi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grass,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                tarla.ad,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${tarla.zonNumaralari.length} parsel',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final zon in tarla.zonNumaralari)
                _ZonKarosu(
                  zonNumarasi: zon,
                  okuma: durum.sonOkuma(zon),
                  cevrimici: durum.zonCevrimiciMi(zon),
                  onTap: () => onZonSecildi(zon),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZonKarosu extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma? okuma;
  final bool cevrimici;
  final VoidCallback onTap;

  const _ZonKarosu({
    required this.zonNumarasi,
    required this.okuma,
    required this.cevrimici,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = DurumRenkleri.renkGetir(okuma: okuma, cevrimici: cevrimici);
    final ikon = DurumRenkleri.ikonGetir(okuma: okuma, cevrimici: cevrimici);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: renk.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon, color: renk, size: 24),
              const SizedBox(height: 6),
              Text(
                'Zon $zonNumarasi',
                style: TextStyle(
                  color: renk,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
