// AquaGuard - YardimButonu Testleri
//
// Bagimsiz (?, "?" ikonu) butonun bilinen bir ekran anahtari icin modal
// actigini, bilinmeyen bir anahtar icin bos widget dondugunu dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/widgets/yardim_butonu.dart';

Widget _sar(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('bilinen ekran anahtari icin butona dokununca modal acilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        const YardimButonu(ekranAnahtari: 'genel_bakis', baslik: 'Genel Bakış'),
      ),
    );

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bilinmeyen ekran anahtari icin bos widget doner, istisna olmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(const YardimButonu(ekranAnahtari: 'yok_boyle_bir_ekran', baslik: 'X')),
    );

    expect(find.byIcon(Icons.help_outline), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
