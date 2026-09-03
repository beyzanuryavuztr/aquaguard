/// AquaGuard - Zon Dashboard Ekrani
/// ====================================
///
/// Amac:
///   Secilen tarladaki tum zonlarin renk kodlu (yesil/sari/kirmizi) ozet
///   durumunu listeler. Bir zona dokununca tikanma detay ekranina gecilir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tarla.dart';
import '../providers/uygulama_durumu.dart';
import '../services/mqtt_servisi.dart';
import '../widgets/demo_modu_banner.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/zon_durum_karti.dart';
import 'ayarlar_ekrani.dart';
import 'gecmis_loglar_ekrani.dart';
import 'tikanma_detay_ekrani.dart';

class ZonDashboardEkrani extends StatelessWidget {
  final Tarla tarla;

  const ZonDashboardEkrani({super.key, required this.tarla});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    // NOT: Bildirimler artik AnaKabuk seviyesinde (kabugun kendisi) drenaj
    // ediliyor -- kullanici hangi sekmede olursa olsun gorunmesi icin.
    // Burada tekrar cagirmiyoruz (cift SnackBar / yaris durumu olmasin diye).

    return Scaffold(
      appBar: AppBar(
        title: Text(tarla.ad),
        actions: [
          if (durum.demoModuAktif)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: _DemoRozeti(),
            )
          else
            _BaglantiRozeti(durum: durum.baglantiDurumu),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Geçmiş Loglar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GecmisLoglarEkrani(tarla: tarla),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (durum.demoModuAktif)
            DemoModuBanner(
              onAyarlaraGit: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AyarlarEkrani())),
            ),
          Expanded(
            child: DuyarliIcerik(
              child: Column(
                children: [
                  _OzetSatiri(tarla: tarla, durum: durum),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: tarla.zonNumaralari.map((zon) {
                        return ZonDurumKarti(
                          zonNumarasi: zon,
                          okuma: durum.sonOkuma(zon),
                          cevrimici: durum.zonCevrimiciMi(zon),
                          sulamaDurdurulduMu: durum.sulamasiDurduruldu(zon),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TikanmaDetayEkrani(zonNumarasi: zon),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OzetSatiri extends StatelessWidget {
  final Tarla tarla;
  final UygulamaDurumu durum;

  const _OzetSatiri({required this.tarla, required this.durum});

  @override
  Widget build(BuildContext context) {
    final ozet = durum.durumOzetiHesapla(tarla.zonNumaralari);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _OzetRozeti(
            sayi: ozet.normal,
            etiket: 'Normal',
            renk: DurumRenkleri.normal,
          ),
          const SizedBox(width: 8),
          _OzetRozeti(
            sayi: ozet.belirsiz,
            etiket: 'Belirsiz',
            renk: DurumRenkleri.belirsiz,
          ),
          const SizedBox(width: 8),
          _OzetRozeti(
            sayi: ozet.tespitEdildi,
            etiket: 'Tespit',
            renk: DurumRenkleri.tespitEdildi,
          ),
          const SizedBox(width: 8),
          _OzetRozeti(
            sayi: ozet.tedavide,
            etiket: 'Tedavide',
            renk: DurumRenkleri.tedaviAktif,
          ),
          if (ozet.cevrimdisi > 0) ...[
            const SizedBox(width: 8),
            _OzetRozeti(
              sayi: ozet.cevrimdisi,
              etiket: 'Çevrimdışı',
              renk: DurumRenkleri.cevrimdisi,
            ),
          ],
        ],
      ),
    );
  }
}

class _OzetRozeti extends StatelessWidget {
  final int sayi;
  final String etiket;
  final Color renk;

  const _OzetRozeti({
    required this.sayi,
    required this.etiket,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$sayi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            Text(etiket, style: TextStyle(fontSize: 11, color: renk)),
          ],
        ),
      ),
    );
  }
}

class _DemoRozeti extends StatelessWidget {
  const _DemoRozeti();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.smart_toy_outlined,
          color: Theme.of(context).colorScheme.tertiary,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          'Demo',
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _BaglantiRozeti extends StatelessWidget {
  final MqttBaglantiDurumu durum;

  const _BaglantiRozeti({required this.durum});

  @override
  Widget build(BuildContext context) {
    final (renk, metin, ikon) = switch (durum) {
      MqttBaglantiDurumu.bagli => (Colors.green, 'Bağlı', Icons.wifi),
      MqttBaglantiDurumu.baglaniyor => (
        Colors.amber,
        'Bağlanıyor',
        Icons.wifi_find,
      ),
      MqttBaglantiDurumu.baglantiKesildi => (
        Colors.orange,
        'Kesildi',
        Icons.wifi_off,
      ),
      MqttBaglantiDurumu.hata => (Colors.red, 'Hata', Icons.error),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(ikon, color: renk, size: 18),
          const SizedBox(width: 4),
          Text(metin, style: TextStyle(color: renk, fontSize: 12)),
        ],
      ),
    );
  }
}
