/// AquaGuard - Bakim Takvimi Karti (Ayarlar bolumu)
/// =====================================================
///
/// Amac:
///   Periyodik bakim gorevlerinin (filtre temizligi vb.) durumunu listeler.
///   "filtre_temizligi" gorevi icin turbidite trendine dayali "onerilen
///   erken tarih" notu da hesaplanir (bkz. models/bakim_gorevi.dart).
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan BakimProvider + CihazIletisimProvider + TarlaProvider'i
///   izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tarih_bicimleri.dart';
import '../../models/bakim_gorevi.dart';
import '../../providers/bakim_provider.dart';
import '../../providers/cihaz_iletisim_provider.dart';
import '../../providers/tarla_provider.dart';

class BakimTakvimiKarti extends StatelessWidget {
  const BakimTakvimiKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final bakim = context.watch<BakimProvider>();
    final cihaz = context.watch<CihazIletisimProvider>();
    final tarla = context.watch<TarlaProvider>();
    final gorevler = bakim.bakimGorevleri;

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < gorevler.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _BakimGoreviSatiri(
              gorev: gorevler[i],
              onerilenTarih: gorevler[i].id != 'filtre_temizligi'
                  ? null
                  : filtreTemizligiOnerilenTarih(
                      turbiditeGecmisleriKronolojik: tarla.tumZonNumaralari
                          .map((z) => cihaz.gecmis(z).reversed.toList())
                          .toList(),
                      gorev: gorevler[i],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BakimGoreviSatiri extends StatelessWidget {
  final BakimGorevi gorev;
  final DateTime? onerilenTarih;
  const _BakimGoreviSatiri({required this.gorev, this.onerilenTarih});

  @override
  Widget build(BuildContext context) {
    final durumu = gorev.durumu();
    final renk = switch (durumu) {
      BakimDurumu.gecikti => Theme.of(context).colorScheme.error,
      BakimDurumu.yaklasiyor => const Color(0xFFFFB300),
      BakimDurumu.normal => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final kalanGun = gorev.kalanGun();
    final durumMetni = switch (durumu) {
      BakimDurumu.gecikti => '${-kalanGun} gün gecikti',
      BakimDurumu.yaklasiyor => '$kalanGun gün kaldı',
      BakimDurumu.normal =>
        'Sıradaki: ${TarihBicimleri.sadeceTarih.format(gorev.sonrakiTarih)}',
    };
    final oneriMetni = onerilenTarih == null
        ? ''
        : '\n📈 Türbidite artış eğiliminde — önerilen erken tarih: '
              '${TarihBicimleri.sadeceTarih.format(onerilenTarih!)}';

    return ListTile(
      leading: Icon(
        durumu == BakimDurumu.gecikti
            ? Icons.error_outline
            : Icons.build_outlined,
        color: renk,
      ),
      title: Text(gorev.baslik),
      subtitle: Text(
        '${gorev.aciklama}\n$durumMetni$oneriMetni',
        style: TextStyle(color: renk),
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: () => context
            .read<BakimProvider>()
            .bakimGoreviTamamlandiIsaretle(gorev.id),
        child: const Text('Yapıldı'),
      ),
    );
  }
}
