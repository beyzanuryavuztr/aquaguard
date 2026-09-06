/// AquaGuard - Operator Mudahale Paneli
/// ========================================
///
/// Amac:
///   AquaGuard'in temel iddiasi OTONOM teshis+tedavidir, ama sahada calisan
///   gercek bir sistemin operatore GUVENLIK/ESNEKLIK sunmasi gerekir:
///     1) "Belirsiz" durumda sistem tikanma turunu yeterli guvenle
///        secemedigi icin, operatorun uygun tedaviyi MANUEL secmesini saglar
///        (ya da durumu yanlis alarm olarak isaretleyip normale doner).
///     2) Su an suren HERHANGI BIR tedavi, operator tarafindan her zaman
///        ERKEN durdurulabilir (ornegin sahada baska bir sorun fark edilirse).
///
///   Bu, daha once "belirsiz -> operatör kontrolü gerekiyor" mesajinin hicbir
///   ic aksiyona baglanmamasi eksikligini giderir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../providers/uygulama_durumu.dart';

class ManuelMudahalePaneli extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;

  const ManuelMudahalePaneli({
    super.key,
    required this.zonNumarasi,
    required this.okuma,
  });

  @override
  Widget build(BuildContext context) {
    if (okuma.tedaviAktif != TedaviTuru.yok) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _DurdurKarti(zonNumarasi: zonNumarasi, okuma: okuma),
      );
    }
    if (okuma.durum == TeshisDurumu.belirsiz) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _SecimKarti(zonNumarasi: zonNumarasi),
      );
    }
    return const SizedBox.shrink();
  }
}

class _PanelBasligi extends StatelessWidget {
  final String metin;
  const _PanelBasligi({required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.pan_tool_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(metin, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _DurdurKarti extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;
  const _DurdurKarti({required this.zonNumarasi, required this.okuma});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelBasligi(metin: 'Operatör Müdahalesi'),
            const SizedBox(height: 8),
            Text(
              'Devam eden ${tedaviEtiketi(okuma.tedaviAktif)} işlemini sahada gerekli '
              'görürseniz erken sonlandırabilirsiniz. Güvenlik gereği sistem '
              'ardından zorunlu durulama adımına geçecektir.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Tedaviyi Durdur'),
              onPressed: () => _onayDiyaloguGoster(
                context,
                baslik: 'Tedaviyi Durdur',
                icerik:
                    '${tedaviEtiketi(okuma.tedaviAktif)} işlemini erken durdurmak '
                    'istediğinize emin misiniz? Sistem zorunlu durulama adımına geçecektir.',
                onayEtiketi: 'Durdur',
                onOnay: () async {
                  await context.read<UygulamaDurumu>().manuelTedaviDurdur(
                    zonNumarasi,
                  );
                  return true;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecimKarti extends StatelessWidget {
  final int zonNumarasi;
  const _SecimKarti({required this.zonNumarasi});

  static const _secenekler = [
    TedaviTuru.asitDozlama,
    TedaviTuru.klorEnjeksiyon,
    TedaviTuru.yuksekBasincliYikama,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelBasligi(metin: 'Operatör Kontrolü Gerekiyor'),
            const SizedBox(height: 8),
            Text(
              'Sistem tıkanma türünü yeterli güvenle belirleyemedi. Aşağıdaki '
              '"Neden Bu Karar?" panelindeki güven skorlarını ve sensör '
              'eğilimlerini inceleyerek uygun tedaviyi siz seçebilir ya da '
              'durumu yanlış alarm olarak işaretleyebilirsiniz.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tedavi in _secenekler)
                  OutlinedButton(
                    onPressed: () => _onayDiyaloguGoster(
                      context,
                      baslik: 'Tedaviyi Manuel Başlat',
                      icerik:
                          'Zon $zonNumarasi için "${tedaviEtiketi(tedavi)}" '
                          'tedavisini manuel olarak başlatmak istediğinize emin misiniz?',
                      onayEtiketi: 'Başlat',
                      onOnay: () => context
                          .read<UygulamaDurumu>()
                          .manuelTedaviBaslat(zonNumarasi, tedavi),
                    ),
                    child: Text(tedaviEtiketi(tedavi)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Yanlış Alarm — Normale Döndür'),
              onPressed: () => _onayDiyaloguGoster(
                context,
                baslik: 'Yanlış Alarm',
                icerik:
                    'Zon $zonNumarasi için bu durumu yanlış alarm olarak '
                    'işaretleyip herhangi bir tedavi uygulamadan normal izlemeye '
                    'dönmek istediğinize emin misiniz?',
                onayEtiketi: 'Normale Döndür',
                onOnay: () async {
                  await context.read<UygulamaDurumu>().manuelNormaleDondur(
                    zonNumarasi,
                  );
                  return true;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [onOnay] artik bir `Future<bool>` doner -- ACIMASIZ DENETIM (2026-09-06):
/// onceden `VoidCallback` idi ve SONUCU HIC beklemeden/kontrol etmeden HER
/// ZAMAN "$baslik uygulandı" gosteriyordu. Bu, manuelTedaviBaslat() mutex
/// kilidi nedeniyle reddedebildigi icin YANLIŞ bir "basarili" mesaji
/// gosterebilirdi (operator, tedavinin aslinda BASLAMADIGINI bilmezdi).
void _onayDiyaloguGoster(
  BuildContext context, {
  required String baslik,
  required String icerik,
  required String onayEtiketi,
  required Future<bool> Function() onOnay,
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
          onPressed: () async {
            final basarili = await onOnay();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  basarili
                      ? '$baslik uygulandı'
                      : '$baslik REDDEDİLDİ (mutex kilidi — zon zaten '
                            'bir tedavi/durulama sürdürüyor)',
                ),
              ),
            );
          },
          child: Text(onayEtiketi),
        ),
      ],
    ),
  );
}
