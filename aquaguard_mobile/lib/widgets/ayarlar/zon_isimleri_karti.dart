/// AquaGuard - Zon Isimleri Karti (Ayarlar bolumu)
/// ====================================================
///
/// Amac:
///   Her zon icin opsiyonel takma ad girisi (orn. "Kuzeydogu Parseli").
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan TarlaProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/tarla_provider.dart';

class ZonIsimleriKarti extends StatelessWidget {
  const ZonIsimleriKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final tarla = context.watch<TarlaProvider>();
    final zonlar = tarla.tumZonNumaralari;

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < zonlar.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _ZonAdiSatiri(zon: zonlar[i]),
          ],
          if (zonlar.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Henüz izlenen zon yok.'),
            ),
        ],
      ),
    );
  }
}

class _ZonAdiSatiri extends StatelessWidget {
  final int zon;
  const _ZonAdiSatiri({required this.zon});

  @override
  Widget build(BuildContext context) {
    final tarla = context.watch<TarlaProvider>();
    final varsayilanAd = 'Zon $zon';
    final zonAdi = tarla.zonAdiGetir(zon);
    final takmaAdVarMi = zonAdi != varsayilanAd;
    return ListTile(
      title: Text(varsayilanAd),
      subtitle: Text(
        takmaAdVarMi ? zonAdi : 'Takma ad verilmedi',
        style: takmaAdVarMi
            ? null
            : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _takmaAdDiyaloguGoster(context, tarla, zon),
    );
  }

  Future<void> _takmaAdDiyaloguGoster(
    BuildContext context,
    TarlaProvider tarla,
    int zon,
  ) async {
    final mevcutAd = tarla.zonAdiGetir(zon);
    final baslangicMetni = mevcutAd == 'Zon $zon' ? '' : mevcutAd;
    final controller = TextEditingController(text: baslangicMetni);

    final sonuc = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Zon $zon Takma Adı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'örn. Kuzeydoğu Parseli'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (sonuc != null && context.mounted) {
      await tarla.zonTakmaAdiAyarla(zon, sonuc);
    }
  }
}
