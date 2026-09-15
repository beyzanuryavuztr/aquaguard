// AquaGuard - IsFizibilitesiEkrani Widget Testleri (Faz 3)
//
// Ekranin tasma/istisna olmadan cizildigini, kilit maliyet/fiyat/marj
// sayilarinin ve rakip karsilastirma tablosunun (3 rakip sutunu) dogru
// gorundugunu dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/screens/is_fizibilitesi_ekrani.dart';
import 'package:aquaguard_mobile/screens/model_performansi_ekrani.dart';

void main() {
  testWidgets(
    'tasma/istisna olmadan cizilir, kilit sayilar ve rakip tablosu gorunur',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: IsFizibilitesiEkrani()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('7.266 ₺'), findsOneWidget);
      expect(find.text('~11.200 ₺'), findsOneWidget);
      expect(find.text('%35'), findsOneWidget);
      expect(find.text('%89.9 ± %2.3'), findsOneWidget);

      // Rakip karsilastirma tablosu -- 3 rakip sutunu + AquaGuard'in kendi
      // ayirt edici ifadeleri.
      expect(find.text('Netafim NetBeat'), findsOneWidget);
      expect(find.text('Rivulis Manna'), findsOneWidget);
      expect(find.text('AquaGuard'), findsOneWidget);
      expect(
        find.text('pH+EC+ORP+türbidite+hidrolik füzyon'),
        findsOneWidget,
      );
      expect(find.text('Mutex kilidi + zorunlu durulama'), findsOneWidget);

      // Yarışma/takım bilgisi BİLEREK yok (bkz. Hakkında ekranıyla aynı ilke).
      expect(find.textContaining('TEKNOFEST'), findsNothing);
    },
  );

  testWidgets('ML doğruluk satırına dokununca Model Performansı ekranı açılır', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: IsFizibilitesiEkrani()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('%89.9 ± %2.3'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ModelPerformansiEkrani), findsOneWidget);
  });
}
