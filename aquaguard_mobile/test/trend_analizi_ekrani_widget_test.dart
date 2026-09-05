// AquaGuard - TrendAnaliziEkrani Widget Testleri (Oncelik 9)
//
// Zon + tarih araligi secimine bagli, 6 sensorun tamaminin tek sayfada
// tasma/istisna olmadan cizildigini ve zon/donem secimi degistirmenin
// istisna olusturmadigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/trend_analizi_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // NOT: 6 sensor grafigi + zon/donem secicileri dikeyde uzun bir sayfa
  // olusturur -- diger ekran testlerindeki gibi (bkz. tedavi_gecmisi_ekrani
  // _widget_test.dart) canli demo Timer'iyla scrollUntilVisible cakismasini
  // onlemek icin TUM icerigi kapsayan uzun bir yuzey kullaniyoruz.
  Future<void> pumpUzunYuzeyle(WidgetTester tester, UygulamaDurumu durum) async {
    await tester.binding.setSurfaceSize(const Size(500, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: TrendAnaliziEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'ekran tasma/istisna olmadan cizilir, 6 sensorun tamami ve zon/donem seciciler gorunur',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await pumpUzunYuzeyle(tester, durum);

      expect(tester.takeException(), isNull);
      expect(find.text('Trend Analizi'), findsOneWidget);
      expect(find.text('Zon'), findsOneWidget);
      expect(find.text('Tarih Aralığı'), findsOneWidget);
      expect(find.text('pH Eğilimi'), findsOneWidget);
      expect(find.text('EC Eğilimi'), findsOneWidget);
      expect(find.text('ORP Eğilimi'), findsOneWidget);
      expect(find.text('Türbidite Eğilimi'), findsOneWidget);
      expect(find.text('Debi Eğilimi'), findsOneWidget);
      expect(find.text('ΔBasınç Eğilimi'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('baska bir zon cipine dokununca istisna olusmaz', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await pumpUzunYuzeyle(tester, durum);

    final zon2Cipi = find.text('Zon 2');
    expect(zon2Cipi, findsOneWidget);
    await tester.tap(zon2Cipi);
    await tester.pump();

    expect(tester.takeException(), isNull);

    durum.dispose();
  });

  testWidgets('donem degistirince (7g) istisna olusmaz', (tester) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await pumpUzunYuzeyle(tester, durum);

    final yediGunSekmesi = find.text('7g').first;
    await tester.tap(yediGunSekmesi);
    await tester.pump();

    expect(tester.takeException(), isNull);

    durum.dispose();
  });
}
