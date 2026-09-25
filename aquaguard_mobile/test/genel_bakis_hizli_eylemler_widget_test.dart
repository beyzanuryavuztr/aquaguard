// AquaGuard - Genel Bakış "Hızlı Eylemler" Regresyon Testleri
//
// ACIMASIZ DENETIM (2026-09-25): Uzaktan Sulama/Besin Takviyesi daha once
// SADECE AppBar'daki etiketsiz "⋮" menusunun icindeydi -- kullanici gercek
// uygulamada denedi ve ozelligi BULAMADI. Artik Genel Bakis govdesinde
// yazili, dogrudan gorunur iki buton var. Bu test dosyasi butonlarin
// GORUNUR oldugunu ve dogru ekranlara GECTIGINI kilitler.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/besin_takviyesi_ekrani.dart';
import 'package:aquaguard_mobile/screens/genel_bakis_ekrani.dart';
import 'package:aquaguard_mobile/screens/uzaktan_sulama_ekrani.dart';

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

Future<UygulamaDurumu> _kurulumYap(WidgetTester tester) async {
  final durum = UygulamaDurumu();
  await durum.baslat();
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
      child: _uygulamaSarici(const GenelBakisEkrani()),
    ),
  );
  // pumpAndSettle DEGIL: ZonSemasi'nin surekli nabiz animasyonu var
  // (bkz. giris_ekrani_widget_test.dart ayni not).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return durum;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    '"Sulama Başlat" ve "Besin Takviyesi" butonları AppBar\'a gizli bir '
    'menu ARDINDA DEGIL, dogrudan govdede yazili/gorunur',
    (tester) async {
      final durum = await _kurulumYap(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Sulama Başlat'), findsOneWidget);
      expect(find.text('Besin Takviyesi'), findsOneWidget);
      // Eski gizli menu artik yok.
      expect(find.text('Daha fazla'), findsNothing);

      durum.dispose();
    },
  );

  testWidgets('"Sulama Başlat" butonu Uzaktan Sulama ekranına götürür', (
    tester,
  ) async {
    final durum = await _kurulumYap(tester);
    // tester.tap DEGIL: demo modundaki canli aktivite bildirimleri
    // (SnackBar) tam bu anda gorunuyor olup butonun ustune binebilir --
    // bu, gercek uygulamadaki bir onceki bug'la (Jüri Sunum Modu) AYNI
    // sinif sorun, testi ondan bagimsiz kilmak icin onPressed dogrudan
    // cagrilir (bkz. proje hafizasindaki SnackBarAction.onPressed deseni).
    final buton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sulama Başlat'),
    );
    buton.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(UzaktanSulamaEkrani), findsOneWidget);

    durum.dispose();
  });

  testWidgets('"Besin Takviyesi" butonu Besin Takviyesi ekranına götürür', (
    tester,
  ) async {
    final durum = await _kurulumYap(tester);
    final buton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Besin Takviyesi'),
    );
    buton.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(BesinTakviyesiEkrani), findsOneWidget);

    durum.dispose();
  });
}
