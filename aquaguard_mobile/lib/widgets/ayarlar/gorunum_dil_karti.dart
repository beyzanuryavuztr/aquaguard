/// AquaGuard - Gorunum + Dil Kartlari (Ayarlar bolumu)
/// ========================================================
///
/// Amac:
///   Tema/aksan rengi/saha modu/titresim/yazi boyutu (Gorunum) ve
///   TR/EN (Dil) secicileri. i18n PILOT (kisitli kapsam -- bkz.
///   lib/l10n/app_tr.arb dosya basi notu): SADECE bu iki kart
///   AppLocalizations uzerinden cekilir, uygulamanin geri kalani hala
///   sabit Turkce metin kullanir.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan AyarlarProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/aksan_rengi.dart';
import '../../models/tema_modu.dart';
import '../../models/uygulama_dili.dart';
import '../../models/yazi_boyutu.dart';
import '../../providers/ayarlar_provider.dart';
import 'bolum_basligi.dart';

class GorunumDilKartlari extends StatelessWidget {
  const GorunumDilKartlari({super.key});

  @override
  Widget build(BuildContext context) {
    final ayarlar = context.watch<AyarlarProvider>();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BolumBasligi(baslik: l10n.gorunumBasligi),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.temaEtiketi,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<TemaModu>(
                  segments: [
                    ButtonSegment(
                      value: TemaModu.koyu,
                      label: Text(l10n.temaKoyu),
                    ),
                    ButtonSegment(
                      value: TemaModu.acik,
                      label: Text(l10n.temaAcik),
                    ),
                    ButtonSegment(
                      value: TemaModu.sistem,
                      label: Text(l10n.temaSistem),
                    ),
                  ],
                  selected: {ayarlar.temaModu},
                  showSelectedIcon: false,
                  onSelectionChanged: (secim) => context
                      .read<AyarlarProvider>()
                      .temaModuAyarla(secim.first),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.aksanRengiEtiketi,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<AksanRengi>(
                  segments: [
                    ButtonSegment(
                      value: AksanRengi.teal,
                      label: Text(l10n.aksanTurkuvaz),
                      icon: Icon(
                        Icons.circle,
                        color: aksanPaletleri[AksanRengi.teal]!.renk,
                        size: 14,
                      ),
                    ),
                    ButtonSegment(
                      value: AksanRengi.toprak,
                      label: Text(l10n.aksanToprak),
                      icon: Icon(
                        Icons.circle,
                        color: aksanPaletleri[AksanRengi.toprak]!.renk,
                        size: 14,
                      ),
                    ),
                  ],
                  selected: {ayarlar.aksanRengi},
                  showSelectedIcon: false,
                  onSelectionChanged: (secim) => context
                      .read<AyarlarProvider>()
                      .aksanRengiAyarla(secim.first),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.sahaModuBaslik),
                  subtitle: Text(l10n.sahaModuAciklama),
                  value: ayarlar.sahaModuAktif,
                  onChanged: (yeni) =>
                      context.read<AyarlarProvider>().sahaModuAyarla(yeni),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.titresimBaslik),
                  subtitle: Text(l10n.titresimAciklama),
                  value: ayarlar.titresimAktif,
                  onChanged: (yeni) => context
                      .read<AyarlarProvider>()
                      .titresimGeriBildirimiAyarla(yeni),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.yaziBoyutuEtiketi,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<YaziBoyutu>(
                  segments: [
                    ButtonSegment(
                      value: YaziBoyutu.kucuk,
                      label: Text(l10n.yaziBoyutuKucuk),
                    ),
                    ButtonSegment(
                      value: YaziBoyutu.normal,
                      label: Text(l10n.yaziBoyutuNormal),
                    ),
                    ButtonSegment(
                      value: YaziBoyutu.buyuk,
                      label: Text(l10n.yaziBoyutuBuyuk),
                    ),
                    ButtonSegment(
                      value: YaziBoyutu.cokBuyuk,
                      label: Text(l10n.yaziBoyutuCokBuyuk),
                    ),
                  ],
                  selected: {ayarlar.yaziBoyutu},
                  showSelectedIcon: false,
                  onSelectionChanged: (secim) => context
                      .read<AyarlarProvider>()
                      .yaziBoyutuAyarla(secim.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        BolumBasligi(baslik: l10n.dilBolumBasligi),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<UygulamaDili>(
              segments: [
                ButtonSegment(
                  value: UygulamaDili.turkce,
                  label: Text(l10n.dilTurkce),
                ),
                ButtonSegment(
                  value: UygulamaDili.ingilizce,
                  label: Text(l10n.dilIngilizce),
                ),
              ],
              selected: {ayarlar.uygulamaDili},
              showSelectedIcon: false,
              onSelectionChanged: (secim) => context
                  .read<AyarlarProvider>()
                  .uygulamaDiliniAyarla(secim.first),
            ),
          ),
        ),
      ],
    );
  }
}
