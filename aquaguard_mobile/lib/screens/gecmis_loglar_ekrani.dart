/// AquaGuard - Gecmis Loglar Ekrani
/// ====================================
///
/// Amac:
///   Bir tarladaki her zonun gecmiste alinmis okumalarini (tarih bazli)
///   listeler. Veri, UygulamaDurumu icinde hem bellekte hem de yerel
///   depolamada (SharedPreferences) tutulur; bu ekran sadece o veriyi
///   goruntuler, yeniden sorgulama yapmaz.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sensor_okuma.dart';
import '../models/tarla.dart';
import '../providers/uygulama_durumu.dart';
import '../services/disa_aktarma_factory.dart';
import '../services/disa_aktarma_servisi.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';

class GecmisLoglarEkrani extends StatefulWidget {
  final Tarla tarla;

  const GecmisLoglarEkrani({super.key, required this.tarla});

  @override
  State<GecmisLoglarEkrani> createState() => _GecmisLoglarEkraniState();
}

class _GecmisLoglarEkraniState extends State<GecmisLoglarEkrani> {
  late int _seciliZon;

  @override
  void initState() {
    super.initState();
    _seciliZon = widget.tarla.zonNumaralari.first;
  }

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final gecmis = durum.gecmis(_seciliZon);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tarla.ad} - Geçmiş Loglar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'CSV Olarak Dışa Aktar',
            onPressed: gecmis.isEmpty ? null : () => _disaAktar(context),
          ),
        ],
        bottom: widget.tarla.zonNumaralari.length > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _ZonSekmeleri(
                  zonlar: widget.tarla.zonNumaralari,
                  seciliZon: _seciliZon,
                  onSecim: (zon) => setState(() => _seciliZon = zon),
                ),
              )
            : null,
      ),
      body: gecmis.isEmpty
          ? const Center(child: Text('Bu zon için henüz kayıt yok'))
          : DuyarliIcerik(
              child: ListView.separated(
                itemCount: gecmis.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _GecmisSatiri(okuma: gecmis[index]),
              ),
            ),
    );
  }

  Future<void> _disaAktar(BuildContext context) async {
    final gecmis = context.read<UygulamaDurumu>().gecmis(_seciliZon);
    final csv = DisaAktarmaServisi.csvOlustur(gecmis);
    final dosyaAdi = DisaAktarmaServisi.dosyaAdiUret(
      '${widget.tarla.ad}_zon$_seciliZon',
    );
    final konum = await csvKaydet(dosyaAdi, csv);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV dışa aktarıldı: $konum')),
    );
  }
}

class _ZonSekmeleri extends StatelessWidget {
  final List<int> zonlar;
  final int seciliZon;
  final ValueChanged<int> onSecim;

  const _ZonSekmeleri({
    required this.zonlar,
    required this.seciliZon,
    required this.onSecim,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: zonlar.map((zon) {
          final secili = zon == seciliZon;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ChoiceChip(
              label: Text('Zon $zon'),
              selected: secili,
              onSelected: (_) => onSecim(zon),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GecmisSatiri extends StatelessWidget {
  final SensorOkuma okuma;
  const _GecmisSatiri({required this.okuma});

  @override
  Widget build(BuildContext context) {
    final renk = DurumRenkleri.renkGetir(okuma: okuma, cevrimici: true);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: renk.withValues(alpha: 0.15),
        child: Icon(
          DurumRenkleri.ikonGetir(okuma: okuma, cevrimici: true),
          color: renk,
          size: 20,
        ),
      ),
      title: Text(durumEtiketi(okuma.durum)),
      subtitle: Text(
        'Tür: ${turEtiketi(okuma.tikanmaTuru)}   •   Güven: %${okuma.guven.toStringAsFixed(0)}\n'
        'pH ${okuma.ph.toStringAsFixed(2)}  EC ${okuma.ec.toStringAsFixed(2)}  '
        'ORP ${okuma.orp.toStringAsFixed(0)}  Türb ${okuma.turbidite.toStringAsFixed(1)}  '
        'Debi ${okuma.debi.toStringAsFixed(2)}',
      ),
      isThreeLine: true,
      trailing: Text(
        DateFormat('dd.MM HH:mm:ss').format(okuma.zaman),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
