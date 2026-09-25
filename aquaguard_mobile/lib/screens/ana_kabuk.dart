/// AquaGuard - Ana Kabuk (Duyarli Navigasyon)
/// ===============================================
///
/// Amac:
///   Uygulamanin 3 kalici sekmesini (Genel Bakış, Tedavi Geçmişi, Ayarlar)
///   birbirine baglar. IndexedStack kullanilir ki sekmeler arasi gecişte
///   her ekranin durumu (scroll pozisyonu, form girdileri vb.) KORUNSUN --
///   her sekme degisiminde sifirdan olusturulmasin.
///
///   TASARIM KARARI (2026-09-04): "Tarlalar" artik kalici bir sekme DEGIL --
///   varsayilan/demo verisi artik TEK ciftlik oldugundan (bkz. models/tarla.dart),
///   ciftlik secimi/yonetimi Genel Bakış'in app bar'indaki bir ikondan
///   ACILAN bir ekrana tasindi (coklu ciftlik EKLEME yetenegi hala var,
///   sadece artik gunluk kullanimda one cikan bir sekme degil).
///
///   DUYARLI DAVRANIS: brief "once web/Chrome test" diyor -- yani birincil
///   yuzey genis bir masaustu tarayici penceresidir. Dar (mobil) ekranda alt
///   navigasyon cubugu (NavigationBar), genis (masaustu) ekranda ise SOL
///   NAVIGASYON RAYI (NavigationRail) gosterilir -- bu, Material 3'un
///   resmi "adaptive navigation" onerisidir ve masaustu web
///   dashboard'larinin standart deseni (VS Code, Notion, Linear vb.).
///   Mobil bir uygulamanin genis pencerede uzayip gitmesi yerine, genis
///   ekranda GERCEKTEN masaustu icin tasarlanmis gibi gorunur.
///
/// Tarih:  2026-09-01 (guncelleme: 2026-09-02 -- duyarli rayli navigasyon)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/aktivite_kaydi.dart';
import '../models/bildirim_onceligi.dart';
import '../providers/aktivite_bildirim_provider.dart';
import '../providers/ayarlar_provider.dart';
import '../providers/depolama_unawaited.dart';
import '../services/bildirim_servisi.dart';
import '../widgets/duyarli_icerik.dart';
import 'ayarlar_ekrani.dart';
import 'genel_bakis_ekrani.dart';
import 'tedavi_gecmisi_ekrani.dart';
import 'trend_analizi_ekrani.dart';

class _SekmeTanimi {
  final Widget ekran;
  final IconData ikon;
  final IconData seciliIkon;
  final String etiket;

  const _SekmeTanimi({
    required this.ekran,
    required this.ikon,
    required this.seciliIkon,
    required this.etiket,
  });
}

class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key});

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

class _AnaKabukState extends State<AnaKabuk> {
  int _seciliSekme = 0;

  // ACIMASIZ DENETIM (2026-09-25): canli aktivite bildirimleri onceden
  // ALTTAN (SnackBar) gosteriliyordu -- bu, ekranin ALT kismindaki her sey
  // (Jüri Sunum Modu'nun Geri/Ileri butonlari, Genel Bakis'in Hizli Eylem
  // butonlari, Trend Analizi/Ayarlar'in son karti) ile TEKRAR TEKRAR
  // cakisan gercek bug'lara yol acti (bkz. proje gecmisi). Kok neden
  // mimariydi: alttan gelen bir toast, icerigin nerede bittigini asla
  // bilemez. Cozum: USTTEN (AppBar'in hemen altindan) inen bir
  // MaterialBanner -- icerik yukaridan asagi aktigi icin bir ust-banner
  // hicbir zaman alttaki interaktif kontrollerle cakismaz.
  //
  // MaterialBanner kendi suresi/otomatik kapanma OZELLIGI TASIMAZ (SnackBar
  // gibi degil) -- bu yuzden basit bir sira (kuyruk) + zamanlayici burada
  // elle kuruluyor: aninda birden fazla bildirim gelirse sirayla, her biri
  // 4 saniye gorunup bir sonrakine gecer.
  final List<AktiviteKaydi> _bannerKuyrugu = [];
  bool _bannerGosteriliyor = false;
  Timer? _bannerZamanlayici;

  @override
  void dispose() {
    _bannerZamanlayici?.cancel();
    super.dispose();
  }

