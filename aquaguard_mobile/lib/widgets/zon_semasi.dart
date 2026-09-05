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
///   PIYASA-HAZIRLIK TURU ONCELIK 11 (2026-09-05): iki gorsel eklendi --
///   (1) tespit edilmis (TESPIT_EDILDI) bir tikanmasi olan dugumler artik
///   yavas bir "nabiz" (pulsating) animasyonuyla dikkat cekiyor -- operatorun
///   ekrana bir bakista "hangi zon acil" sorusunu cevaplamasi icin (sadece
///   tespitEdildi durumunda, digerlerinde -- belirsiz/tedavide -- sabit
///   kaliyor, cunku "acil mudahale gerekiyor" mesaji SADECE bu duruma ait).
///   (2) SDI ana hattinin ARKASINDA, "toprak alti" temasini pekistiren
///   soluk bir toprak katmani illustrasyonu (yuzey + iki koyulasan toprak
///   bandi) -- salt dekoratif, dugum okunabilirligini etkilemeyecek kadar
///   dusuk opaklikta.
///
/// Tarih:  2026-09-04 (gorsel yenileme: 2026-09-05)
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';
import 'durum_renkleri.dart';

class ZonSemasi extends StatelessWidget {
  final List<int> zonlar;
  final SensorOkuma? Function(int zon) okumaGetir;
  final bool Function(int zon) cevrimiciMi;
  final ValueChanged<int> onZonSecildi;

  /// Zonun gosterilecek adini doner (opsiyonel takma ad -- bkz.
  /// UygulamaDurumu.zonAdiGetir). Verilmezse "Zon N" varsayilanina duser.
  final String Function(int zon)? adGetir;

  static const double dugumGenislik = 108;
  static const double hatUstBosluk = 40;

  const ZonSemasi({
    super.key,
    required this.zonlar,
    required this.okumaGetir,
    required this.cevrimiciMi,
    required this.onZonSecildi,
    this.adGetir,
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
                painter: _ToprakKatmaniRessami(dropBitisY: hatUstBosluk),
              ),
            ),
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
                        zonAdi: adGetir?.call(zon) ?? 'Zon $zon',
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

class _ZonDugumu extends StatefulWidget {
  final int zonNumarasi;
  final String zonAdi;
  final SensorOkuma? okuma;
  final bool cevrimici;
  final VoidCallback onTap;

  const _ZonDugumu({
    required this.zonNumarasi,
    required this.zonAdi,
    required this.okuma,
    required this.cevrimici,
    required this.onTap,
  });

  @override
  State<_ZonDugumu> createState() => _ZonDugumuState();
}

class _ZonDugumuState extends State<_ZonDugumu> with SingleTickerProviderStateMixin {
  late final AnimationController _nabizDenetci;

  @override
  void initState() {
    super.initState();
    _nabizDenetci = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nabizDenetci.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renk = DurumRenkleri.renkGetir(
      okuma: widget.okuma,
      cevrimici: widget.cevrimici,
    );
    final ikon = DurumRenkleri.ikonGetir(
      okuma: widget.okuma,
      cevrimici: widget.cevrimici,
    );
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final gosterilecekOkuma = widget.cevrimici ? widget.okuma : null;
    // Sadece GERCEKTEN tespit edilmis bir tikanma (acil mudahale gereken
    // tek durum) nabiz atar -- belirsiz/tedavide/normal sabit kalir, aksi
    // halde "nabiz" sinyalinin ayirt ediciligi kaybolur.
    final oncelik = DurumRenkleri.onceligiBelirle(
      okuma: widget.okuma,
      cevrimici: widget.cevrimici,
    );
    final nabizAtsinMi = oncelik == ZonOnceligi.tespitEdildi;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _nabizDenetci,
              builder: (context, child) {
                final nabiz = nabizAtsinMi ? _nabizDenetci.value : 0.0;
                return Container(
                  width: 44 + nabiz * 10,
                  height: 44 + nabiz * 10,
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: 0.15 + nabiz * 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: renk, width: 2),
                    boxShadow: nabizAtsinMi
                        ? [
                            BoxShadow(
                              color: renk.withValues(alpha: 0.35 * nabiz),
                              blurRadius: 10 * nabiz,
                              spreadRadius: 2 * nabiz,
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                );
              },
              child: Icon(ikon, color: renk, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              widget.zonAdi,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

/// Sematik diyagramin ARKASINDA, "toprak alti" temasini pekistiren --
/// salt dekoratif, dugum/metin okunabilirligini ETKILEMEYECEK kadar dusuk
/// opaklikta -- 3 yatay bant: [dropBitisY] UZERI acik "yuzey" bandi, altinda
/// giderek koyulasan iki toprak bandi (SDI lateralleri gercekte toprak
/// altina gomulu oldugu icin, dugumler görsel olarak bu bantların icinde
/// dururlar).
class _ToprakKatmaniRessami extends CustomPainter {
  final double dropBitisY;

  const _ToprakKatmaniRessami({required this.dropBitisY});

  @override
  void paint(Canvas canvas, Size size) {
    final yuzeyBandi = Paint()..color = const Color(0xFF3E4A3A).withValues(alpha: 0.10);
    final toprakBandi1 = Paint()..color = const Color(0xFF5D4A36).withValues(alpha: 0.14);
    final toprakBandi2 = Paint()..color = const Color(0xFF4A3826).withValues(alpha: 0.18);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, dropBitisY),
      yuzeyBandi,
    );
    final kalanYukseklik = size.height - dropBitisY;
    final bant1Yukseklik = kalanYukseklik * 0.45;
    canvas.drawRect(
      Rect.fromLTWH(0, dropBitisY, size.width, bant1Yukseklik),
      toprakBandi1,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        dropBitisY + bant1Yukseklik,
        size.width,
        kalanYukseklik - bant1Yukseklik,
      ),
      toprakBandi2,
    );
  }

  @override
  bool shouldRepaint(covariant _ToprakKatmaniRessami oldDelegate) =>
      oldDelegate.dropBitisY != dropBitisY;
}
