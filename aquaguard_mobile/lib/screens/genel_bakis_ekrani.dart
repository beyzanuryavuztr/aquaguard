/// AquaGuard - Genel Bakis Ekrani
/// ==================================
///
/// Amac:
///   Uygulamanin acilis sekmesi. Tum tarlalar/zonlar genelinde ozet bir
///   "kus bakisi" sunar: genel sistem sagligi, kac zon izleniyor, kac
///   tanesi dikkat gerektiriyor, su an kac tedavi aktif, TUM zonlarin
///   tek bakista durumu ve en son neler oldu. Kullanicinin tek tek
///   tarlalara girmeden sistemin tamamini gormesini saglar.
///
/// Tarih:  2026-09-01 (guncelleme: 2026-09-02 -- saglik gostergesi + tum zonlar)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/aktivite_kaydi.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/acil_durdurma_fab.dart';
import '../widgets/aktif_tedaviler_bolumu.dart';
import '../widgets/bakim_uyari_karti.dart';
import '../widgets/demo_modu_banner.dart';
import '../widgets/demo_senaryo_paneli.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/enerji_gostergesi.dart';
import '../widgets/sistem_sagligi_gostergesi.dart';
import '../widgets/zon_durum_karti.dart';
import '../widgets/zon_semasi.dart';
import 'aktivite_gecmisi_ekrani.dart';
import 'ayarlar_ekrani.dart';
import 'tarla_secim_ekrani.dart';
import 'tikanma_detay_ekrani.dart';

class GenelBakisEkrani extends StatelessWidget {
  const GenelBakisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();

