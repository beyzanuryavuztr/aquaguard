/// AquaGuard - Onboarding Turu (ilk açılışta bir kez)
/// ========================================================
///
/// Amac:
///   Uygulamanın ilk kez açıldığı anda (henüz onboarding görülmemişse)
///   Giriş Ekranı'ndan ÖNCE gösterilen 4 sayfalık kısa bir tanıtım turu:
///   ne olduğu, nasıl çalıştığı, tıkanma türleri ve Demo Modu seçimiyle
///   başlangıç. Nokta göstergeli bir `PageView` ile gezilir; "Atla" veya
///   son sayfadaki "Başla" ile bir daha GÖSTERİLMEZ (bkz.
///   UygulamaDurumu.onboardingiTamamla).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/aquaguard_logosu.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/tikanma_turu_ikonu.dart';
import 'giris_ekrani.dart';

class OnboardingEkrani extends StatefulWidget {
  const OnboardingEkrani({super.key});

  @override
  State<OnboardingEkrani> createState() => _OnboardingEkraniState();
}

class _OnboardingEkraniState extends State<OnboardingEkrani> {
  final _controller = PageController();
  int _sayfa = 0;
  static const _toplamSayfa = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tamamlaVeDevamEt() async {
    await context.read<UygulamaDurumu>().onboardingiTamamla();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GirisEkrani()),
    );
  }

  void _ileriGit() {
    if (_sayfa == _toplamSayfa - 1) {
      _tamamlaVeDevamEt();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DuyarliIcerik(
          maksimumGenislik: 520,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: _tamamlaVeDevamEt,
                    child: const Text('Atla'),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _sayfa = i),
                  children: const [
                    _NedirSayfasi(),
                    _NasilCalisirSayfasi(),
                    _TikanmaTurleriSayfasi(),
                    _BaslaSayfasi(),
                  ],
                ),
              ),
              _NoktaGostergesi(sayfa: _sayfa, toplam: _toplamSayfa),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _ileriGit,
                    child: Text(
                      _sayfa == _toplamSayfa - 1 ? 'Başla' : 'İleri',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoktaGostergesi extends StatelessWidget {
  final int sayfa;
  final int toplam;
  const _NoktaGostergesi({required this.sayfa, required this.toplam});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < toplam; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == sayfa ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == sayfa ? primary : onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _SayfaIskeleti extends StatelessWidget {
  final Widget ikon;
  final String baslik;
  final String aciklama;
  final Widget? altIcerik;

  const _SayfaIskeleti({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    this.altIcerik,
  });

  @override
  Widget build(BuildContext context) {
    // NOT: "Nasil Calisir?" ve "Tikanma Turleri" sayfalarinin alt icerigi
    // (sensor rozetleri, tur satirlari) kucuk/kisa ekranlarda PageView'in
    // sabit yuksekligini asabilir -- SingleChildScrollView bu durumda
    // sessizce KIRPILMAK yerine kaydirilabilir olmasini saglar (Column'un
    // kendi yukseklik tasmasi hatasi vermez).
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ikon,
          const SizedBox(height: 28),
          Text(
            baslik,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            aciklama,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (altIcerik != null) ...[
            const SizedBox(height: 24),
            altIcerik!,
          ],
        ],
      ),
    );
  }
}

class _NedirSayfasi extends StatelessWidget {
  const _NedirSayfasi();

  @override
  Widget build(BuildContext context) {
    return const _SayfaIskeleti(
      ikon: AquaGuardLogosu(boyut: 84),
      baslik: 'AquaGuard Nedir?',
      aciklama:
          'Toprak altı damla sulama (SDI) sistemlerinde emitör tıkanmalarını '
          'otonom olarak teşhis eden ve tedavi eden akıllı bir izleme ve '
          'kontrol sistemidir. Saha sensörlerinden gelen verilerle çalışır, '
          'operatörün yerine karar verir, gerektiğinde otomatik tedavi başlatır.',
    );
  }
}

class _NasilCalisirSayfasi extends StatelessWidget {
  const _NasilCalisirSayfasi();

