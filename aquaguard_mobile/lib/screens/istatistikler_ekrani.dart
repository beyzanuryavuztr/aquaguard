/// AquaGuard - Istatistikler Ekrani
/// ====================================
///
/// Amac:
///   Sistemin biriktirdigi veriden turetilmis analitik gorunum: hangi
///   tikanma turu ne siklikta goruluyor, kac tedavi tetiklendi ve
///   AquaGuard'in projelendirilen ekonomik/operasyonel etkisi nedir.
///
///   ONEMLI: "Etki ve Tasarruf" karti CANLI VERIDEN degil, PROJE_BRIEF.md
///   SS7'deki DOGRULANMIS literatur/hesaplama degerlerinden gelir (bu
///   acikca belirtilir) -- demo modundaki rastgele senaryolarla
///   KARISTIRILMAMALIDIR.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../providers/uygulama_durumu.dart';
import '../services/disa_aktarma_factory.dart';
import '../services/disa_aktarma_servisi.dart';
import '../widgets/duyarli_icerik.dart';

class IstatistiklerEkrani extends StatelessWidget {
  const IstatistiklerEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final tumOkumalar = durum.tumOkumalarBirlesik;

    final turSayaclari = <TikanmaTuru, int>{
      TikanmaTuru.kimyasal: 0,
      TikanmaTuru.biyolojik: 0,
      TikanmaTuru.fiziksel: 0,
    };
    for (final okuma in tumOkumalar) {
      if (okuma.durum == TeshisDurumu.tespitEdildi) {
        turSayaclari[okuma.tikanmaTuru] =
            (turSayaclari[okuma.tikanmaTuru] ?? 0) + 1;
      }
    }
    final toplamTespit = turSayaclari.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Tüm Zonların Raporunu Dışa Aktar (CSV)',
            onPressed: tumOkumalar.isEmpty
                ? null
                : () => _raporuDisaAktar(context, tumOkumalar),
          ),
        ],
      ),
      body: DuyarliIcerik(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tıkanma Türü Dağılımı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              toplamTespit == 0
                  ? 'Henüz tıkanma tespiti kaydedilmedi.'
                  : 'Şimdiye kadar tespit edilen $toplamTespit tıkanma olayının türe göre dağılımı:',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: toplamTespit == 0
                    ? const SizedBox(
                        height: 120,
                        child: Center(
                          child: Text('Grafik için yeterli veri yok'),
                        ),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            height: 140,
                            width: 140,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 32,
                                sections: [
                                  _dilimOlustur(
                                    turSayaclari[TikanmaTuru.kimyasal]!,
                                    toplamTespit,
                                    const Color(0xFFEF6C00),
                                  ),
                                  _dilimOlustur(
                                    turSayaclari[TikanmaTuru.biyolojik]!,
                                    toplamTespit,
                                    const Color(0xFF2E7D32),
                                  ),
                                  _dilimOlustur(
                                    turSayaclari[TikanmaTuru.fiziksel]!,
                                    toplamTespit,
                                    const Color(0xFF1565C0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LejantSatiri(
                                  renk: const Color(0xFFEF6C00),
                                  etiket: 'Kimyasal',
                                  sayi: turSayaclari[TikanmaTuru.kimyasal]!,
                                ),
                                _LejantSatiri(
                                  renk: const Color(0xFF2E7D32),
                                  etiket: 'Biyolojik',
                                  sayi: turSayaclari[TikanmaTuru.biyolojik]!,
                                ),
                                _LejantSatiri(
                                  renk: const Color(0xFF1565C0),
                                  etiket: 'Fiziksel',
                                  sayi: turSayaclari[TikanmaTuru.fiziksel]!,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tedavi Sayıları',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TedaviSayacKarti(
                  etiket: 'Asit\nDozlama',
                  sayi: durum.tedaviSayaclari[TedaviTuru.asitDozlama] ?? 0,
                  renk: const Color(0xFFEF6C00),
                ),
                const SizedBox(width: 10),
                _TedaviSayacKarti(
                  etiket: 'Klor\nEnjeksiyon',
                  sayi: durum.tedaviSayaclari[TedaviTuru.klorEnjeksiyon] ?? 0,
                  renk: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 10),
                _TedaviSayacKarti(
                  etiket: 'Yüksek Basınçlı\nYıkama',
                  sayi:
                      durum.tedaviSayaclari[TedaviTuru.yuksekBasincliYikama] ??
                      0,
                  renk: const Color(0xFF1565C0),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _EtkiVeTasarrufKarti(),
          ],
        ),
      ),
    );
  }

  Future<void> _raporuDisaAktar(
    BuildContext context,
    List<SensorOkuma> tumOkumalar,
  ) async {
    final csv = DisaAktarmaServisi.csvOlustur(tumOkumalar);
    final dosyaAdi = DisaAktarmaServisi.dosyaAdiUret('tum_zonlar_raporu');
    final konum = await csvKaydet(dosyaAdi, csv);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV dışa aktarıldı: $konum')),
    );
  }

  PieChartSectionData _dilimOlustur(int sayi, int toplam, Color renk) {
    final yuzde = toplam == 0 ? 0.0 : (sayi / toplam) * 100;
    return PieChartSectionData(
      value: sayi.toDouble() == 0 ? 0.001 : sayi.toDouble(),
      title: sayi == 0 ? '' : '%${yuzde.toStringAsFixed(0)}',
      color: renk,
      radius: 44,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _LejantSatiri extends StatelessWidget {
  final Color renk;
  final String etiket;
  final int sayi;

  const _LejantSatiri({
    required this.renk,
    required this.etiket,
    required this.sayi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(etiket)),
          Text('$sayi', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TedaviSayacKarti extends StatelessWidget {
  final String etiket;
  final int sayi;
  final Color renk;

  const _TedaviSayacKarti({
    required this.etiket,
    required this.sayi,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                '$sayi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: renk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                etiket,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtkiVeTasarrufKarti extends StatelessWidget {
  const _EtkiVeTasarrufKarti();

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco_outlined, color: renkSemasi.primary),
                const SizedBox(width: 8),
                Text(
                  'Projelendirilen Etki',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'PROJE_BRIEF.md doğrulanmış istatistiklerine dayanır (canlı veriden değil).',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            const _EtkiSatiri(
              ikon: Icons.trending_down,
              baslik: 'Tedavisiz debi düşüşü (5 yıl)',
              deger: '%11.7',
              kaynak: 'Ma vd., 2025',
            ),
            const _EtkiSatiri(
              ikon: Icons.schedule,
              baslik: 'Tedavisiz sistem ömrü',
              deger: '8–11 yıl',
              kaynak: 'Ma vd., 2025',
            ),
            const _EtkiSatiri(
              ikon: Icons.payments_outlined,
              baslik: 'Geri ödeme süresi',
              deger: '3–5 sezon',
              kaynak: 'Takım hesaplaması',
            ),
            const _EtkiSatiri(
              ikon: Icons.water,
              baslik: 'Türkiye tarımsal su kullanımı',
              deger: '%79',
              kaynak: 'T.C. Tarım ve Orman Bakanlığı DSİ, 2024',
              sonSatir: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _EtkiSatiri extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String deger;
  final String kaynak;
  final bool sonSatir;

  const _EtkiSatiri({
    required this.ikon,
    required this.baslik,
    required this.deger,
    required this.kaynak,
    this.sonSatir = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: sonSatir ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(fontSize: 13)),
                Text(
                  kaynak,
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ],
            ),
          ),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
