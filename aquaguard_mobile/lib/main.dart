/// AquaGuard - Uygulama Giris Noktasi
/// ======================================
///
/// Amac:
///   Provider ile UygulamaDurumu'nu (ana state) uygulama agacinin en
///   tepesine yerlestirir, MaterialApp'i tema ile kurar ve alt navigasyonlu
///   Ana Kabuk'u (Genel Bakış / Tarlalar / İstatistikler / Ayarlar) acar.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/tema.dart';
import 'providers/uygulama_durumu.dart';
import 'screens/ana_kabuk.dart';

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
        theme: AquaGuardTema.acikTema(),
        darkTheme: AquaGuardTema.koyuTema(),
        // BILINCLI KARAR: koyu tema ThemeData olarak tanimli (ileride
        // etkinlestirilebilir) ama SISTEM ayarina birakilmiyor. Uygulama
        // genelinde bircok yerde metin rengi Theme.of(context).colorScheme
        // yerine sabit Colors.black54/black87 kullaniyor (bkz. proje notlari)
        // -- bu, koyu temada okunmaz/dusuk kontrastli metne yol acar. Bir
        // yaris jurisi karsisinda YARIM kalmis bir koyu tema riske atmaktansa,
        // iki turdur cilalanan tek (acik) temayi HER ZAMAN garanti etmek
        // tercih edildi.
        themeMode: ThemeMode.light,
        home: const AnaKabuk(),
      ),
    );
  }
}
