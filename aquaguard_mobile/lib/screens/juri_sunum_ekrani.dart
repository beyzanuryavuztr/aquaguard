/// AquaGuard - Juri Sunum Ekrani
/// =================================
///
/// Amac:
///   Sabit `sunumAdimlari` (bkz. models/sunum_adimi.dart) listesini adim
///   adim gezen, sunucunun (Beyzanur/Enver) juri karsisinda takip edecegi
///   bir rehber. Her adimda: baslik, konusma metni, VARSA tek dokunuşluk
///   bir "Bu Adımı Tetikle" butonu (mevcut
///   UygulamaDurumu.demoSenaryosuTetikle() cagirir -- yeni simulasyon
///   mantigi icat edilmez).
///
///   BILEREK ekranlar arasi otomatik gezinme YOK -- adimlar arasi manuel
///   talimat iceren adimlar (orn. "simdi Tedavi Gecmisi'ne gecin") sadece
///   METIN gosterir, sunucu o gezinmeyi kendi eliyle yapar. Bu tasarim
///   kararinin gerekcesi: coklu-ekran otomatik gezinme Flutter'da
///   güvenilir test edilmesi zor, yarisma tarihine yakin risk almaya
///   degmez (bkz. plan dosyasi).
///
///   SADECE Demo Modu acikken anlamlidir (gercek donanimda "senaryo
///   tetikleme" yoktur) -- bu yuzden Genel Bakis'taki giris ikonu SADECE
///   durum.demoModuAktif iken gosterilir (ayni DemoSenaryoPaneli deseni).
///
/// Tarih:  2026-09-15
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sunum_adimi.dart';
import '../providers/cihaz_iletisim_provider.dart';
import '../widgets/duyarli_icerik.dart';

class JuriSunumEkrani extends StatefulWidget {
  const JuriSunumEkrani({super.key});

  @override
  State<JuriSunumEkrani> createState() => _JuriSunumEkraniState();
}

class _JuriSunumEkraniState extends State<JuriSunumEkrani> {
  int _adimIndeksi = 0;

  void _ileriGit() {
    if (_adimIndeksi < sunumAdimlari.length - 1) {
      setState(() => _adimIndeksi++);
    }
  }

  void _geriGit() {
    if (_adimIndeksi > 0) {
      setState(() => _adimIndeksi--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adim = sunumAdimlari[_adimIndeksi];
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final sonAdimMi = _adimIndeksi == sunumAdimlari.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Jüri Sunum Modu')),
      body: SafeArea(
        child: DuyarliIcerik(
          maksimumGenislik: 560,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Adım ${_adimIndeksi + 1} / ${sunumAdimlari.length}',
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          adim.baslik,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          adim.konusmaMetni,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        if (adim.opsiyonelDemoSenaryosu != null) ...[
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context
                                .read<CihazIletisimProvider>()
                                .demoSenaryosuTetikle(
                                  adim.opsiyonelDemoSenaryosu!,
                                ),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Bu Adımı Tetikle'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _NoktaGostergesi(
                  adim: _adimIndeksi,
                  toplam: sunumAdimlari.length,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _adimIndeksi == 0 ? null : _geriGit,
                        child: const Text('Geri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: sonAdimMi ? null : _ileriGit,
                        child: Text(sonAdimMi ? 'Bitti' : 'İleri'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoktaGostergesi extends StatelessWidget {
  final int adim;
  final int toplam;
  const _NoktaGostergesi({required this.adim, required this.toplam});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < toplam; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            width: i == adim ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == adim
                  ? primary
                  : onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
