/// AquaGuard - Bildirimler Karti (Ayarlar bolumu)
/// ===================================================
///
/// Amac:
///   4 bildirim kategorisi (tespit/tedavi baslangic/tedavi tamamlanma/
///   dusuk pil) + sessiz saatler anahtari.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan AyarlarProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ayarlar_provider.dart';

class BildirimlerKarti extends StatelessWidget {
  const BildirimlerKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final ayarlar = context.watch<AyarlarProvider>();

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Tıkanma tespiti'),
            subtitle: const Text(
              'Yeni bir tıkanma tespit edildiğinde veya şüphe oluştuğunda',
            ),
            value: ayarlar.bildirimTercihleri.tespit,
            onChanged: (deger) =>
                context.read<AyarlarProvider>().bildirimTercihleriniGuncelle(
                  ayarlar.bildirimTercihleri.kopyalaVeGuncelle(tespit: deger),
                ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Tedavi başlangıcı'),
            subtitle: const Text(
              'Otonom bir tedavi (asit/klor/yıkama) başladığında',
            ),
            value: ayarlar.bildirimTercihleri.tedaviBaslangic,
            onChanged: (deger) =>
                context.read<AyarlarProvider>().bildirimTercihleriniGuncelle(
                  ayarlar.bildirimTercihleri.kopyalaVeGuncelle(
                    tedaviBaslangic: deger,
                  ),
                ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Tedavi tamamlanma'),
            subtitle: const Text(
              'Tedavi/durulama bitip durum normale döndüğünde',
            ),
            value: ayarlar.bildirimTercihleri.tedaviTamamlanma,
            onChanged: (deger) =>
                context.read<AyarlarProvider>().bildirimTercihleriniGuncelle(
                  ayarlar.bildirimTercihleri.kopyalaVeGuncelle(
                    tedaviTamamlanma: deger,
                  ),
                ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Düşük pil'),
            subtitle: const Text(
              'Cihazın (simüle edilen) pil seviyesi düşük olduğunda',
            ),
            value: ayarlar.bildirimTercihleri.dusukPil,
            onChanged: (deger) =>
                context.read<AyarlarProvider>().bildirimTercihleriniGuncelle(
                  ayarlar.bildirimTercihleri.kopyalaVeGuncelle(dusukPil: deger),
                ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Sessiz Saatler (22:00–07:00)'),
            subtitle: const Text(
              'Bu saatler arasında kritik olmayan bildirimler '
              'cihazda gösterilmez (tıkanma tespiti her zaman '
              'gösterilir).',
            ),
            value: ayarlar.bildirimTercihleri.sessizSaatAktif,
            onChanged: (acik) =>
                context.read<AyarlarProvider>().bildirimTercihleriniGuncelle(
                  acik
                      ? ayarlar.bildirimTercihleri.kopyalaVeGuncelle(
                          sessizBaslangicDakika: 22 * 60,
                          sessizBitisDakika: 7 * 60,
                        )
                      : ayarlar.bildirimTercihleri.kopyalaVeGuncelle(
                          sessizSaatiKaldir: true,
                        ),
                ),
          ),
        ],
      ),
    );
  }
}
