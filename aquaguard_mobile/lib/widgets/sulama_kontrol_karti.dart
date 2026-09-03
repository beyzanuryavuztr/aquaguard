/// AquaGuard - Sulama Kontrol Karti
/// ====================================
///
/// Amac:
///   Operatorun bir zonun ANA VANASINI teshis akisindan tamamen bagimsiz
///   olarak manuel kapatip acmasini saglar (bkz. providers/uygulama_durumu.dart
///   sulamayiDurdur/sulamayiBaslat). "Tedaviyi Durdur"dan (ManuelMudahalePaneli)
///   farki: burada "yanlis teshis" degil, sahadaki BASKA bir sebep (sizinti
///   supheci, bakim, komsu parselde is vb.) soz konusudur -- operator hicbir
///   tikanma/tedavi durumu olmasa bile, istedigi an sulamayi durdurabilmelidir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uygulama_durumu.dart';

class SulamaKontrolKarti extends StatelessWidget {
  final int zonNumarasi;

  const SulamaKontrolKarti({super.key, required this.zonNumarasi});

  @override
  Widget build(BuildContext context) {
    final durdurulduMu = context.select<UygulamaDurumu, bool>(
      (d) => d.sulamasiDurduruldu(zonNumarasi),
    );

    if (!durdurulduMu) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: ListTile(
            leading: Icon(
              Icons.water_drop_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Sulama: Açık'),
            subtitle: const Text('Ana vana normal çalışıyor'),
            trailing: TextButton.icon(
              icon: const Icon(Icons.power_settings_new, size: 18),
              label: const Text('Durdur'),
              onPressed: () => _sulamaOnayDiyalogu(
                context,
                baslik: 'Sulamayı Durdur',
                icerik:
                    'Zon $zonNumarasi için ana vanayı kapatmak istediğinize '
                    'emin misiniz? Tıkanma teşhisinden bağımsız olarak sulama '
                    'tamamen duracak; siz yeniden başlatana kadar devam etmez.',
                onayEtiketi: 'Durdur',
                onOnay: () =>
                    context.read<UygulamaDurumu>().sulamayiDurdur(zonNumarasi),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sulama Manuel Olarak Durduruldu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bu zonun ana vanası operatör tarafından kapatıldı. Aşağıdaki '
                'sensör verileri, vana kapanmadan önceki son bilinen duruma aittir.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Sulamayı Yeniden Başlat'),
                onPressed: () => _sulamaOnayDiyalogu(
                  context,
                  baslik: 'Sulamayı Yeniden Başlat',
                  icerik:
                      'Zon $zonNumarasi için ana vanayı yeniden açmak '
                      'istediğinize emin misiniz?',
                  onayEtiketi: 'Başlat',
                  onOnay: () => context.read<UygulamaDurumu>().sulamayiBaslat(
                    zonNumarasi,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _sulamaOnayDiyalogu(
  BuildContext context, {
  required String baslik,
  required String icerik,
  required String onayEtiketi,
  required VoidCallback onOnay,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(baslik),
      content: Text(icerik),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            onOnay();
            Navigator.of(dialogContext).pop();
          },
          child: Text(onayEtiketi),
        ),
      ],
    ),
  );
}
