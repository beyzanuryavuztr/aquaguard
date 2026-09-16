// AquaGuard - TarlaGpsHaritasi Testleri
//
// NOT: TileLayer arka planda gercek ag istegi baslatir (harita karolari)
// -- bu testler bilerek `pumpAndSettle()` KULLANMAZ (ag cevabini
// SONSUZA KADAR bekleme riski), sadece tek bir `pump()` ile widget
// agacinin cokmeden kuruldugunu dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/widgets/tarla_gps_haritasi.dart';

Widget _sar(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('gecerli koordinatlarla tasma/istisna olmadan cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        const TarlaGpsHaritasi(enlem: 37.1591, boylam: 38.7969), // Şanlıurfa
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.location_pin), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sinir degerlerinde (ekvator/greenwich) cokmez', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(const TarlaGpsHaritasi(enlem: 0, boylam: 0)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
