// AquaGuard - GizlilikPolitikasiEkrani Widget Testleri
//
// Ekranin tasma/istisna olmadan cizildigini ve Ayarlar ekranindaki
// "Gizlilik Politikası" satirinin bu ekrana gectigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/ayarlar_ekrani.dart';
import 'package:aquaguard_mobile/screens/gizlilik_politikasi_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tasma/istisna olmadan cizilir, tum bolumler gorunur', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GizlilikPolitikasiEkrani()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hangi veriyi topluyoruz?'), findsOneWidget);
    expect(find.text('Bu veri nerede saklanır?'), findsOneWidget);
    expect(find.text('Ağ üzerinden neler gidip geliyor?'), findsOneWidget);
  });

  testWidgets(
    'Ayarlar ekranindaki Gizlilik Politikası satiri bu ekrana gecer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 6000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.ayarlarProvider),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
            ChangeNotifierProvider.value(value: durum.tarlaProvider),
            ChangeNotifierProvider.value(value: durum.bakimProvider),
            ChangeNotifierProvider.value(value: durum.guvenlikProvider),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: AyarlarEkrani(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Gizlilik Politikası'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GizlilikPolitikasiEkrani), findsOneWidget);

      durum.dispose();
    },
  );
}
