/// AquaGuard - Aksan Rengi (Marka Vurgu Rengi Secenekleri)
/// ============================================================
///
/// Amac:
///   `config/tema.dart`'taki turkuvaz marka vurgusu (`vurguRenk`) TEK
///   sabit degerdi -- operator alternatif bir vurgu rengi secemiyordu.
///   Bu dosya, koyu/acik tema ayrimiyla AYNI desende (bkz. tema.dart dosya
///   basi notu) ikinci bir secenek ekler: 'Toprak' (tarim temasina uygun
///   kahve/amber), marka renginin (turkuvaz) YERINE degil YANINA.
///
///   Durum renkleri (basari/uyari/tehlike, DurumRenkleri sinifi) BU
///   secimden ETKILENMEZ -- sadece ColorScheme.primary (buton/secili
///   sekme/link gibi ETKILESIMLI ogeler) degisir.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/material.dart';

enum AksanRengi { teal, toprak }

extension AksanRengiX on AksanRengi {
  String get etiket => switch (this) {
    AksanRengi.teal => 'Turkuvaz',
    AksanRengi.toprak => 'Toprak',
  };
}

/// Bir aksan renginin koyu/acik temada ihtiyac duydugu TUM turev
/// renkleri (ColorScheme.primary ailesi) tasir -- tema.dart'taki
/// ColorScheme kaydi bunlari dogrudan kullanir.
class AksanPaleti {
  final Color renk;
  final Color onRenkKoyu;
  final Color renkContainerKoyu;
  final Color onRenkContainerKoyu;
  final Color inversePrimaryKoyu;
  final Color onRenkAcik;
  final Color renkContainerAcik;
  final Color onRenkContainerAcik;
  final Color inversePrimaryAcik;

  const AksanPaleti({
    required this.renk,
    required this.onRenkKoyu,
    required this.renkContainerKoyu,
    required this.onRenkContainerKoyu,
    required this.inversePrimaryKoyu,
    required this.onRenkAcik,
    required this.renkContainerAcik,
    required this.onRenkContainerAcik,
    required this.inversePrimaryAcik,
  });
}

const Map<AksanRengi, AksanPaleti> aksanPaletleri = {
  // Mevcut marka rengi -- tema.dart'ta onceden hardcoded olan degerlerin
  // BIREBIR AYNISI, sadece bu haritaya tasindi (varsayilan davranis
  // degismez).
  AksanRengi.teal: AksanPaleti(
    renk: Color(0xFF00BFA6),
    onRenkKoyu: Color(0xFF00251F),
    renkContainerKoyu: Color(0xFF00473C),
    onRenkContainerKoyu: Color(0xFF7BFFE9),
    inversePrimaryKoyu: Color(0xFF00695C),
    onRenkAcik: Colors.white,
    renkContainerAcik: Color(0xFFB2F5EA),
    onRenkContainerAcik: Color(0xFF00443B),
    inversePrimaryAcik: Color(0xFF7BFFE9),
  ),
  AksanRengi.toprak: AksanPaleti(
    renk: Color(0xFFB5651D),
    onRenkKoyu: Color(0xFFFFF3E0),
    renkContainerKoyu: Color(0xFF5C3B14),
    onRenkContainerKoyu: Color(0xFFFFD9A6),
    inversePrimaryKoyu: Color(0xFF8A5321),
    onRenkAcik: Colors.white,
    renkContainerAcik: Color(0xFFFFDBB0),
    onRenkContainerAcik: Color(0xFF5C3B14),
    inversePrimaryAcik: Color(0xFFFFD9A6),
  ),
};