    final tumZonlar = durum.tumZonNumaralari;
    final ozet = durum.durumOzetiHesapla(tumZonlar);
    final sonAktiviteler = durum.aktiviteGecmisi.take(6).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.water_drop,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('AquaGuard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grass_outlined),
            tooltip: 'Çiftlikler',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TarlaSecimEkrani()),
            ),
          ),
        ],
      ),
      body: !durum.hazir
          ? const Center(child: CircularProgressIndicator())
          : DuyarliIcerik(
              // NOT: ListView yerine bilerek SingleChildScrollView+Column --
              // bu ekrandaki icerik KUCUK VE SABIT sayida (en fazla birkac
              // kart + 6 zon + 6 aktivite), yani ListView'in lazy/sliver
              // mimarisine hic ihtiyac yok. Cok yuksek pencerelerde (~2000px+
              // mantiksal yukseklik -- genis 4K monitorlerde tam ekran
              // tarayici) ListView + CanvasKit kombinasyonunda icerigin
              // pencerenin alt kisminda HAYALET SEKILDE TEKRAR cizildigi
              // gozlemlendi (Skia'nin resim (picture) katmanini belirli bir
              // yukseklik esiginde ic ice dosemesiyle ilgili bir motor
              // tuhafligi gibi gorunuyor -- diger ekranlarda ayni yukseklikte
              // GOZLEMLENMEDI). SingleChildScrollView bu sliver tabanli
              // cizim yolunu tamamen atlar.
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (durum.demoModuAktif) ...[
                      DemoModuBanner(
                        onAyarlaraGit: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AyarlarEkrani(),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: DemoSenaryoPaneli(),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SistemSagligiGostergesi(ozet: ozet),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: const EnerjiGostergesi(),
                      ),
                    ),
                    if (durum.bakimUyarisiVarMi)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: BakimUyariKarti(
                          gorevler: durum.bakimGorevleri,
                          onAyarlaraGit: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AyarlarEkrani(),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Text(
                        'Sistem Özeti',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _IstatistikKarti(
                            deger: durum.tarlalar.length,
                            etiket: 'Tarla',
                            ikon: Icons.grass,
                          ),
                          const SizedBox(width: 10),
                          _IstatistikKarti(
                            deger: tumZonlar.length,
                            etiket: 'Zon',
                            ikon: Icons.sensors,
                          ),
                          const SizedBox(width: 10),
                          _IstatistikKarti(
                            deger: ozet.tedavide,
                            etiket: 'Aktif Tedavi',
                            ikon: Icons.build_circle,
                            vurgulaRenk: ozet.tedavide > 0
                                ? DurumRenkleri.tedaviAktif
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _DurumOzetRozeti(
                            sayi: ozet.normal,
                            etiket: 'Normal',
                            renk: DurumRenkleri.normal,
                          ),
                          const SizedBox(width: 8),
                          _DurumOzetRozeti(
                            sayi: ozet.belirsiz,
                            etiket: 'Belirsiz',
                            renk: DurumRenkleri.belirsiz,
                          ),
                          const SizedBox(width: 8),
                          _DurumOzetRozeti(
                            sayi: ozet.tespitEdildi,
                            etiket: 'Tespit',
                            renk: DurumRenkleri.tespitEdildi,
                          ),
                          if (ozet.cevrimdisi > 0) ...[
                            const SizedBox(width: 8),
                            _DurumOzetRozeti(
                              sayi: ozet.cevrimdisi,
                              etiket: 'Çevrimdışı',
                              renk: DurumRenkleri.cevrimdisi,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Zon Şeması',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ZonSemasi(
                        zonlar: tumZonlar,
                        okumaGetir: durum.sonOkuma,
                        cevrimiciMi: durum.zonCevrimiciMi,
                        adGetir: durum.zonAdiGetir,
                        onZonSecildi: (zon) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TikanmaDetayEkrani(zonNumarasi: zon),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Tüm Zonlar',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (tumZonlar.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          'Henüz izlenen zon yok.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ...tumZonlar.map(
                        (zon) => ZonDurumKarti(
                          zonNumarasi: zon,
                          zonAdi: durum.zonAdiGetir(zon),
                          okuma: durum.sonOkuma(zon),
                          cevrimici: durum.zonCevrimiciMi(zon),
                          sulamaDurdurulduMu: durum.sulamasiDurduruldu(zon),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TikanmaDetayEkrani(zonNumarasi: zon),
                            ),
                          ),
                        ),
                      ),
                    if (ozet.tedavide > 0) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Aktif Tedaviler',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AktifTedavilerBolumu(
                        zonlar: tumZonlar,
                        okumaGetir: durum.sonOkuma,
                        baslangicGetir: durum.tedaviBaslangicZamani,
                        adGetir: durum.zonAdiGetir,
                        onZonSecildi: (zon) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TikanmaDetayEkrani(zonNumarasi: zon),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Son Aktiviteler',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AktiviteGecmisiEkrani(),
                              ),
                            ),
                            child: const Text('Tümünü Gör'),
                          ),
                        ],
                      ),
                    ),
                    if (sonAktiviteler.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          'Henüz aktivite kaydı yok.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ...sonAktiviteler.map(
                        (kayit) => _AktiviteSatiri(kayit: kayit),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: durum.hazir && tumZonlar.isNotEmpty
          ? const AcilDurdurmaFab()
          : null,
    );
  }
}

class _IstatistikKarti extends StatelessWidget {
  final int deger;
  final String etiket;
  final IconData ikon;
  final Color? vurgulaRenk;

  const _IstatistikKarti({
    required this.deger,
    required this.etiket,
    required this.ikon,
    this.vurgulaRenk,
  });

  @override
  Widget build(BuildContext context) {
    final renk = vurgulaRenk ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(ikon, color: renk),
              const SizedBox(height: 8),
              Text(
                '$deger',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
              Text(
                etiket,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurumOzetRozeti extends StatelessWidget {
  final int sayi;
  final String etiket;
  final Color renk;

  const _DurumOzetRozeti({
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
                fontSize: 18,
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

class _AktiviteSatiri extends StatelessWidget {
  final AktiviteKaydi kayit;
  const _AktiviteSatiri({required this.kayit});

  @override
  Widget build(BuildContext context) {
    final renk = kayit.renkGetir(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: renk.withValues(alpha: 0.15),
        child: Icon(kayit.ikon, color: renk, size: 20),
      ),
      title: Text(kayit.mesaj, style: const TextStyle(fontSize: 13)),
      subtitle: Text(DateFormat('dd.MM HH:mm:ss').format(kayit.zaman)),
    );
  }
}
