/// AquaGuard - Sulama Onerisi Karti (Faz 4, 2026-09-25)
/// =========================================================
///
/// Amac:
///   Secili ciftligin GPS konumuna gore Open-Meteo'dan hava durumu tahmini
///   ceker, bitki turune gore BASIT bir sulama onerisi gosterir (bkz.
///   models/sulama_onerisi.dart durustluk notu -- bilimsel bir model
///   DEGILDIR). Ciftlikte GPS yoksa API HIC cagrilmaz, ekleme daveti
///   gosterilir. Ag hatasinda sessizce "su an alinamadi" gosterir,
///   UYGULAMAYI ÇÖKERTMEZ.
///
/// Tarih:  2026-09-25
library;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/bitki_turu.dart';
import '../models/hava_tahmini.dart';
import '../models/sulama_onerisi.dart';
import '../models/tarla.dart';
import '../providers/tarla_provider.dart';
import '../services/hava_durumu_servisi.dart';

class SulamaOnerisiKarti extends StatefulWidget {
  final Tarla tarla;
  // SADECE test icin: gercek ag istegi yerine bir MockClient enjekte etmeye
  // yarar (bkz. test/sulama_onerisi_karti_widget_test.dart). Verilmezse
  // HavaDurumuServisi kendi gercek http.Client'ini olusturur.
  final http.Client? testIstemci;
  const SulamaOnerisiKarti({
    super.key,
    required this.tarla,
    this.testIstemci,
  });

  @override
  State<SulamaOnerisiKarti> createState() => _SulamaOnerisiKartiState();
}

class _SulamaOnerisiKartiState extends State<SulamaOnerisiKarti> {
  Future<HavaTahmini?>? _tahminGelecegi;
  String? _yuklenenTarlaId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tahminIstenirseYukle();
  }

  @override
  void didUpdateWidget(covariant SulamaOnerisiKarti oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tahminIstenirseYukle();
  }

  void _tahminIstenirseYukle() {
    if (widget.tarla.id == _yuklenenTarlaId) return;
    _yuklenenTarlaId = widget.tarla.id;
    if (widget.tarla.gpsKonumuVarMi) {
      _tahminGelecegi = HavaDurumuServisi.tahminGetir(
        enlem: widget.tarla.enlem!,
        boylam: widget.tarla.boylam!,
        istemci: widget.testIstemci,
      );
    } else {
      _tahminGelecegi = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_cloudy_outlined, size: 18, color: onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Sulama Önerisi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _BitkiTuruSecici(tarla: widget.tarla),
            const SizedBox(height: 12),
            if (!widget.tarla.gpsKonumuVarMi)
              Text(
                'Öneri gösterebilmek için çiftlik profiline GPS konumu '
                'ekleyin (Çiftlikler > ${widget.tarla.ad} > Konumu Kaydet).',
                style: TextStyle(fontSize: 12, color: onSurfaceVariant),
              )
            else
              FutureBuilder<HavaTahmini?>(
                future: _tahminGelecegi,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final tahmin = snapshot.data;
                  final yarin = tahmin?.yarin;
                  if (tahmin == null || yarin == null) {
                    return Text(
                      'Hava durumu şu an alınamadı — bağlantınızı kontrol edip '
                      'daha sonra tekrar deneyin.',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                    );
                  }
                  final oneri = sulamaOnerisiUret(
                    yarininTahmini: yarin,
                    bitkiTuru: widget.tarla.bitkiTuru ?? BitkiTuru.diger,
                  );
                  return _OneriGosterimi(
                    oneri: oneri,
                    yarin: yarin,
                    onSurfaceVariant: onSurfaceVariant,
                  );
                },
              ),
            const SizedBox(height: 8),
            Text(
              'Basit, kural tabanlı bir öneridir — profesyonel tarım '
              'danışmanlığının yerine geçmez.',
              style: TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BitkiTuruSecici extends StatelessWidget {
  final Tarla tarla;
  const _BitkiTuruSecici({required this.tarla});

  @override
  Widget build(BuildContext context) {
    final secili = tarla.bitkiTuru ?? BitkiTuru.diger;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tur in BitkiTuru.values)
          ChoiceChip(
            label: Text(
              bitkiTuruEtiketi(tur),
              style: const TextStyle(fontSize: 11),
            ),
            visualDensity: VisualDensity.compact,
            selected: secili == tur,
            onSelected: (_) {
              context.read<TarlaProvider>().tarlaGuncelle(
                tarla.kopyalaVeGuncelle(bitkiTuru: tur),
              );
            },
          ),
      ],
    );
  }
}

class _OneriGosterimi extends StatelessWidget {
  final SulamaOnerisi oneri;
  final GunlukHavaTahmini yarin;
  final Color onSurfaceVariant;

  const _OneriGosterimi({
    required this.oneri,
    required this.yarin,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    final renk = switch (oneri.seviye) {
      SulamaOneriSeviyesi.erteleyebilirsiniz => const Color(0xFF2E90FA),
      SulamaOneriSeviyesi.normal => const Color(0xFF1E8F5F),
      SulamaOneriSeviyesi.artirabilirsiniz => const Color(0xFFB45309),
    };
    final ikon = switch (oneri.seviye) {
      SulamaOneriSeviyesi.erteleyebilirsiniz => Icons.umbrella_outlined,
      SulamaOneriSeviyesi.normal => Icons.check_circle_outline,
      SulamaOneriSeviyesi.artirabilirsiniz => Icons.wb_sunny_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Yarın: ${yarin.minSicaklikC.toStringAsFixed(0)}° / '
              '${yarin.maksSicaklikC.toStringAsFixed(0)}°C',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
            const SizedBox(width: 10),
            Icon(Icons.water_drop_outlined, size: 13, color: onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              '%${yarin.yagisIhtimaliYuzde}',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ikon, size: 16, color: renk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  oneri.mesaj,
                  style: TextStyle(fontSize: 12.5, color: renk),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
