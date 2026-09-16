// AquaGuard - i18n Pilot Testleri
//
// Ayarlar ekranindaki "Görünüm" bolumu (kisitli kapsam i18n pilotu, bkz.
// lib/l10n/app_tr.arb dosya basi notu) TR locale ile varsayilan Turkce
// metni, EN locale ile Ingilizce metni gosterdigini dogrular -- geri
// kalan Ayarlar bolumleri (MQTT, bildirimler vb.) locale'den BAGIMSIZ
// hala sabit Turkce kalir, bu testlerde DOGRULANMAZ (kapsam disi).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/models/uygulama_dili.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/ayarlar_ekrani.dart';

Widget _sar(UygulamaDurumu durum, Locale locale) {
  return ChangeNotifierProvider.value(
    value: durum,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AyarlarEkrani(),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('TR locale (varsayilan) ile Görünüm bolumu Turkce gosterilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(_sar(durum, const Locale('tr')));
    await tester.pump();

    expect(find.text('Görünüm'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Aksan Rengi'), findsOneWidget);
    expect(find.text('Saha Modu'), findsOneWidget);
    expect(find.text('Dil'), findsOneWidget);
    expect(tester.takeException(), isNull);

    durum.dispose();
  });

  testWidgets('EN locale ile Görünüm bolumu Ingilizce gosterilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(_sar(durum, const Locale('en')));
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Accent Color'), findsOneWidget);
    expect(find.text('Field Mode'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    // Turkce metin GORUNMEMELI.
    expect(find.text('Görünüm'), findsNothing);
    expect(tester.takeException(), isNull);

    durum.dispose();
  });

  testWidgets('dil secici ile Turkce -> Ingilizce gecisi gercekten calisir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final durum = UygulamaDurumu();
    await durum.baslat();

    // NOT: MaterialApp.locale, UygulamaDurumu.uygulamaDili'ni TAKIP EDER
    // (bkz. main.dart) -- bu test bunu dogrudan simule etmek icin
    // Consumer benzeri bir sarmalayici kullanir (gercek main.dart akisi).
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: Consumer<UygulamaDurumu>(
          builder: (context, d, _) => MaterialApp(
            locale: d.uygulamaDili.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AyarlarEkrani(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Görünüm'), findsOneWidget);

    await durum.uygulamaDiliniAyarla(UygulamaDili.ingilizce);
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Görünüm'), findsNothing);
    expect(tester.takeException(), isNull);

    durum.dispose();
  });
}
