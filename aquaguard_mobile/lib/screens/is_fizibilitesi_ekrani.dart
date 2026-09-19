/// AquaGuard - Is Fizibilitesi Ekrani
/// ======================================
///
/// Amac:
///   PROJE_BRIEF.md SS7 (Dogrulanmis Istatistikler) ve SS8 (Rakip
///   Konumlandirma) bolumlerindeki, uygulamanin BASKA HICBIR YERINDE
///   gosterilmeyen verileri tek bir ekranda toplar: donanim maliyeti,
///   hedef satis fiyati, brut marj, ML dogrulugu (Model Performansi
///   ekranina capraz link) ve rakip karsilastirma tablosu.
///
///   `tedavi_gecmisi_ekrani.dart`'taki _EtkiVeTasarrufKarti ile
///   CAKISMAZ: o ekran debi dususu/sistem omru/geri odeme suresi/su
///   kullanimini zaten gosteriyor -- burada TEKRAR EDILMEZ.
///
///   Tum sayilar PROJE_BRIEF.md'den birebir; her satirda kaynak notu var
///   (mevcut _EtkiSatiri deseniyle tutarli).
///
/// Tarih:  2026-09-15
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../widgets/duyarli_icerik.dart';
import 'model_performansi_ekrani.dart';

class IsFizibilitesiEkrani extends StatelessWidget {
  const IsFizibilitesiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('İş Fizibilitesi')),
      body: DuyarliIcerik(
        maksimumGenislik: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maliyet ve Pazar Konumu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PROJE_BRIEF.md doğrulanmış istatistiklerine dayanır '
                      '(canlı veriden değil).',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FizibiliteSatiri(
                      ikon: Icons.build_circle_outlined,
                      baslik: 'Donanım maliyeti (1 zon)',
                      deger: '7.266 ₺',
                      kaynak: 'Takım hesaplaması',
                    ),
                    _FizibiliteSatiri(
                      ikon: Icons.sell_outlined,
                      baslik: 'Hedef satış fiyatı',
                      deger: '~11.200 ₺',
                      kaynak: 'Takım hesaplaması',
                    ),
                    _FizibiliteSatiri(
                      ikon: Icons.percent_outlined,
                      baslik: 'Brüt marj',
                      deger: '%35',
                      kaynak: 'Takım hesaplaması',
                    ),
                    _FizibiliteSatiri(
                      ikon: Icons.model_training_outlined,
                      baslik: 'ML doğruluk (sentetik veri, 5-fold CV)',
                      deger: '%89.9 ± %1.5',
                      kaynak: 'Model Performansı ekranına bakın',
                      sonSatir: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ModelPerformansiEkrani(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rakip Konumlandırma',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Özellik')),
                      DataColumn(label: Text('Netafim NetBeat')),
                      DataColumn(label: Text('Rivulis Manna')),
                      DataColumn(label: Text('AquaGuard')),
                    ],
                    rows: const [
                      DataRow(
                        cells: [
                          DataCell(Text('Tespit seviyesi')),
                          DataCell(Text('Hat seviyesi')),
                          DataCell(Text('Makro (sensörsüz)')),
                          DataCell(Text('Zon seviyesi, 6 parametre')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('Tıkanma türü teşhisi')),
                          DataCell(Text('Yok')),
                          DataCell(Text('Yok')),
                          DataCell(
                            Text('pH+EC+ORP+türbidite+hidrolik füzyon'),
                          ),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('Karar mekanizması')),
                          DataCell(Text('Operatör bildirimi')),
                          DataCell(Text('Reçete önerisi')),
                          DataCell(Text('İki katmanlı otonom (kural + RF)')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('Tedavi')),
                          DataCell(Text('Manuel')),
                          DataCell(Text('Manuel')),
                          DataCell(Text('Türe özgü otomatik enjeksiyon')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('Güvenlik')),
                          DataCell(Text('Operatöre bağlı')),
                          DataCell(Text('Yazılımsal öneri')),
                          DataCell(Text('Mutex kilidi + zorunlu durulama')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FizibiliteSatiri extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String deger;
  final String kaynak;
  final bool sonSatir;
  final VoidCallback? onTap;

  const _FizibiliteSatiri({
    required this.ikon,
    required this.baslik,
    required this.deger,
    required this.kaynak,
    this.sonSatir = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final satir = Padding(
      padding: EdgeInsets.only(bottom: sonSatir ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(fontSize: 13)),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        kaynak,
                        style: TextStyle(
                          fontSize: 10,
                          color: onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return satir;
    return InkWell(onTap: onTap, child: satir);
  }
}
