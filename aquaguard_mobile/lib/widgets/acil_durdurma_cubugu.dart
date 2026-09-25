/// AquaGuard - Acil Durdurma Cubugu
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
///   ACIMASIZ DENETIM (2026-09-25): bu eskiden yüzen bir
///   FloatingActionButton'du -- her zaman ekranın sağ-alt köşesinde
///   SABİT konumda kalıp, sayfa kısaldıkça (bkz. Genel Bakış'taki
///   tekrar/redundancy sadeleştirmesi) ALTINDAKİ içeriğin (Hızlı Eylem
///   butonları, istatistik kartları) üzerine binmeye devam ediyordu --
///   yüzen bir buton doğası gereği HER ZAMAN scroll içeriğinin üzerinde
///   durur, hangi içeriğin altında kaldığı tamamen tesadüfe bağlıdır.
///   Artık `GenelBakisEkrani`'nin `body`'sinde, kaydırılabilir alanın
///   HEMEN ALTINDA, sabit (floating DEĞİL) tam genişlikte bir çubuk --
///   içerik onun ÜZERİNDE asla render edilmez, ekranın ayrılmış kendi
///   şeridi vardır.
///
/// Tarih:  2026-09-05 (FAB -> sabit cubuk: 2026-09-25)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/ayarlar_provider.dart';
import '../providers/cihaz_iletisim_provider.dart';
import 'durum_renkleri.dart';

class AcilDurdurmaCubugu extends StatelessWidget {
  const AcilDurdurmaCubugu({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Acil durdur. Tüm zonlardaki tedavileri ve sulamayı durdurur, '
          'onay gerektirir.',
      onTap: () => _onayDiyaloguGoster(context),
      excludeSemantics: true,
      child: Material(
        color: DurumRenkleri.tespitEdildi,
        child: InkWell(
          onTap: () => _onayDiyaloguGoster(context),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ACİL DURDUR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
