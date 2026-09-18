// AquaGuard - GirisEkrani Widget Testleri (Asama 6)
//
// Hazir olmadan once yukleniyor gostergesi gosterdigini, hazir olunca
// marka + Demo Modu karti + (varsa) ciftlik ozeti + "Devam Et" butonunu
// tasma/istisna olmadan cizdigini ve "Devam Et"e basinca AnaKabuk'a
// (Genel Bakış sekmesine) gecistigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/giris_ekrani.dart';

// "Devam Et" AnaKabuk'a gecer -- AnaKabuk'un IndexedStack'i TUM sekmeleri
// (Ayarlar dahil) HEMEN insa eder, Ayarlar'in Görünüm bolumu ise
// AppLocalizations kullanir (i18n pilotu) -- delegate'ler olmadan cokerdi.
Widget _uygulamaSarici(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hazir olmadan once yukleniyor gostergesi gosterir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: _uygulamaSarici(const GirisEkrani()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('AquaGuard'), findsNothing);

    durum.dispose();
  });

  testWidgets(
    'hazir olunca marka + Demo Modu karti + ciftlik ozeti + Devam Et gosterir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: durum,
          child: _uygulamaSarici(const GirisEkrani()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AquaGuard'), findsOneWidget);
      expect(find.text('SDI Tıkanma Yönetim Merkezi'), findsOneWidget);
      expect(find.text('Demo Modu'), findsOneWidget);
      expect(find.text('1 çiftlik, 4 zon izleniyor'), findsOneWidget);
      // Yarışma/takım markalaması BİLEREK yok (kullanıcının kesin talebi).
      expect(find.text('Arge-T HydroLab • TEKNOFEST 2026'), findsNothing);
      expect(find.text('v0.9.0-beta.1'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('"Devam Et"e basinca AnaKabuk\'a (Genel Bakış) gecer', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    // AnaKabuk'un varsayilan sekmesi GenelBakisEkrani -- facade yerine
    // dogrudan 4 alt provider'i izliyor (bkz. o dosyanin dosya basi notu),
    // test agacinda da saglanmasi gerekir.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
          ChangeNotifierProvider.value(value: durum.tarlaProvider),
          ChangeNotifierProvider.value(value: durum.bakimProvider),
          ChangeNotifierProvider.value(value: durum.aktiviteProvider),
          ChangeNotifierProvider.value(value: durum.ayarlarProvider),
        ],
        child: _uygulamaSarici(const GirisEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Devam Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et'));
    // pumpAndSettle DEGIL: AnaKabuk -> Genel Bakış -> ZonSemasi'ndeki zon
    // dugumleri artik surekli tekrarlanan (nabiz) bir AnimationController
    // tasiyor (bkz. widgets/zon_semasi.dart, Oncelik 11) -- pumpAndSettle
    // sonsuz animasyon karsisinda hicbir zaman "durulmaz" ve zaman asimina
    // ugrar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Genel Bakış'), findsWidgets);
    // Giris Ekrani'nin kendine ozgu elemanlari artik agac disinda olmali.
    expect(find.text('SDI Tıkanma Yönetim Merkezi'), findsNothing);

    durum.dispose();
  });
}
