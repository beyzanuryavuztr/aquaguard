/// AquaGuard - Aktif Tedavi Ekrani
/// ===================================
///
/// Amac:
///   Bir zonda su an surmekte olan tedaviyi (asit dozlama / klor
///   enjeksiyonu / yuksek basincli yikama) ve zorunlu durulama asamasini
///   ilerleme cubuguyla gosterir.
///
///   ONEMLI: Ilerleme yuzdesi TAHMINIDIR. Cihaz, tedavinin tam olarak
///   ne zaman basladigini MQTT mesajinda GONDERMEZ (sadece o an aktif
///   olan tedavinin ADINI gonderir). Bu yuzden UygulamaDurumu, "tedavi_aktif"
///   alaninin YOK'tan bir tedavi adina ilk gectigi ani kendi tarafinda
///   zaman damgasi olarak kaydeder (bkz. providers/uygulama_durumu.dart)
///   ve ilerleme, firmware/config.h'deki YAPILANDIRILMIS sureye (ornegin
///   asit icin 30 saniye) gore hesaplanir. Cihaz farkli bir surede
///   tamamlarsa (ornegin manuel mudahale), bu ilerleme cubugu hafif
///   sapabilir -- bu bilinen ve kabul edilebilir bir sinirlamadir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/ayarlar_sabitleri.dart';
import '../models/sensor_okuma.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/manuel_mudahale_paneli.dart';

class AktifTedaviEkrani extends StatefulWidget {
  final int zonNumarasi;

  const AktifTedaviEkrani({super.key, required this.zonNumarasi});

  @override
  State<AktifTedaviEkrani> createState() => _AktifTedaviEkraniState();
}

class _AktifTedaviEkraniState extends State<AktifTedaviEkrani> {
  Timer? _saniyeSayaci;

  @override
  void initState() {
    super.initState();
    // Ilerleme cubugunun canli akmasi icin her saniye yeniden ciz.
    _saniyeSayaci = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _saniyeSayaci?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final okuma = durum.sonOkuma(widget.zonNumarasi);

    return Scaffold(
      appBar: AppBar(title: Text('Zon ${widget.zonNumarasi} - Aktif Tedavi')),
      body: okuma == null
          ? const Center(child: Text('Veri bulunamadı'))
          : DuyarliIcerik(
              maksimumGenislik: 560,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: okuma.tedaviAktif != TedaviTuru.yok
                    ? _TedaviIlerlemeGorunumu(
                        zonNumarasi: widget.zonNumarasi,
                        okuma: okuma,
                        baslangic: durum.tedaviBaslangicZamani(
                          widget.zonNumarasi,
                        ),
                      )
                    : okuma.durulamaAktif
                    ? _DurulamaGorunumu(okuma: okuma)
                    : const _AktifTedaviYok(),
              ),
            ),
    );
  }
}

class _TedaviIlerlemeGorunumu extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma okuma;
  final DateTime? baslangic;

  const _TedaviIlerlemeGorunumu({
    required this.zonNumarasi,
    required this.okuma,
    required this.baslangic,
  });

  @override
  Widget build(BuildContext context) {
    final toplamSaniye =
        AyarlarSabitleri.tedaviSuresiSaniye[okuma.tedaviAktif] ?? 30;
    final gecenSaniye = baslangic == null
        ? 0
        : DateTime.now()
              .difference(baslangic!)
              .inSeconds
              .clamp(0, toplamSaniye);
    final ilerleme = toplamSaniye == 0 ? 0.0 : gecenSaniye / toplamSaniye;
    final kalanSaniye = toplamSaniye - gecenSaniye;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.build_circle, size: 64, color: DurumRenkleri.tedaviAktif),
        const SizedBox(height: 16),
        Text(
          tedaviEtiketi(okuma.tedaviAktif),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${turEtiketi(okuma.tikanmaTuru)} tıkanmaya karşı tetiklendi',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ilerleme.clamp(0.0, 1.0),
            minHeight: 14,
            backgroundColor: DurumRenkleri.tedaviAktif.withValues(alpha: 0.15),
            color: DurumRenkleri.tedaviAktif,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          kalanSaniye > 0
              ? 'Tahmini kalan süre: $kalanSaniye sn'
              : 'Tamamlanmak üzere...',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        const _TahminiSureAciklamasi(),
        const SizedBox(height: 20),
        ManuelMudahalePaneli(zonNumarasi: zonNumarasi, okuma: okuma),
      ],
    );
  }
}

class _DurulamaGorunumu extends StatelessWidget {
  final SensorOkuma okuma;
  const _DurulamaGorunumu({required this.okuma});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.water_drop, size: 64, color: Colors.blueGrey),
        const SizedBox(height: 16),
        Text(
          'Zorunlu Durulama Sürüyor',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tedavi tamamlandı. Güvenlik gereği, yeni bir tedavi başlamadan önce '
          'sistem zorunlu durulama süresini bekliyor.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _AktifTedaviYok extends StatelessWidget {
  const _AktifTedaviYok();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: DurumRenkleri.normal),
          SizedBox(height: 16),
          Text(
            'Şu anda aktif bir tedavi yok',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TahminiSureAciklamasi extends StatelessWidget {
  const _TahminiSureAciklamasi();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.black45),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Süre, cihazın yapılandırılmış tedavi süresine göre tahmini olarak hesaplanır.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}
