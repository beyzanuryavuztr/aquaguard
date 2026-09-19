/// AquaGuard - Acil Durdurma FAB'i
/// ====================================
///
/// Amac:
///   Dashboard'da her zaman sabit, göz ardı edilemeyecek kadar belirgin
///   bir güvenlik supabı: TEK dokunuşla (onay alarak) TÜM zonlardaki
///   aktif tedavileri güvenlik gereği zorunlu durulamadan geçirerek
///   durdurur VE tüm ana vanaları kapatır (bkz.
///   providers/cihaz_iletisim_provider.dart acilDurdurmaTetikle).
///
///   Yanlışlıkla tetiklenmeyi önlemek için EXPLICIT bir onay diyaloğu
///   gerekir; onaylandıktan sonra sadece bu eylemle kapatılan vanalar
///   için 3 saniyelik bir "Geri Al" penceresi sunulur (durdurulan
///   tedaviler GERİ ALINAMAZ -- güvenlik gereği tek yönlüdür).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/ayarlar_provider.dart';
import '../providers/cihaz_iletisim_provider.dart';
import 'durum_renkleri.dart';

class AcilDurdurmaFab extends StatelessWidget {
  const AcilDurdurmaFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Acil durdur. Tüm zonlardaki tedavileri ve sulamayı durdurur, '
          'onay gerektirir.',
      onTap: () => _onayDiyaloguGoster(context),
      excludeSemantics: true,
      child: FloatingActionButton.extended(
        heroTag: 'acil_durdurma_fab',
        backgroundColor: DurumRenkleri.tespitEdildi,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded),
        label: const Text(
          'ACİL DURDUR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        onPressed: () => _onayDiyaloguGoster(context),
      ),
    );
  }

  Future<void> _onayDiyaloguGoster(BuildContext context) async {
    final cihaz = context.read<CihazIletisimProvider>();

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: DurumRenkleri.tespitEdildi,
          size: 36,
        ),
        title: const Text('Acil Durdurma'),
        content: const Text(
          'TÜM tedavileri ve sulamayı acil olarak durdurmak istediğinize '
          'emin misiniz?\n\n'
          'Aktif tedaviler güvenlik gereği zorunlu durulamadan geçirilecek, '
          'tüm zonların ana vanaları kapatılacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DurumRenkleri.tespitEdildi,
            ),
            onPressed: () {
              // Sistemin en yuksek riskli tek-tuslu eylemi -- EN YOGUN
              // dokunsal geri bildirim (heavyImpact) burada.
              if (context.read<AyarlarProvider>().titresimAktif) {
                HapticFeedback.heavyImpact();
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('ACİL DURDUR'),
          ),
        ],
      ),
    );

    if (onay != true || !context.mounted) return;

    final vanasiYeniKapatilanlar = await cihaz.acilDurdurmaTetikle();
    if (!context.mounted) return;

    // DURUSTLUK: gercek modda komutlar cihaza ULASMAYABILIR (kuyruga alinir,
    // 5 dk icinde iletilemezse duser). "Durduruldu" demek yerine gercek
    // durumu soyle; cihaz onayi ayrica vana durumu telemetrisiyle gelir.
    final gercekMod = !cihaz.demoModuAktif;
    final kuyrukta = gercekMod ? cihaz.sonAcilDurdurmaKuyrugaAlinan : 0;
    final String mesaj;
    if (!gercekMod) {
      mesaj = 'Acil durdurma uygulandı: tüm tedaviler ve sulama durduruldu.';
    } else if (kuyrukta > 0) {
      mesaj =
          'UYARI: Cihaza ULAŞILAMIYOR -- $kuyrukta komut kuyruğa alındı ve '
          'bağlantı 5 dakika içinde gelmezse GÖNDERİLMEYECEK. '
          'Cihazın başında elle durdurun.';
    } else {
      mesaj =
          'Acil durdurma komutları cihaza GÖNDERİLDİ. Cihazın yanıtını (vana '
          'durumu) birkaç saniye içinde zon ekranından doğrulayın.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: kuyrukta > 0 ? DurumRenkleri.tespitEdildi : null,
        duration: Duration(seconds: kuyrukta > 0 ? 10 : (gercekMod ? 6 : 3)),
        action: vanasiYeniKapatilanlar.isEmpty
            ? null
            : SnackBarAction(
                label: 'Geri Al',
                onPressed: () {
                  for (final zon in vanasiYeniKapatilanlar) {
                    cihaz.sulamayiBaslat(zon);
                  }
                },
              ),
      ),
    );
  }
}
