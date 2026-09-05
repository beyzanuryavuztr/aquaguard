/// AquaGuard - Uygulama Giris Noktasi
/// ======================================
///
/// Amac:
///   Provider ile UygulamaDurumu'nu (ana state) uygulama agacinin en
///   tepesine yerlestirir, MaterialApp'i tema ile kurar. Ilk (soguk) acilista
///   -- onboarding turu daha once GORULMEDIYSE -- once OnboardingEkrani,
///   sonra GirisEkrani gosterilir (marka + Demo Modu secimi); "Devam Et"
///   oradan Ana Kabuk'a (Genel Bakış / Tedavi Geçmişi / Ayarlar) gecer.
///
///   TEMA MODU (Oncelik 14, 2026-09-05): `themeMode` artik operatorun
///   Ayarlar'dan sectigi tercihe (Koyu/Açık/Sistem, bkz. models/tema_modu.dart)
///   bagli -- bu yuzden MaterialApp bir `Consumer<UygulamaDurumu>` icinde
///   kurulur (UygulamaDurumu.temaModu degisince MaterialApp yeniden cizilir).
///
/// Tarih:  2026-09-01 (Giris Ekrani: 2026-09-05, Onboarding: 2026-09-05, Tema Modu: 2026-09-05)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/tema.dart';
import 'models/tema_modu.dart';
import 'providers/uygulama_durumu.dart';
import 'screens/giris_ekrani.dart';
import 'screens/onboarding_ekrani.dart';
import 'screens/pin_kilit_ekrani.dart';

void main() {
  runApp(const AquaGuardUygulamasi());
}

class AquaGuardUygulamasi extends StatelessWidget {
  const AquaGuardUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UygulamaDurumu()..baslat(),
      child: Consumer<UygulamaDurumu>(
        builder: (context, durum, _) => MaterialApp(
          title: 'AquaGuard',
          debugShowCheckedModeBanner: false,
          theme: AquaGuardTema.acikTema(),
          darkTheme: AquaGuardTema.koyuTema(),
          // Varsayilan Koyu (bkz. TemaModu.koyu) -- "tarla gunesinde ekran
          // okunabilirligi" ve profesyonel bir "kontrol merkezi" hissi icin
          // kullanicinin ilk talebi. Artik operator Ayarlar'dan Açık/Sistem'e
          // de gecebilir (Oncelik 14) -- tek-tema garantisi kaldirildi, ama
          // varsayilan davranis degismedi.
          themeMode: durum.temaModu.flutterModu,
          home: const _BaslangicYonlendirici(),
        ),
      ),
    );
  }
}

/// Ilk (soğuk) açılışta, onboarding turu daha önce görülmediyse ONU
/// (bkz. screens/onboarding_ekrani.dart), görüldüyse doğrudan GirisEkrani'ni
/// gösterir. UygulamaDurumu.baslat() (SharedPreferences'tan asenkron
/// yükleme) bitene kadar kısa bir yükleniyor göstergesi gösterir.
class _BaslangicYonlendirici extends StatelessWidget {
  const _BaslangicYonlendirici();

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    if (!durum.hazir) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!durum.onboardingGoruldu) return const OnboardingEkrani();
    if (durum.pinKilitliSuAn) return const PinKilitEkrani();
    return const GirisEkrani();
  }
}
