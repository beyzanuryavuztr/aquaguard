/// AquaGuard - Veri Kaynagi Karti (Demo Modu, Ayarlar bolumu)
/// ================================================================
///
/// Amac:
///   Demo Modu acik/kapali anahtari -- gercek MQTT baglantisi
///   (MqttBaglantiKarti) SADECE demo kapaliyken anlamlidir.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan CihazIletisimProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cihaz_iletisim_provider.dart';

class VeriKaynagiKarti extends StatelessWidget {
  const VeriKaynagiKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final cihaz = context.watch<CihazIletisimProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Demo Modu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: cihaz.demoModuAktif,
                  onChanged: (acik) {
                    final cihazOkuyucu = context.read<CihazIletisimProvider>();
                    if (acik) {
                      cihazOkuyucu.demoModunuAc();
                    } else {
                      cihazOkuyucu.demoModunuKapat();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              cihaz.demoModuAktif
                  ? 'Uygulama, gerçekçi simüle edilmiş sensör verisiyle çalışıyor. '
                        'Herhangi bir ağ/donanım bağlantısı gerekmez.'
                  : 'Uygulama, aşağıdaki MQTT brokerına bağlanarak gerçek '
                        'Deneyap Kart verisini dinliyor.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
