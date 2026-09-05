/// AquaGuard - Tedavi Geçmişi Ekranı (Ekran 3)
/// =================================================
///
/// Amac:
///   Önceki İstatistikler ekranının analitik içeriğini (tıkanma türü
///   dağılımı, tedavi sayıları, brief-tabanlı "Projelendirilen Etki"
///   kartı) YENİ bir "Ortalama Başarı Oranı" kartı ve zon/tür/tarih
///   filtrelenebilir bir tıkanma-tespiti günlüğüyle birleştirir.
///
///   NOT: `screens/aktivite_gecmisi_ekrani.dart` ve
///   `screens/gecmis_loglar_ekrani.dart` BAŞKA ekranlardır, silinmedi --
///   ilki Genel Bakış'ın "Son Aktiviteler" özetinin TAM listesi (durum/
///   tedavi GEÇİŞLERİ, tüm sistem), ikincisi TEK BİR çiftliğin HAM sensör
///   okuma loglarını gösterir (Zon Dashboard'dan erişilir). Bu ekran ise
///   TÜM sistem genelinde ANALİZ + filtrelenebilir tespit günlüğüdür.
///
/// Tarih:  2026-09-05
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../models/tedavi_basari_analizi.dart';
import '../models/tikanma_olayi.dart';
import '../providers/uygulama_durumu.dart';
import '../services/disa_aktarma_factory.dart';
import '../services/disa_aktarma_servisi.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/tikanma_turu_ikonu.dart';

enum _TarihAraligi { tumu, saat24, gun7, gun30 }

extension on _TarihAraligi {
  Duration? get pencere => switch (this) {
    _TarihAraligi.tumu => null,
    _TarihAraligi.saat24 => const Duration(hours: 24),
    _TarihAraligi.gun7 => const Duration(days: 7),
    _TarihAraligi.gun30 => const Duration(days: 30),
  };

  String get etiket => switch (this) {
    _TarihAraligi.tumu => 'Tümü',
    _TarihAraligi.saat24 => 'Son 24s',
    _TarihAraligi.gun7 => 'Son 7g',
    _TarihAraligi.gun30 => 'Son 30g',
  };
}

class TedaviGecmisiEkrani extends StatefulWidget {
  const TedaviGecmisiEkrani({super.key});

  @override
  State<TedaviGecmisiEkrani> createState() => _TedaviGecmisiEkraniState();
}

class _TedaviGecmisiEkraniState extends State<TedaviGecmisiEkrani> {
  int? _seciliZon; // null = tumu
  TikanmaTuru? _seciliTur; // null = tumu
  _TarihAraligi _seciliDonem = _TarihAraligi.tumu;

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final tumZonlar = durum.tumZonNumaralari;
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

    final basariAnalizi = TedaviBasariAnalizi.birlestir(
      tumZonlar.map((z) => tedaviBasarisiniHesapla(durum.gecmis(z))),
    );

    final tumOlaylar = <TikanmaOlayi>[
      for (final z in tumZonlar)
        ...tikanmaOlaylariniBul(durum.gecmis(z).reversed.toList()),
    ]..sort((a, b) => b.zaman.compareTo(a.zaman));

