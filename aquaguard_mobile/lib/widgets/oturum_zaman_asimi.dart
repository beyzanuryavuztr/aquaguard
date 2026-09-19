/// AquaGuard - Oturum Zaman Asimi Sarmalayicisi (D3)
/// ======================================================
///
/// Amac:
///   Uygulama arka plana alinip uzun sure sonra on plana donerse (bkz.
///   GuvenlikProvider.varsayilanZamanAsimi) PIN ekranini mevcut ekranin
///   USTUNE bindirir -- kullanici hangi ekranda olursa olsun, telefon
///   masada/cebinde acik unutulduysa yetkisiz biri sistemi (tedavi
///   baslatma/acil durdurma dahil) kullanamaz.
///
///   Sadece PIN korumasi ACIKKEN etkilidir. Soguk acilis kilidi zaten
///   baslangic yonlendiricisi tarafindan gosterilir; bu sarmalayici
///   yalnizca ZAMAN ASIMI kaynakli yeniden kilitlemeyi ustlenir.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/guvenlik_provider.dart';
import '../screens/pin_kilit_ekrani.dart';

class OturumZamanAsimi extends StatefulWidget {
  final Widget child;
  const OturumZamanAsimi({super.key, required this.child});

  @override
  State<OturumZamanAsimi> createState() => _OturumZamanAsimiState();
}

class _OturumZamanAsimiState extends State<OturumZamanAsimi>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final guvenlik = context.read<GuvenlikProvider>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        guvenlik.arkaplanaAlindi();
      case AppLifecycleState.resumed:
        guvenlik.planaDonuldu();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kilitli = context.select<GuvenlikProvider, bool>(
      (g) => g.zamanAsimiylaKilitlendi,
    );
    return Stack(
      children: [
        widget.child,
        if (kilitli) const Positioned.fill(child: PinKilitEkrani()),
      ],
    );
  }
}
