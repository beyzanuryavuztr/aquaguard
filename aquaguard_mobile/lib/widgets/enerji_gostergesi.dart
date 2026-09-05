/// AquaGuard - Enerji/GSM Durumu Gostergesi (SIMULE)
/// ======================================================
///
/// Amac:
///   Genel Bakis'ta cihazin guc kaynagi (pil/sebeke) ve GSM sinyal
///   durumunu ozetleyen kompakt bir rozet.
///
///   DURUSTLUK NOTU: bu GERCEK bir telemetri degildir -- firmware/MQTT
///   semasi (bkz. models/sensor_okuma.dart) su an boyle bir alan
///   TASIMIYOR, gercek donanimda henuz bu veriyi olcen bir devre yok.
///   Deger, her yeniden cizimde rastgele SIcRAMAYAN, gunun tarihine bagli
///   deterministik bir gosterge degeridir (ayni AciklanabilirlikPaneli'nin
///   "kural tabanli, uydurma degil" ilkesiyle tutarli -- burada da
///   kullaniciyi yaniltacak sekilde "canli veri" izlenimi vermek yerine
///   Tooltip ile acikca "simule" oldugu belirtilir). Gercek donanim bu
///   telemetriyi yayinlamaya basladiginda, tek yapilmasi gereken bu
///   sabit hesaplarin gercek SensorOkuma alanlarina baglanmasidir.
///
/// Tarih:  2026-09-04
library;

import 'package:flutter/material.dart';

import 'durum_renkleri.dart';

class EnerjiGostergesi extends StatelessWidget {
  const EnerjiGostergesi({super.key});

  static int get _pilYuzdesi {
    final gun = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    return 78 + (gun % 5) * 4; // 78..94 arasinda, gune gore sabit
  }

  static bool get _gsmGucluMu {
    final gun = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;
    return gun % 7 != 0; // cogunlukla guclu, haftada bir gun orta
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final pil = _pilYuzdesi;
    final gsmGuclu = _gsmGucluMu;
    final pilRenk = pil >= 50
        ? DurumRenkleri.normal
        : pil >= 20
        ? DurumRenkleri.belirsiz
        : DurumRenkleri.tespitEdildi;

    return Tooltip(
      message:
          'Simüle gösterge — firmware şu an bu telemetriyi yayınlamıyor.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pil >= 50
                  ? Icons.battery_full
                  : (pil >= 20 ? Icons.battery_4_bar : Icons.battery_alert),
              size: 16,
              color: pilRenk,
            ),
            const SizedBox(width: 4),
            Text(
              '%$pil',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: pilRenk,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              gsmGuclu
                  ? Icons.signal_cellular_alt
                  : Icons.signal_cellular_alt_2_bar,
              size: 16,
              color: onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              gsmGuclu ? 'GSM Güçlü' : 'GSM Orta',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