  void _bannerSirasiniIsle(BuildContext context, AyarlarProvider ayarlar) {
    if (_bannerGosteriliyor || _bannerKuyrugu.isEmpty) return;
    // Kabuk'un UZERINE baska bir ekran PUSH edilmisse (Zon Detay/Ayarlar
    // alt-sayfasi/Jüri Sunum Modu vb.) gösterilmez -- bildirim yine de
    // Bildirim Gecmisi'ne kaydedildi (asagida, provider tarafinda) ve OS
    // bildirimi olarak gonderildi, sadece anlik "toast" atlanir.
    final kabukGuncelRotada = ModalRoute.of(context)?.isCurrent ?? true;
    if (!kabukGuncelRotada) {
      _bannerKuyrugu.clear();
      return;
    }
    final kayit = _bannerKuyrugu.removeAt(0);
    _bannerGosteriliyor = true;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        leading: Icon(kayit.ikon, color: Theme.of(context).colorScheme.primary),
        content: Text(kayit.mesaj),
        actions: [
          TextButton(
            onPressed: () {
              _bannerZamanlayici?.cancel();
              _bannerGosterimiKapat(context);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    _bannerZamanlayici = Timer(const Duration(seconds: 4), () {
      _bannerGosterimiKapat(context);
    });
  }

  void _bannerGosterimiKapat(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    _bannerGosteriliyor = false;
    _bannerSirasiniIsle(context, context.read<AyarlarProvider>());
  }

  static const _sekmeler = [
    _SekmeTanimi(
      ekran: GenelBakisEkrani(),
      ikon: Icons.dashboard_outlined,
      seciliIkon: Icons.dashboard,
      etiket: 'Genel Bakış',
    ),
    _SekmeTanimi(
      ekran: TedaviGecmisiEkrani(),
      ikon: Icons.bar_chart_outlined,
      seciliIkon: Icons.bar_chart,
      etiket: 'Tedavi Geçmişi',
    ),
    _SekmeTanimi(
      ekran: TrendAnaliziEkrani(),
      ikon: Icons.show_chart_outlined,
      seciliIkon: Icons.show_chart,
      etiket: 'Trend Analizi',
    ),
    _SekmeTanimi(
      ekran: AyarlarEkrani(),
      ikon: Icons.settings_outlined,
      seciliIkon: Icons.settings,
      etiket: 'Ayarlar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Bildirimleri BURADA (kabuk seviyesinde) dinliyoruz -- Genel Bakış
    // artik uygulamanin ana ekrani, kullanici hicbir tarlaya girmeden
    // saatlerce orada kalabilir. Bildirim akisi tek bir sekmeye (Zon
    // Dashboard'a) bagli kalirsa, kullanici Genel Bakış'tayken hicbir
    // canli tikanma/tedavi uyarisi GORMEZ (veri Aktivite Gecmisi'ne
    // kaydedilir ama aninda haber verilmez). Kabuk her zaman monte
    // oldugu icin, hangi sekmede olursa olsun bildirimler burada gosterilir.
    final aktivite = context.watch<AktiviteBildirimProvider>();
    final ayarlar = context.watch<AyarlarProvider>();
    final bildirimler = aktivite.bildirimleriAlVeTemizle();
    if (bildirimler.isNotEmpty) {
      _bannerKuyrugu.addAll(bildirimler);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _bannerSirasiniIsle(context, ayarlar);
      });
      for (final kayit in bildirimler) {
        // Yerel bildirim (banner sadece on plandayken gorunur) --
        // BildirimServisi kendi icinde try/catch ile korunur, burada
        // ek bir hata isleme gerekmez. Sessiz saatte (kritik haric)
        // OS bildirimi BASTIRILIR -- banner yine de gosterilir
        // (kullanici zaten uygulamayi acik tutuyor, rahatsiz etmez).
        final oncelik = oncelikGetir(kayit.tur);
        if (!sessizSaattaBastirilmaliMi(ayarlar.bildirimTercihleri, oncelik)) {
          unawaited(
            BildirimServisi.goster(
              id: bildirimIdGetir(kayit),
              baslik: bildirimBasligiGetir(kayit.tur),
              icerik: kayit.mesaj,
              oncelik: oncelik,
            ),
          );
        }
      }
    }

    final icerik = IndexedStack(
      index: _seciliSekme,
      children: [for (final s in _sekmeler) s.ekran],
    );

    if (genisEkranMi(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _seciliSekme,
              onDestinationSelected: (index) =>
                  setState(() => _seciliSekme = index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AquaGuard',
                      // SABIT acik renk: NavigationRail'in arka plani
                      // (anaRenk, koyu lacivert) HER IKI temada da ayni
                      // kalir (bkz. config/tema.dart) -- buradaki metin
                      // Theme.of(context)'in genel (aciktemada KOYU) metin
                      // rengini DEGIL, rayin kendi sabit acik rengini
                      // kullanmali (aksi halde acik temada gorunmez olur).
                      style: const TextStyle(
                        color: Color(0xFFE6ECF1),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: [
                for (final s in _sekmeler)
                  NavigationRailDestination(
                    icon: Icon(s.ikon),
                    selectedIcon: Icon(s.seciliIkon),
                    label: Text(s.etiket),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: icerik),
          ],
        ),
      );
    }

    return Scaffold(
      body: icerik,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSekme,
        onDestinationSelected: (index) => setState(() => _seciliSekme = index),
        destinations: [
          for (final s in _sekmeler)
            NavigationDestination(
              icon: Icon(s.ikon),
              selectedIcon: Icon(s.seciliIkon),
              label: s.etiket,
            ),
        ],
      ),
    );
  }
}