  static const _sensorler = [
    (Icons.science, 'pH'),
    (Icons.bolt, 'EC'),
    (Icons.swap_vert, 'ORP'),
    (Icons.blur_on, 'Türbidite'),
    (Icons.water, 'Debi'),
    (Icons.speed, 'ΔBasınç'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return _SayfaIskeleti(
      ikon: Icon(Icons.hub_outlined, size: 84, color: primary),
      baslik: 'Nasıl Çalışır?',
      aciklama:
          '6 sensörden gelen veriler karar motoruna iletilir; motor tıkanma '
          'olup olmadığını ve türünü belirler, gerekirse doğru tedaviyi '
          'otomatik başlatır.',
      altIcerik: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final s in _sensorler)
                _MiniRozet(ikon: s.$1, etiket: s.$2, renk: onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Icon(Icons.arrow_downward, color: onSurfaceVariant, size: 20),
          const SizedBox(height: 8),
          _MiniRozet(
            ikon: Icons.account_tree,
            etiket: 'Karar Motoru',
            renk: primary,
            vurgulu: true,
          ),
          const SizedBox(height: 8),
          Icon(Icons.arrow_downward, color: onSurfaceVariant, size: 20),
          const SizedBox(height: 8),
          _MiniRozet(
            ikon: Icons.build_circle,
            etiket: 'Otonom Tedavi',
            renk: primary,
            vurgulu: true,
          ),
        ],
      ),
    );
  }
}

class _MiniRozet extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final bool vurgulu;

  const _MiniRozet({
    required this.ikon,
    required this.etiket,
    required this.renk,
    this.vurgulu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: vurgulu
            ? renk.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: vurgulu ? Border.all(color: renk) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 16, color: renk),
          const SizedBox(width: 6),
          Text(etiket, style: TextStyle(fontSize: 12, color: renk)),
        ],
      ),
    );
  }
}

class _TikanmaTurleriSayfasi extends StatelessWidget {
  const _TikanmaTurleriSayfasi();

  @override
  Widget build(BuildContext context) {
    return _SayfaIskeleti(
      ikon: Icon(
        Icons.category_outlined,
        size: 84,
        color: Theme.of(context).colorScheme.primary,
      ),
      baslik: 'Tıkanma Türleri',
      aciklama: 'AquaGuard 3 farklı tıkanma türünü ayırt edip birbirinden '
          'farklı bir tedaviyle müdahale eder.',
      altIcerik: const Column(
        children: [
          _TikanmaTuruSatiri(
            tur: TikanmaTuru.kimyasal,
            aciklama: 'Mineral birikintileri — asit dozlamayla tedavi edilir.',
          ),
          SizedBox(height: 14),
          _TikanmaTuruSatiri(
            tur: TikanmaTuru.biyolojik,
            aciklama: 'Bakteri/biyofilm oluşumu — klor enjeksiyonuyla tedavi edilir.',
          ),
          SizedBox(height: 14),
          _TikanmaTuruSatiri(
            tur: TikanmaTuru.fiziksel,
            aciklama: 'Partikül/sediman birikimi — yüksek basınçlı yıkamayla tedavi edilir.',
          ),
        ],
      ),
    );
  }
}

class _TikanmaTuruSatiri extends StatelessWidget {
  final TikanmaTuru tur;
  final String aciklama;
  const _TikanmaTuruSatiri({required this.tur, required this.aciklama});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TikanmaTuruIkonu(tur: tur, boyut: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                turEtiketi(tur),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                aciklama,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BaslaSayfasi extends StatelessWidget {
  const _BaslaSayfasi();

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return _SayfaIskeleti(
      ikon: Icon(
        Icons.rocket_launch_outlined,
        size: 84,
        color: Theme.of(context).colorScheme.primary,
      ),
      baslik: 'Haydi Başlayalım',
      aciklama: 'Demo Modu ile gerçek donanım olmadan hemen deneyebilir, '
          'hazır olduğunuzda gerçek Deneyap Kart cihazına bağlanabilirsiniz.',
      altIcerik: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Modu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: onSurfaceVariant,
                  ),
                ),
              ),
              Switch(
                value: durum.demoModuAktif,
                onChanged: (acik) {
                  final durumOkuyucu = context.read<UygulamaDurumu>();
                  if (acik) {
                    durumOkuyucu.demoModunuAc();
                  } else {
                    durumOkuyucu.demoModunuKapat();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
