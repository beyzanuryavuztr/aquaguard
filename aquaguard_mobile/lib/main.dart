/// AquaGuard - Uygulama Giris Noktasi
/// ======================================
///
/// Amac:
///   Provider ile UygulamaDurumu'nu (ana state) uygulama agacinin en
///   tepesine yerlestirir, MaterialApp'i tema ile kurar. Ilk (soguk) acilista
///   GirisEkrani gosterilir (marka + Demo Modu secimi); "Devam Et" oradan
///   Ana Kabuk'a (Genel Bakış / Tedavi Geçmişi / Ayarlar) gecer.
///
/// Tarih:  2026-09-01 (Giris Ekrani: 2026-09-05)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/tema.dart';
import 'providers/uygulama_durumu.dart';
import 'screens/giris_ekrani.dart';

void main() {
  runApp(const AquaGuardUygulamasi());
}

class AquaGuardUygulamasi extends StatelessWidget {
  const AquaGuardUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UygulamaDurumu()..baslat(),
      child: MaterialApp(
        title: 'AquaGuard',
        debugShowCheckedModeBanner: false,
        theme: AquaGuardTema.koyuTema(),
        // BILINCLI KARAR (2026-09-03 yenilemesi): uygulama artik SADECE koyu
        // tema kullanir -- "tarla gunesinde ekran okunabilirligi" ve
        // profesyonel bir "kontrol merkezi" hissi icin kullanicinin acik
        // talebi. Tek tema = tek garanti edilen gorunum (onceki turdeki
        // "ThemeMode.system riskli, tek temayi garanti et" ilkesinin aynisi,
        // simdi koyu yonde). Butun ekranlardaki sabit Colors.black* /
        // Colors.white kullanimlari bu gecisle birlikte Theme.of(context)
        // renklerine tasindi (bkz. proje notlari).
        themeMode: ThemeMode.dark,
        home: const GirisEkrani(),
      ),
    );
  }
}
