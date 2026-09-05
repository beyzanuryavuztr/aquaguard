/// AquaGuard - Aktif Tedaviler Bolumu (Genel Bakis mini listesi)
/// ==================================================================
///
/// Amac:
///   Genel Bakis'ta, su an tedavi uygulanmakta olan zonlari one cikaran
///   kompakt, canli ilerleme cubuklu bir liste -- kullanicinin "su an
///   sistem ne yapiyor?" sorusuna tek tek zonlara girmeden cevap
///   bulmasini saglar. Ilerleme hesabi AktifTedaviEkrani ile AYNI
///   TedaviIlerlemesi.hesapla() fonksiyonunu kullanir (tek kaynak).
///
/// Tarih:  2026-09-04
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';
import '../models/tedavi_ilerlemesi.dart';
import 'durum_renkleri.dart';

class AktifTedavilerBolumu extends StatefulWidget {
  final List<int> zonlar;
  final SensorOkuma? Function(int zon) okumaGetir;
  final DateTime? Function(int zon) baslangicGetir;
  final ValueChanged<int> onZonSecildi;

  const AktifTedavilerBolumu({
    super.key,
    required this.zonlar,
    required this.okumaGetir,
    required this.baslangicGetir,
    required this.onZonSecildi,
  });

  @override
  State<AktifTedavilerBolumu> createState() => _AktifTedavilerBolumuState();
}

class _AktifTedavilerBolumuState extends State<AktifTedavilerBolumu> {
  Timer? _saniyeSayaci;

  @override
  void initState() {
    super.initState();
    // Ilerleme cubuklarinin canli akmasi icin her saniye yeniden ciz
    // (ayni desen: screens/aktif_tedavi_ekrani.dart).
    _saniyeSayaci = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _saniyeSayaci?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aktifZonlar = widget.zonlar.where((zon) {
      final okuma = widget.okumaGetir(zon);
      return okuma != null && okuma.tedaviAktif != TedaviTuru.yok;
    }).toList();

    if (aktifZonlar.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final zon in aktifZonlar)
          _AktifTedaviSatiri(
            zonNumarasi: zon,
            okuma: widget.okumaGetir(zon)!,
            baslangic: widget.baslangicGetir(zon),
            onTap: () => widget.onZonSecildi(zon),
          ),
      ],
    );
  }
}

class _AktifTedaviSatiri extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;
  final DateTime? baslangic;
  final VoidCallback onTap;

  const _AktifTedaviSatiri({
    required this.zonNumarasi,
    required this.okuma,
    required this.baslangic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ilerleme = TedaviIlerlemesi.hesapla(
      tedavi: okuma.tedaviAktif,
      baslangic: baslangic,
    );
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DurumRenkleri.tedaviAktif.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_circle,
                    color: DurumRenkleri.tedaviAktif,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zon $zonNumarasi — ${tedaviEtiketi(okuma.tedaviAktif)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ilerleme.oran.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: DurumRenkleri.tedaviAktif
                              .withValues(alpha: 0.15),
                          color: DurumRenkleri.tedaviAktif,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ilerleme.kalanSaniye > 0
                            ? 'Tahmini kalan: ${ilerleme.kalanSaniye} sn'
                            : 'Tamamlanmak üzere...',
                        style: TextStyle(
                          fontSize: 11,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
