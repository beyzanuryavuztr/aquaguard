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
import 'package:provider/provider.dart';

import '../config/tarih_bicimleri.dart';
import '../models/aktivite_kaydi.dart';
import '../providers/aktivite_bildirim_provider.dart';
import '../providers/bakim_provider.dart';
import '../providers/cihaz_iletisim_provider.dart';
import '../providers/tarla_provider.dart';
import '../widgets/acil_durdurma_cubugu.dart';
import '../widgets/aktif_tedaviler_bolumu.dart';
import '../widgets/bakim_uyari_karti.dart';
import '../widgets/cevrimdisi_banner.dart';
import '../widgets/demo_modu_banner.dart';
import '../widgets/demo_senaryo_paneli.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/enerji_gostergesi.dart';
import '../widgets/sistem_sagligi_gostergesi.dart';
import '../widgets/yardim_butonu.dart';
import '../widgets/zon_durum_karti.dart';
import '../widgets/zon_semasi.dart';
import 'aktivite_gecmisi_ekrani.dart';
import 'ayarlar_ekrani.dart';
import 'bildirim_gecmisi_ekrani.dart';
import 'besin_takviyesi_ekrani.dart';
import 'juri_sunum_ekrani.dart';
import 'tarla_secim_ekrani.dart';
import 'uzaktan_sulama_ekrani.dart';
import 'tikanma_detay_ekrani.dart';

class GenelBakisEkrani extends StatelessWidget {
  const GenelBakisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Facade yerine dogrudan ilgili 4 provider'i izler (Faz "ekran
    // migrasyonu") -- bu ekran GERCEKTEN 4'unun de verisini kullaniyor
    // (Cihaz/Tarla/Bakim/Aktivite), ama ARTIK diger 2 provider'daki
    // (Ayarlar, Guvenlik) degisikliklerde GEREKSIZ YERE yeniden cizilmiyor.
    final cihaz = context.watch<CihazIletisimProvider>();
    final tarla = context.watch<TarlaProvider>();
    final bakim = context.watch<BakimProvider>();
    final aktivite = context.watch<AktiviteBildirimProvider>();

    final tumZonlar = tarla.tumZonNumaralari;
    final ozet = cihaz.durumOzetiHesapla(tumZonlar);
    final sonAktiviteler = aktivite.aktiviteGecmisi.take(6).toList();

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
          const YardimButonu(ekranAnahtari: 'genel_bakis', baslik: 'Genel Bakış'),
          Badge(
            label: Text('${aktivite.okunmamisBildirimSayisi}'),
            isLabelVisible: aktivite.okunmamisBildirimSayisi > 0,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Bildirim Geçmişi',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BildirimGecmisiEkrani()),
              ),
            ),
          ),
          if (cihaz.demoModuAktif)
            IconButton(
              icon: const Icon(Icons.co_present_outlined),
              tooltip: 'Jüri Sunum Modu',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JuriSunumEkrani()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.grass_outlined),
            tooltip: 'Çiftlikler',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TarlaSecimEkrani()),
            ),
          ),
        ],
      ),
      body: !cihaz.hazir
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _icerik(
                    context,
                    cihaz,
                    tarla,
                    bakim,
                    ozet,
                    tumZonlar,
                    sonAktiviteler,
                  ),
                ),
                // ACIMASIZ DENETIM (2026-09-25): daha once yuzen bir FAB'di,
                // sayfa kisaldikca (redundancy sadelestirmesi sonrasi) alttaki
                // Hizli Eylem butonlarinin UZERINE binmeye basladi -- artik
                // sabit, tam genislikte bir cubuk: kaydirilabilir alanin
                // KENDI ayrilmis seridi, hicbir icerigin ustune binmez.
                if (tumZonlar.isNotEmpty) const AcilDurdurmaCubugu(),
              ],
            ),
    );
  }

  Widget _icerik(
    BuildContext context,
    CihazIletisimProvider cihaz,
    TarlaProvider tarla,
    BakimProvider bakim,
    ZonDurumOzeti ozet,
    List<int> tumZonlar,
    List<AktiviteKaydi> sonAktiviteler,
  ) {
    return DuyarliIcerik(
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
                    if (cihaz.demoModuAktif) ...[
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
                    ] else if (!cihaz.cihazBagliMi) ...[
                      const CevrimdisiBanner(),
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
                    if (bakim.bakimUyarisiVarMi)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: BakimUyariKarti(
                          gorevler: bakim.bakimGorevleri,
                          onAyarlaraGit: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AyarlarEkrani(),
                            ),
                          ),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _HizliEylemlerBolumu(),
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
                            deger: tarla.tarlalar.length,
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
                        okumaGetir: cihaz.sonOkuma,
                        cevrimiciMi: cihaz.zonCevrimiciMi,
                        adGetir: tarla.zonAdiGetir,
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
                          zonAdi: tarla.zonAdiGetir(zon),
                          okuma: cihaz.sonOkuma(zon),
                          cevrimici: cihaz.zonCevrimiciMi(zon),
                          sulamaDurdurulduMu: cihaz.sulamasiDurduruldu(zon),
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
                        okumaGetir: cihaz.sonOkuma,
                        baslangicGetir: cihaz.tedaviBaslangicZamani,
                        adGetir: tarla.zonAdiGetir,
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
            );
  }
}

/// Uzaktan Sulama ve Besin Takviyesi'ne DOĞRUDAN, YAZILI erişim.
///
/// ACIMASIZ DENETIM (2026-09-25): bu iki eylem daha önce sadece AppBar'daki
/// etiketsiz "⋮" (Daha fazla) menüsünün İÇİNDEYDİ -- AppBar'da zaten
/// Yardım/Bildirim/Jüri Sunum/Çiftlikler ikonlarıyla birlikte 4-5 ikon
/// yan yana sıkışık duruyordu, "⋮" ikonu görsel olarak hiçbir ipucu
/// vermiyordu. Kullanıcı gerçek uygulamada denedi ve özelliği BULAMADI
/// ("sulama başlat... hala yok") -- kod çalışıyordu ama keşfedilemiyordu.
/// Artık ana ekranın gövdesinde, yazılı iki buton olarak duruyor.
class _HizliEylemlerBolumu extends StatelessWidget {
  const _HizliEylemlerBolumu();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UzaktanSulamaEkrani()),
            ),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text('Sulama Başlat'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BesinTakviyesiEkrani()),
            ),
            icon: const Icon(Icons.grain_outlined),
            label: const Text('Besin Takviyesi'),
          ),
        ),
      ],
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

class _AktiviteSatiri extends StatelessWidget {
  final AktiviteKaydi kayit;
  const _AktiviteSatiri({required this.kayit});

  @override
  Widget build(BuildContext context) {
    final renk = kayit.renkGetir(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: renk.rozetTonu,
        child: Icon(kayit.ikon, color: renk, size: 20),
      ),
      title: Text(kayit.mesaj, style: const TextStyle(fontSize: 13)),
      subtitle: Text(TarihBicimleri.kompaktZamanli.format(kayit.zaman)),
    );
  }
}
