/// AquaGuard - Tikanma Turu Ikon/Renk Tanimlari
/// =================================================
///
/// Amac:
///   Her tikanma turunu (kimyasal/biyolojik/fiziksel) HER YERDE (Zon Detay,
///   Aciklanabilirlik Paneli, ileride Tedavi Gecmisi) AYNI ikon+renkle
///   temsil eden tek kaynak.
///
///   BILEREK DurumRenkleri'NDEN AYRI: DurumRenkleri "şu an ne DURUMDA"
///   sorusuna (normal/belirsiz/tespit/tedavide) cevap verir; bu dosya ise
///   "ne TÜR bir tıkanma" sorusuna cevap verir -- ikisi farklı boyutlar,
///   karıştırılırsa (örn. biyolojik=yeşil burada, normal=yeşil orada)
///   "bu yeşil hangi anlamda?" belirsizliği doğar. Bu yuzden burada
///   KASITLI olarak farklı ton yeşil/turuncu/kahverengi kullanılır.
///
/// Tarih:  2026-09-04
library;

import 'package:flutter/material.dart';

import '../models/sensor_okuma.dart';

class TikanmaTuruBilgisi {
  final IconData ikon;
  final Color renk;
  const TikanmaTuruBilgisi(this.ikon, this.renk);
}

TikanmaTuruBilgisi tikanmaTuruBilgisiGetir(TikanmaTuru tur) {
  switch (tur) {
    case TikanmaTuru.kimyasal:
      return const TikanmaTuruBilgisi(
        Icons.diamond,
        Color(0xFFFF8F00), // turuncu kristal
      );
    case TikanmaTuru.biyolojik:
      return const TikanmaTuruBilgisi(
        Icons.coronavirus,
        Color(0xFF2E7D32), // yeşil biyofilm
      );
    case TikanmaTuru.fiziksel:
      return const TikanmaTuruBilgisi(
        Icons.grain,
        Color(0xFF6D4C41), // kahverengi sediman
      );
    case TikanmaTuru.yok:
      return const TikanmaTuruBilgisi(
        Icons.check_circle_outline,
        Color(0xFF6B7A8C),
      );
  }
}

class TikanmaTuruIkonu extends StatelessWidget {
  final TikanmaTuru tur;
  final double boyut;

  const TikanmaTuruIkonu({super.key, required this.tur, this.boyut = 20});

  @override
  Widget build(BuildContext context) {
    final bilgi = tikanmaTuruBilgisiGetir(tur);
    return Icon(bilgi.ikon, color: bilgi.renk, size: boyut);
  }
}
