/// AquaGuard - PIN Kilit Ekrani
/// ===================================
///
/// Amac:
///   PIN korumasi Ayarlar'dan ACILMISSA, her SOGUK acilista Ana Kabuk'a
///   gecmeden once bu ekran gosterilir (bkz. main.dart yonlendiricisi).
///   4 haneli sayisal giris + (destekleniyorsa) biyometrik kisayolu sunar.
///   3 yanlis denemeden sonra 30 saniyelik bir giris kilidi baslar (bkz.
///   UygulamaDurumu.pinGirisiKilitliMi) -- kilit SADECE bu oturum icin
///   bellekte tutulur, kalici degildir (bkz. o alanin dokumantasyonu).
///
/// Tarih:  2026-09-05
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../providers/uygulama_durumu.dart';
import '../services/pin_servisi.dart';
import '../widgets/aquaguard_logosu.dart';

class PinKilitEkrani extends StatefulWidget {
  const PinKilitEkrani({super.key});

  @override
  State<PinKilitEkrani> createState() => _PinKilitEkraniState();
}

class _PinKilitEkraniState extends State<PinKilitEkrani> {
  String _girilenPin = '';
  String? _hataMetni;
  bool _biyometrikDestekli = false;
  Timer? _kilitSayaci;

  @override
  void initState() {
    super.initState();
    PinServisi.biyometrikDesteklidMi().then((destekli) {
      if (!mounted) return;
      setState(() => _biyometrikDestekli = destekli);
      if (destekli) _biyometrikDeneyin();
    });
    _kilitSayaci = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _kilitSayaci?.cancel();
    super.dispose();
  }

  Future<void> _biyometrikDeneyin() async {
    final basarili = await PinServisi.biyometrikDogrula();
    if (!mounted || !basarili) return;
    context.read<UygulamaDurumu>().pinKilidiniBiyometrikIleAc();
  }

  Future<void> _hanEkle(String hane) async {
    final durum = context.read<UygulamaDurumu>();
    if (durum.pinGirisiKilitliMi || _girilenPin.length >= 4) return;
    setState(() {
      _girilenPin += hane;
      _hataMetni = null;
    });
    if (_girilenPin.length == 4) {
      final dogruMu = await durum.pinDenemesiYap(_girilenPin);
      if (!mounted) return;
      if (!dogruMu) {
        setState(() {
          _hataMetni = durum.pinGirisiKilitliMi
              ? 'Çok fazla yanlış deneme -- 30 saniye bekleyin'
              : 'Yanlış PIN, tekrar deneyin';
          _girilenPin = '';
        });
      }
    }
  }

  void _haneSil() {
    if (_girilenPin.isEmpty) return;
    setState(() => _girilenPin = _girilenPin.substring(0, _girilenPin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final kilitli = durum.pinGirisiKilitliMi;
    final kalanSaniye = durum.pinKilidiKalanSure?.inSeconds ?? 0;

    return Scaffold(
      backgroundColor: AquaGuardTema.arkaPlanRenk,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AquaGuardLogosu(boyut: 64),
                const SizedBox(height: 16),
                // SABIT acik renkler: bu ekranin arka plani her temada AYNI
                // koyu renk (arkaPlanRenk, tema secimine gore degismez) --
                // Theme.of(context) acik temada KOYU metin dondurur, bu da
                // arka planin uzerinde gorunmez olurdu.
                const Text(
                  'Kilit Açık Değil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE6ECF1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kilitli
                      ? 'Çok fazla yanlış deneme — $kalanSaniye sn sonra tekrar deneyin'
                      : 'Devam etmek için PIN girin',
                  style: TextStyle(
                    color: kilitli
                        ? AquaGuardTema.tehlikeRenk
                        : const Color(0xFF9AACBC),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _girilenPin.length
                              ? AquaGuardTema.vurguRenk
                              : Colors.transparent,
                          border: Border.all(
                            color: AquaGuardTema.vurguRenk,
                            width: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 20,
                  child: _hataMetni == null
                      ? null
                      : Text(
                          _hataMetni!,
                          style: const TextStyle(
                            color: AquaGuardTema.tehlikeRenk,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                _NumaraTusTakimi(
                  devreDisi: kilitli,
                  onHane: _hanEkle,
                  onSil: _haneSil,
                ),
                if (_biyometrikDestekli && !kilitli) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _biyometrikDeneyin,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Biyometrik ile Aç'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumaraTusTakimi extends StatelessWidget {
  final bool devreDisi;
  final ValueChanged<String> onHane;
  final VoidCallback onSil;

  const _NumaraTusTakimi({
    required this.devreDisi,
    required this.onHane,
    required this.onSil,
  });

  @override
  Widget build(BuildContext context) {
    const satirlar = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final satir in satirlar)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final tus in satir)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TusButonu(
                      etiket: tus,
                      devreDisi: devreDisi,
                      onTap: tus.isEmpty
                          ? null
                          : tus == '⌫'
                          ? onSil
                          : () => onHane(tus),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TusButonu extends StatelessWidget {
  final String etiket;
  final bool devreDisi;
  final VoidCallback? onTap;

  const _TusButonu({
    required this.etiket,
    required this.devreDisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (etiket.isEmpty) return const SizedBox(width: 64, height: 64);
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: devreDisi ? null : onTap,
          child: Center(
            child: Text(
              etiket,
              // SABIT acik renkler -- bkz. yukaridaki "Kilit Açık Değil"
              // basligindaki ayni not (ekran arka plani tema secimine
              // gore degismez).
              style: TextStyle(
                fontSize: 22,
                color: devreDisi
                    ? const Color(0xFF9AACBC)
                    : const Color(0xFFE6ECF1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
