/// AquaGuard - Tikanma Detay Ekrani
/// ====================================
///
/// Amac:
///   Bir zonun GUNCEL sensor degerlerini, teshis durumunu, tikanma turunu
///   ve guven skorunu detayli gosterir. Tedavi aktifse, aktif tedavi
///   ekranina gecis icin bir banner/buton gosterir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/aciklanabilirlik_paneli.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/manuel_mudahale_paneli.dart';
import '../widgets/mini_trend_grafigi.dart';
import 'aktif_tedavi_ekrani.dart';

class TikanmaDetayEkrani extends StatelessWidget {
  final int zonNumarasi;

  const TikanmaDetayEkrani({super.key, required this.zonNumarasi});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final okuma = durum.sonOkuma(zonNumarasi);
    final cevrimici = durum.zonCevrimiciMi(zonNumarasi);
    final renk = DurumRenkleri.renkGetir(okuma: okuma, cevrimici: cevrimici);

    // Sparkline'lar icin son 20 okuma, ESKIDEN YENIYE sirali.
    final sonOkumalar = durum
        .gecmis(zonNumarasi)
        .take(20)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Zon $zonNumarasi Detayı')),
      body: okuma == null
          ? const Center(child: Text('Bu zon için henüz veri alınmadı'))
          : DuyarliIcerik(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!cevrimici) _CevrimdisiBanner(okuma: okuma),
                  _DurumOzetKarti(
                    okuma: okuma,
                    cevrimici: cevrimici,
                    renk: renk,
                  ),
                  const SizedBox(height: 16),
                  if (okuma.tedaviAktif != TedaviTuru.yok ||
                      okuma.durulamaAktif) ...[
                    _TedaviBanner(zonNumarasi: zonNumarasi, okuma: okuma),
                    const SizedBox(height: 16),
                  ],
                  ManuelMudahalePaneli(
                    zonNumarasi: zonNumarasi,
                    okuma: okuma,
                  ),
                  if (okuma.durum == TeshisDurumu.tespitEdildi ||
                      okuma.durum == TeshisDurumu.belirsiz) ...[
                    AciklanabilirlikPaneli(okuma: okuma),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Sensör Eğilimleri',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _SensorTrendIzgarasi(sonOkumalar: sonOkumalar),
                ],
              ),
            ),
    );
  }
}

class _CevrimdisiBanner extends StatelessWidget {
  final SensorOkuma okuma;
  const _CevrimdisiBanner({required this.okuma});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DurumRenkleri.cevrimdisi.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: DurumRenkleri.cevrimdisi),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Çevrimdışı — gösterilen veri ${DateFormat('dd.MM.yyyy HH:mm:ss').format(okuma.zaman)} '
              'tarihine ait son bilinen durumdur.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DurumOzetKarti extends StatelessWidget {
  final SensorOkuma okuma;
  final bool cevrimici;
  final Color renk;

  const _DurumOzetKarti({
    required this.okuma,
    required this.cevrimici,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: renk.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  DurumRenkleri.ikonGetir(okuma: okuma, cevrimici: cevrimici),
                  color: renk,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    durumEtiketi(okuma.durum),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: renk,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _bilgiSatiri('Tıkanma Türü', turEtiketi(okuma.tikanmaTuru)),
            _bilgiSatiri('Güven Skoru', '%${okuma.guven.toStringAsFixed(1)}'),
            _bilgiSatiri(
              'Son Güncelleme',
              DateFormat('dd.MM.yyyy HH:mm:ss').format(okuma.zaman),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilgiSatiri(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiket, style: const TextStyle(color: Colors.black54)),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TedaviBanner extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;

  const _TedaviBanner({required this.zonNumarasi, required this.okuma});

  @override
  Widget build(BuildContext context) {
    final metin = okuma.tedaviAktif != TedaviTuru.yok
        ? '${tedaviEtiketi(okuma.tedaviAktif)} uygulanıyor'
        : 'Zorunlu durulama sürüyor';

    return Card(
      color: DurumRenkleri.tedaviAktif.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(
          Icons.build_circle,
          color: DurumRenkleri.tedaviAktif,
        ),
        title: Text(metin, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Ayrıntılar ve ilerleme için dokunun'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AktifTedaviEkrani(zonNumarasi: zonNumarasi),
          ),
        ),
      ),
    );
  }
}

class _SensorTrendIzgarasi extends StatelessWidget {
  final List<SensorOkuma> sonOkumalar;
  const _SensorTrendIzgarasi({required this.sonOkumalar});

  @override
  Widget build(BuildContext context) {
    final tanimlar =
        <
          (
            String baslik,
            String birim,
            Color renk,
            double Function(SensorOkuma) secici,
          )
        >[
          ('pH', '', const Color(0xFF6D4C41), (o) => o.ph),
          ('EC', 'mS/cm', const Color(0xFF00838F), (o) => o.ec),
          ('ORP', 'mV', const Color(0xFF6A1B9A), (o) => o.orp),
          ('Türbidite', 'NTU', const Color(0xFFEF6C00), (o) => o.turbidite),
          ('Debi', 'LPM', const Color(0xFF1565C0), (o) => o.debi),
          (
            'Diferansiyel Basınç',
            'bar',
            const Color(0xFFC62828),
            (o) => o.deltaBasinc,
          ),
        ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: tanimlar.map((tanim) {
        final (baslik, birim, renk, secici) = tanim;
        return MiniTrendGrafigi(
          baslik: baslik,
          birim: birim,
          renk: renk,
          degerler: sonOkumalar.map(secici).toList(),
        );
      }).toList(),
    );
  }
}
