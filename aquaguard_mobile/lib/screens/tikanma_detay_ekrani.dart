/// AquaGuard - Tikanma Detay Ekrani
/// ====================================
///
/// Amac:
///   Bir zonun GUNCEL sensor degerlerini, teshis durumunu, tikanma turunu
///   ve guven skorunu detayli gosterir. Tedavi aktifse, aktif tedavi
///   ekranina gecis icin bir banner/buton gosterir.
///
///   ASAMA 3 GENISLEMESI (2026-09-04): sabit 6'lı sparkline izgarasinin
///   yerini, "once ozet karta dokun, sonra buyuk grafige bak" akisiyla
///   SensorKarti + tek buyuk SensorTrendGrafigi aldi; ayrica mutex kilit
///   gostergesi, karar katmani durustluk etiketi ve tedavi once/sonra
///   karsilastirmasi eklendi. Mevcut SulamaKontrolKarti, ManuelMudahalePaneli
///   ve AciklanabilirlikPaneli KORUNDU, yerlerinde kaldi.
///
/// Tarih:  2026-09-01 (Asama 3 genislemesi: 2026-09-04)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/sensor_imzalari.dart';
import '../models/sensor_okuma.dart';
import '../models/tedavi_karsilastirmasi.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/aciklanabilirlik_paneli.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/manuel_mudahale_paneli.dart';
import '../widgets/mutex_kilit_gostergesi.dart';
import '../widgets/sensor_karti.dart';
import '../widgets/sensor_trend_grafigi.dart';
import '../widgets/sulama_kontrol_karti.dart';
import '../widgets/tikanma_turu_ikonu.dart';
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
    final gecmisEnYeniOnce = durum.gecmis(zonNumarasi);
    final oncesiSonrasi = tedaviOncesiSonrasiBul(gecmisEnYeniOnce);

    return Scaffold(
      appBar: AppBar(title: Text('Zon $zonNumarasi Detayı')),
      body: okuma == null
          ? const Center(child: Text('Bu zon için henüz veri alınmadı'))
          : DuyarliIcerik(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SulamaKontrolKarti(zonNumarasi: zonNumarasi),
                  if (!cevrimici) _CevrimdisiBanner(okuma: okuma),
                  _DurumOzetKarti(
                    okuma: okuma,
                    cevrimici: cevrimici,
                    renk: renk,
                  ),
                  const SizedBox(height: 16),
                  const _KararKatmaniEtiketi(),
                  const SizedBox(height: 16),
                  MutexKilitGostergesi(aktifTedavi: okuma.tedaviAktif),
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
                  if (oncesiSonrasi != null) ...[
                    _OncesiSonrasiKarti(oncesiSonrasi: oncesiSonrasi),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Sensör Analizi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _SensorAnaliziBolumu(gecmisEnYeniOnce: gecmisEnYeniOnce),
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
            _tikanmaTuruSatiri(context),
            _bilgiSatiri(
              context,
              'Güven Skoru',
              '%${okuma.guven.toStringAsFixed(1)}',
            ),
            _bilgiSatiri(
              context,
              'Son Güncelleme',
              DateFormat('dd.MM.yyyy HH:mm:ss').format(okuma.zaman),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tikanmaTuruSatiri(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tıkanma Türü',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              if (okuma.tikanmaTuru != TikanmaTuru.yok) ...[
                TikanmaTuruIkonu(tur: okuma.tikanmaTuru, boyut: 16),
                const SizedBox(width: 6),
              ],
              Text(
                turEtiketi(okuma.tikanmaTuru),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bilgiSatiri(BuildContext context, String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiket,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// DURUSTLUK NOTU: brief, teshisin hangi "katman" tarafindan yapildiginin
/// gosterilmesini istiyor. Gercek: RF (Katman 2), sadece
/// python/aquaguard_karar_motoru.py icinde OFFLINE model dogrulamasi icin
/// var -- hicbir CANLI uygulamada (bu Dart demosu dahil) gercek zamanli RF
/// cikarimi CALISMIYOR. Bu yuzden burada HER ZAMAN "Kural Tabanli (Katman 1)"
/// gosterilir; RF'in offline dogrulama katmani oldugu kucuk notla belirtilir.
/// Asla "yapay zeka karar veriyor" gibi yanlis bir izlenim verilmez.
class _KararKatmaniEtiketi extends StatelessWidget {
  const _KararKatmaniEtiketi();

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_tree, size: 18, color: onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Karar Katmanı: Kural Tabanlı (Katman 1 — birincil)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Yapay zeka (Katman 2) yalnızca çevrimdışı doğrulama içindir, canlı teşhiste kullanılmaz.',
                  style: TextStyle(fontSize: 11, color: onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OncesiSonrasiKarti extends StatelessWidget {
  final TedaviOncesiSonrasi oncesiSonrasi;
  const _OncesiSonrasiKarti({required this.oncesiSonrasi});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final iyilesmeVar = oncesiSonrasi.sonraDebi > oncesiSonrasi.onceDebi;
    final fark = oncesiSonrasi.sonraDebi - oncesiSonrasi.onceDebi;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Tedavi Etkisi',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('dd.MM HH:mm').format(oncesiSonrasi.tedaviBaslangicZamani)} tarihli tedavi öncesi/sonrası debi',
              style: TextStyle(fontSize: 11, color: onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _debiKutusu(
                    context,
                    etiket: 'Önce',
                    deger: oncesiSonrasi.onceDebi,
                  ),
                ),
                Icon(Icons.arrow_forward, color: onSurfaceVariant, size: 18),
                Expanded(
                  child: _debiKutusu(
                    context,
                    etiket: 'Sonra',
                    deger: oncesiSonrasi.sonraDebi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  iyilesmeVar ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: iyilesmeVar
                      ? DurumRenkleri.normal
                      : DurumRenkleri.tespitEdildi,
                ),
                const SizedBox(width: 6),
                Text(
                  '${fark >= 0 ? '+' : ''}${fark.toStringAsFixed(2)} LPM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iyilesmeVar
                        ? DurumRenkleri.normal
                        : DurumRenkleri.tespitEdildi,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _debiKutusu(
    BuildContext context, {
    required String etiket,
    required double deger,
  }) {
    return Column(
      children: [
        Text(
          etiket,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${deger.toStringAsFixed(2)} LPM',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
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

class _SensorTanimi {
  final String baslik;
  final String birim;
  final Color renk;
  final IconData ikon;
  final double Function(SensorOkuma) secici;
  final List<EsikCizgisi> esikler;

  const _SensorTanimi({
    required this.baslik,
    required this.birim,
    required this.renk,
    required this.ikon,
    required this.secici,
    this.esikler = const [],
  });
}

final _sensorTanimlari = <_SensorTanimi>[
  _SensorTanimi(
    baslik: 'pH',
    birim: '',
    renk: const Color(0xFF6D4C41),
    ikon: Icons.science,
    secici: (o) => o.ph,
  ),
  _SensorTanimi(
    baslik: 'EC',
    birim: 'mS/cm',
    renk: const Color(0xFF00838F),
    ikon: Icons.bolt,
    secici: (o) => o.ec,
  ),
  _SensorTanimi(
    baslik: 'ORP',
    birim: 'mV',
    renk: const Color(0xFF6A1B9A),
    ikon: Icons.swap_vert,
    secici: (o) => o.orp,
  ),
  _SensorTanimi(
    baslik: 'Türbidite',
    birim: 'NTU',
    renk: const Color(0xFFEF6C00),
    ikon: Icons.blur_on,
    secici: (o) => o.turbidite,
    esikler: [
      EsikCizgisi(
        deger: turbiditeEsigi,
        etiket: 'Eşik ${turbiditeEsigi.toStringAsFixed(0)} NTU',
        renk: DurumRenkleri.tespitEdildi,
      ),
    ],
  ),
  _SensorTanimi(
    baslik: 'Debi',
    birim: 'LPM',
    renk: const Color(0xFF1565C0),
    ikon: Icons.water,
    secici: (o) => o.debi,
    esikler: [
      EsikCizgisi(
        deger: referansDebi - debiDususEsigi,
        etiket:
            'Alt sınır ${(referansDebi - debiDususEsigi).toStringAsFixed(1)} LPM',
        renk: DurumRenkleri.tespitEdildi,
      ),
    ],
  ),
  _SensorTanimi(
    baslik: 'ΔBasınç',
    birim: 'bar',
    renk: const Color(0xFFC62828),
    ikon: Icons.speed,
    secici: (o) => o.deltaBasinc,
    esikler: [
      EsikCizgisi(
        deger: basincArtisEsigi,
        etiket: 'Üst sınır ${basincArtisEsigi.toStringAsFixed(2)} bar',
        renk: DurumRenkleri.tespitEdildi,
      ),
    ],
  ),
];

class _SensorAnaliziBolumu extends StatefulWidget {
  final List<SensorOkuma> gecmisEnYeniOnce;
  const _SensorAnaliziBolumu({required this.gecmisEnYeniOnce});

  @override
  State<_SensorAnaliziBolumu> createState() => _SensorAnaliziBolumuState();
}

class _SensorAnaliziBolumuState extends State<_SensorAnaliziBolumu> {
  // Varsayilan olarak Debi secili -- tikanma tespitinde en dogrudan
  // gostergedir (referans esigiyle birebir iliskili).
  int _secilenIndeks = 4;

  @override
  Widget build(BuildContext context) {
    final guncelOkuma = widget.gecmisEnYeniOnce.isNotEmpty
        ? widget.gecmisEnYeniOnce.first
        : null;
    final tanim = _sensorTanimlari[_secilenIndeks];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            for (var i = 0; i < _sensorTanimlari.length; i++)
              SensorKarti(
                ikon: _sensorTanimlari[i].ikon,
                baslik: _sensorTanimlari[i].baslik,
                birim: _sensorTanimlari[i].birim,
                deger: guncelOkuma != null
                    ? _sensorTanimlari[i].secici(guncelOkuma)
                    : 0,
                renk: _sensorTanimlari[i].renk,
                secili: i == _secilenIndeks,
                onTap: () => setState(() => _secilenIndeks = i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SensorTrendGrafigi(
          key: ValueKey(tanim.baslik),
          baslik: tanim.baslik,
          birim: tanim.birim,
          renk: tanim.renk,
          gecmisEnYeniOnce: widget.gecmisEnYeniOnce,
          secici: tanim.secici,
          esikler: tanim.esikler,
        ),
      ],
    );
  }
}