    final simdi = DateTime.now();
    final pencere = _seciliDonem.pencere;
    final filtreliOlaylar = tumOlaylar.where((o) {
      if (_seciliZon != null && o.zone != _seciliZon) return false;
      if (_seciliTur != null && o.tur != _seciliTur) return false;
      if (pencere != null && simdi.difference(o.zaman) > pencere) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedavi Geçmişi'),
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
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            _BasariOraniKarti(analiz: basariAnalizi),
            const SizedBox(height: 24),
            const _EtkiVeTasarrufKarti(),
            const SizedBox(height: 24),
            Text(
              'Tespit Günlüğü',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _FiltreSatiri(
              baslik: 'Zon',
              secili: _seciliZon,
              secenekler: tumZonlar,
              etiketUret: (z) => z == null ? 'Tümü' : durum.zonAdiGetir(z),
              onSecim: (z) => setState(() => _seciliZon = z),
            ),
            const SizedBox(height: 8),
            _FiltreSatiri(
              baslik: 'Tür',
              secili: _seciliTur,
              secenekler: const [
                TikanmaTuru.kimyasal,
                TikanmaTuru.biyolojik,
                TikanmaTuru.fiziksel,
              ],
              etiketUret: (t) => t == null ? 'Tümü' : turEtiketi(t),
              onSecim: (t) => setState(() => _seciliTur = t),
            ),
            const SizedBox(height: 8),
            _FiltreSatiri(
              baslik: 'Dönem',
              secili: _seciliDonem,
              secenekler: _TarihAraligi.values
                  .where((d) => d != _TarihAraligi.tumu)
                  .toList(),
              varsayilanDeger: _TarihAraligi.tumu,
              etiketUret: (d) => (d ?? _TarihAraligi.tumu).etiket,
              onSecim: (d) =>
                  setState(() => _seciliDonem = d ?? _TarihAraligi.tumu),
            ),
            const SizedBox(height: 12),
            if (filtreliOlaylar.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  tumOlaylar.isEmpty
                      ? 'Henüz tıkanma tespiti kaydedilmedi.'
                      : 'Seçilen filtrelere uyan kayıt yok.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...filtreliOlaylar
                  .take(100)
                  .map((olay) => _OlaySatiri(olay: olay)),
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

class _BasariOraniKarti extends StatelessWidget {
  final TedaviBasariAnalizi analiz;
  const _BasariOraniKarti({required this.analiz});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final yuzde = (analiz.basariOrani * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ortalama Başarı Oranı',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analiz.tamamlananSayisi == 0
                        ? 'Henüz tamamlanmış tedavi yok.'
                        : '${analiz.tamamlananSayisi} tamamlanmış tedaviden ${analiz.basariliSayisi} tanesi debiyi referans değere döndürdü.',
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              analiz.tamamlananSayisi == 0 ? '—' : '%$yuzde',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltreSatiri<T> extends StatelessWidget {
  final String baslik;
  final T? secili;
  final List<T> secenekler;
  final T? varsayilanDeger;
  final String Function(T?) etiketUret;
  final ValueChanged<T?> onSecim;

  const _FiltreSatiri({
    required this.baslik,
    required this.secili,
    required this.secenekler,
    required this.etiketUret,
    required this.onSecim,
    this.varsayilanDeger,
  });

  @override
  Widget build(BuildContext context) {
    final tumSecenekler = <T?>[varsayilanDeger, ...secenekler];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            baslik,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final secenek in tumSecenekler)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(etiketUret(secenek)),
                      selected: secili == secenek,
                      onSelected: (_) => onSecim(secenek),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OlaySatiri extends StatelessWidget {
  final TikanmaOlayi olay;
  const _OlaySatiri({required this.olay});

  @override
  Widget build(BuildContext context) {
    final bilgi = tikanmaTuruBilgisiGetir(olay.tur);
    final zonAdi = context.read<UygulamaDurumu>().zonAdiGetir(olay.zone);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: bilgi.renk.withValues(alpha: 0.15),
        child: TikanmaTuruIkonu(tur: olay.tur, boyut: 20),
      ),
      title: Text(
        '$zonAdi — ${turEtiketi(olay.tur)} tıkanma tespit edildi',
      ),
      subtitle: Text(
        'Güven %${olay.guven.toStringAsFixed(0)} • '
        '${DateFormat('dd.MM.yyyy HH:mm:ss').format(olay.zaman)}',
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
            Text(
              'PROJE_BRIEF.md doğrulanmış istatistiklerine dayanır (canlı veriden değil).',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          Icon(
            ikon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(fontSize: 13)),
                Text(
                  kaynak,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
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
