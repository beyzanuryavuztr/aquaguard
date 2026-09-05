/// AquaGuard - Marka Logosu (Damla + Kalkan)
/// ==============================================
///
/// Amac:
///   AquaGuard'ın iki temel değerini TEK bir işarette birleştiren özel
///   çizilmiş logo: "Aqua" (su damlası) + "Guard" (koruma/kalkan) --
///   tıkanma teşhis eden ve tedavi eden bir KORUMA sisteminin kimliği.
///   Sabit bir PNG/SVG asset yerine CustomPainter ile çizilir -- boylece
///   her boyutta (splash ekranı, uygulama içi rozetler) keskin kalır ve
///   tema rengine göre otomatik uyarlanır.
///
///   Şekiller kasıtlı olarak SADE bezier eğrileriyle yaklaşıklanır (statik
///   uygulama ikonundaki -- web/icons, android mipmap -- matematiksel
///   teğet-daire hesabı kadar hassas OLMASI GEREKMEZ; bu bir UI elemanı,
///   piksel-mükemmelliği değil canlı/ölçeklenebilir olması önemlidir).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';

import '../config/tema.dart';

class AquaGuardLogosu extends StatelessWidget {
  final double boyut;

  const AquaGuardLogosu({super.key, this.boyut = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boyut,
      height: boyut,
      child: CustomPaint(painter: _LogoRessami()),
    );
  }
}

class _LogoRessami extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final kalkanYolu = _kalkanYoluOlustur(w, h);

    final kalkanDoldur = Paint()
      ..color = AquaGuardTema.vurguRenk.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final kalkanCizgi = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AquaGuardTema.vurguRenk,
          AquaGuardTema.vurguRenk.withValues(alpha: 0.55),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(kalkanYolu, kalkanDoldur);
    canvas.drawPath(kalkanYolu, kalkanCizgi);

    final damlaYolu = _damlaYoluOlustur(w, h);
    final damlaDoldur = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AquaGuardTema.vurguRenk,
          AquaGuardTema.vurguRenk.withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(damlaYolu, damlaDoldur);

    // Camsi/parlak his icin damlanin ust-sol kismina kucuk, yari saydam bir
    // vurgu (highlight) -- duz bir renk yerine hafif "3D" derinlik verir.
    final vurgu = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.40, h * 0.34, w * 0.10, h * 0.14),
      vurgu,
    );
  }

  Path _kalkanYoluOlustur(double w, double h) {
    final path = Path();
    path.moveTo(w * 0.5, h * 0.02);
    path.cubicTo(
      w * 0.5,
      h * 0.06,
      w * 0.84,
      h * 0.08,
      w * 0.84,
      h * 0.17,
    );
    path.lineTo(w * 0.84, h * 0.46);
    path.cubicTo(
      w * 0.84,
      h * 0.72,
      w * 0.68,
      h * 0.90,
      w * 0.5,
      h * 0.98,
    );
    path.cubicTo(
      w * 0.32,
      h * 0.90,
      w * 0.16,
      h * 0.72,
      w * 0.16,
      h * 0.46,
    );
    path.lineTo(w * 0.16, h * 0.17);
    path.cubicTo(
      w * 0.16,
      h * 0.08,
      w * 0.5,
      h * 0.06,
      w * 0.5,
      h * 0.02,
    );
    path.close();
    return path;
  }

  Path _damlaYoluOlustur(double w, double h) {
    final cx = w * 0.5;
    final apexY = h * 0.28;
    final merkezY = h * 0.62;
    final yaricap = w * 0.17;

    final path = Path();
    path.moveTo(cx, apexY);
    path.cubicTo(
      cx - yaricap * 1.15,
      merkezY - yaricap * 0.85,
      cx - yaricap,
      merkezY + yaricap * 0.55,
      cx,
      merkezY + yaricap,
    );
    path.cubicTo(
      cx + yaricap,
      merkezY + yaricap * 0.55,
      cx + yaricap * 1.15,
      merkezY - yaricap * 0.85,
      cx,
      apexY,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _LogoRessami oldDelegate) => false;
}
