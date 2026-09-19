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
///   bagli -- bu yuzden MaterialApp bir `Consumer<AyarlarProvider>` icinde
///   kurulur (AyarlarProvider.temaModu degisince MaterialApp yeniden cizilir).
///
///   GLOBAL HATA YAKALAMA (2026-09-18): `main()`, `runZonedGuarded` ile
///   sarilir -- hem Flutter framework hatalarini (`FlutterError.onError`)
///   hem de yakalanmamis async hatalari (`runZonedGuarded`'in onError'u)
///   `HataGunluguServisi`'ne kaydeder. Boylece bir cokme yasandiginda
///   NE OLDUGUNU bilebiliriz (bkz. o servisin dosya basi notu -- ucuncu
///   parti bir servise BILEREK baglanmiyoruz).
///
/// Tarih:  2026-09-01 (Giris Ekrani: 2026-09-05, Onboarding: 2026-09-05, Tema Modu: 2026-09-05,
///         Global hata yakalama: 2026-09-18)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/tema.dart';
import 'l10n/app_localizations.dart';
import 'models/tema_modu.dart';
import 'models/uygulama_dili.dart';
import 'models/yazi_boyutu.dart';
import 'providers/ayarlar_provider.dart';
import 'providers/cihaz_iletisim_provider.dart';
import 'providers/guvenlik_provider.dart';
import 'providers/uygulama_durumu.dart';
import 'screens/giris_ekrani.dart';
import 'screens/onboarding_ekrani.dart';
import 'screens/pin_kilit_ekrani.dart';
import 'services/hata_gunlugu_servisi.dart';
import 'widgets/oturum_zaman_asimi.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await HataGunluguServisi.baslat();

      final onceki = FlutterError.onError;
      FlutterError.onError = (details) {
        HataGunluguServisi.logla(
          details.exception,
          details.stack,
          baglam: 'FlutterError',
        );
        // Onceki handler'i (varsa, orn. Flutter'in kendi konsol
        // ciktisi/DevTools entegrasyonu) DA cagir -- gelistirme
        // deneyimini bozmayalim, sadece EKLE.
        onceki?.call(details);
      };

      runApp(const AquaGuardUygulamasi());
    },
    (hata, yigin) {
      HataGunluguServisi.logla(hata, yigin, baglam: 'Yakalanmamis');
    },
  );
}

class AquaGuardUygulamasi extends StatelessWidget {
  const AquaGuardUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UygulamaDurumu()..baslat(),
      // Facade'i DINLEMEZ (read) -- aksi halde her sensor okumasinda tum
      // MaterialApp yeniden kurulurdu. Sadece tema/dil/yazi boyutu icin
      // AyarlarProvider dinlenir (asagidaki Consumer).
      child: Builder(
        builder: (context) {
          final durum = context.read<UygulamaDurumu>();
          return MultiProvider(
            // Faz 14 (performans): alt provider'lar burada AYRICA agaca
            // eklenir -- boylece dar bir alani ilgilendiren ekranlar
            // (bkz. PinKilitEkrani, BildirimGecmisiEkrani, TarlaNotlariEkrani)
            // TUM facade'i degil, dogrudan ilgili TEK provider'i izleyebilir
            // (bkz. UygulamaDurumu'nun "ALT PROVIDER ERISIMI" bolumu).
            // `.value` kullanilir -- bu provider'lar UygulamaDurumu
            // TARAFINDAN sahiplenilir/dispose edilir, burada YENIDEN
            // olusturulmaz.
            providers: [
              ChangeNotifierProvider.value(value: durum.ayarlarProvider),
              ChangeNotifierProvider.value(value: durum.tarlaProvider),
              ChangeNotifierProvider.value(value: durum.guvenlikProvider),
              ChangeNotifierProvider.value(value: durum.bakimProvider),
              ChangeNotifierProvider.value(value: durum.aktiviteProvider),
              ChangeNotifierProvider.value(value: durum.cihazProvider),
            ],
            child: Consumer<AyarlarProvider>(
              builder: (context, ayarlar, _) => MaterialApp(
                title: 'AquaGuard',
                debugShowCheckedModeBanner: false,
                theme: AquaGuardTema.acikTema(
                  aksan: ayarlar.aksanRengi,
                  sahaModu: ayarlar.sahaModuAktif,
                ),
                darkTheme: AquaGuardTema.koyuTema(
                  aksan: ayarlar.aksanRengi,
                  sahaModu: ayarlar.sahaModuAktif,
                ),
                // Varsayilan Koyu (bkz. TemaModu.koyu) -- "tarla gunesinde ekran
                // okunabilirligi" ve profesyonel bir "kontrol merkezi" hissi icin
                // kullanicinin ilk talebi. Artik operator Ayarlar'dan Açık/Sistem'e
                // de gecebilir (Oncelik 14) -- tek-tema garantisi kaldirildi, ama
                // varsayilan davranis degismedi.
                themeMode: ayarlar.temaModu.flutterModu,
                // i18n (kisitli kapsam -- bkz. lib/l10n/app_tr.arb dosya basi
                // notu): SADECE Ayarlar'daki Görünüm bolumu bu locale'e tepki
                // verir, uygulamanin geri kalani hala sabit Turkce metin
                // kullanir. `locale` acikca UygulamaDurumu.uygulamaDili'nden
                // gelir (sistem dilini OTOMATIK algilamaz) -- boylece Turkce
                // bir cihazda operator YANLISLIKLA Ingilizce gormez, secim
                // her zaman bilincli bir Ayarlar eylemidir.
                locale: ayarlar.uygulamaDili.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                // Yazi boyutu (erisilebilirlik, bkz. models/yazi_boyutu.dart):
                // `builder` TUM navigator/route agacini (dialoglar dahil) sarar --
                // tek noktadan uygulanir, her ekranda ayri ayri font boyutu
                // yonetmeye gerek kalmaz. Cihazin KENDI erisilebilirlik yazi
                // olcegini (isletim sistemi ayari) DEGIL, operatorun Ayarlar'dan
                // sectigi orani kullanir -- ikisini CARPMAK (ör. sistem zaten
                // %130 + operator %130 = %169) sahada asiri buyumus, kullanilamaz
                // bir arayuze yol acardi.
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(ayarlar.yaziBoyutu.oran),
                  ),
                  child: OturumZamanAsimi(child: child!),
                ),
                home: const _BaslangicYonlendirici(),
              ),
            ),
          );
        },
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
    final hazir = context.select<CihazIletisimProvider, bool>((c) => c.hazir);
    if (!hazir) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final onboardingGoruldu = context.select<AyarlarProvider, bool>(
      (a) => a.onboardingGoruldu,
    );
    if (!onboardingGoruldu) return const OnboardingEkrani();
    final pinKilitli = context.select<GuvenlikProvider, bool>(
      (g) => g.pinKilitliSuAn,
    );
    if (pinKilitli) return const PinKilitEkrani();
    return const GirisEkrani();
  }
}
