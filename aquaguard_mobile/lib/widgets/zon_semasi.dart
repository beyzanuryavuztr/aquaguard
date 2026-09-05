/// AquaGuard - Zon Semasi (Sematik SDI Hat Diyagrami)
/// =======================================================
///
/// Amac:
///   Genel Bakis ekraninin merkezi gorseli. Zonlari duz bir kart izgarasi
///   olarak DEGIL, gercek bir toprak alti damla sulama (SDI) ana hattina
///   bagli lateral hatlar gibi SEMATIK bir borulama diyagrami olarak
///   gosterir -- "genel tarim uygulamasi" degil, teknik bir "tikanma
///   yonetim merkezi" hissi vermek icin (kullanicinin acik talebi).
///
///   CustomPaint SADECE hatlari (ana boru + her zona inen dal) cizer;
///   dugumler (nodes) GERCEK Flutter widget'laridir (InkWell ile
///   dokunulabilir, metin/ikon icerir) -- boylece hem cizim performansi
///   hem de erisilebilirlik/dokunma hedefi basitlesir, hattin GEOMETRISI
///   ile dugum GENISLIGI ayni sabitten (dugumGenislik) turetilir ki
///   cizgiler her zaman dugumlerin tam ortasindan gecsin.
///
///   Her dugumde 2 mini sensor degeri (debi, delta basinc) gosterilir --
///   TUM 6 sensor DEGIL: geri kalan 4'u (pH, EC, ORP, turbidite) Zon
///   Detay ekranindaki tam sensor kartlarinda (bkz. widgets/sensor_karti.dart,
///   Asama 3) gosterilir. Bu bilinckli bir bilgi hiyerarsisi karari --
///   dashboard'da "hizli goz atma", detay ekraninda "tam analiz".
///
/// Tarih:  2026-09-04
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';
import 'durum_renkleri.dart';

class ZonSemasi extends StatelessWidget {
  final List<int> zonlar;
  final SensorOkuma? Function(int zon) okumaGetir;
  final bool Function(int zon) cevrimiciMi;
  final ValueChanged<int> onZonSecildi;

  static const double dugumGenislik = 108;
  static const double hatUstBosluk = 40;

  const ZonSemasi({
    super.key,
    required this.zonlar,
    required this.okumaGetir,
    required this.cevrimiciMi,
    required this.onZonSecildi,
  });

  @override
  Widget build(BuildContext context) {
    if (zonlar.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Henüz izlenen zon yok.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final toplamGenislik = zonlar.length * dugumGenislik;
    final hatRengi = Theme.of(context).colorScheme.outline;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: toplamGenislik,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AnaHatRessami(
                  dugumSayisi: zonlar.length,
                  dugumGenislik: dugumGenislik,
                  hatY: hatUstBosluk * 0.45,
                  dropBitisY: hatUstBosluk,
                  renk: hatRengi,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: hatUstBosluk),
              child: Row(
                children: [
                  for (final zon in zonlar)
                    SizedBox(
                      width: dugumGenislik,
                      child: _ZonDugumu(
                        zonNumarasi: zon,
                        okuma: okumaGetir(zon),
                        cevrimici: cevrimiciMi(zon),
                        onTap: () => onZonSecildi(zon),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnaHatRessami extends CustomPainter {
  final int dugumSayisi;
  final double dugumGenislik;
  final double hatY;
  final double dropBitisY;
  final Color renk;

  const _AnaHatRessami({
    required this.dugumSayisi,
    required this.dugumGenislik,
    required this.hatY,
    required this.dropBitisY,
    required this.renk,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cizgiKalemi = Paint()
      ..color = renk
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final noktaKalemi = Paint()
      ..color = renk
      ..style = PaintingStyle.fill;

    final ilkX = dugumGenislik / 2;
    final sonX = size.width - dugumGenislik / 2;

    // Ana hat (SDI ana besleme borusu)
    canvas.drawLine(Offset(ilkX, hatY), Offset(sonX, hatY), cizgiKalemi);

    for (var i = 0; i < dugumSayisi; i++) {
      final cx = dugumGenislik * i + dugumGenislik / 2;
      // Lateral (dal) hat -- ana borudan zon dugumune iner.
      canvas.drawLine(Offset(cx, hatY), Offset(cx, dropBitisY), cizgiKalemi);
      canvas.drawCircle(Offset(cx, hatY), 3, noktaKalemi);
    }
  }

  @override
  bool shouldRepaint(covariant _AnaHatRessami oldDelegate) =>
      oldDelegate.dugumSayisi != dugumSayisi || oldDelegate.renk != renk;
}

class _ZonDugumu extends StatelessWidget {
  final int zonNumarasi;
  final SensorOkuma? okuma;
  final bool cevrimici;
  final VoidCallback onTap;

  const _ZonDugumu({
    required this.zonNumarasi,
    required this.okuma,
    required this.cevrimici,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = DurumRenkleri.renkGetir(okuma: okuma, cevrimici: cevrimici);
    final ikon = DurumRenkleri.ikonGetir(okuma: okuma, cevrimici: cevrimici);
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final gosterilecekOkuma = cevrimici ? okuma : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: renk, width: 2),
              ),
              child: Icon(ikon, color: renk, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Zon $zonNumarasi',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            if (gosterilecekOkuma != null) ...[
              _MiniDeger(
                etiket: 'Debi',
                deger: '${gosterilecekOkuma.debi.toStringAsFixed(1)} LPM',
                renk: onSurfaceVariant,
              ),
              _MiniDeger(
                etiket: 'ΔP',
                deger:
                    '${gosterilecekOkuma.deltaBasinc.toStringAsFixed(2)} bar',
                renk: onSurfaceVariant,
              ),
            ] else
              Text('—', style: TextStyle(color: onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MiniDeger extends StatelessWidget {
  final String etiket;
  final String deger;
  final Color renk;

  const _MiniDeger({
    required this.etiket,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$etiket: $deger',
      style: TextStyle(fontSize: 10, color: renk),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
