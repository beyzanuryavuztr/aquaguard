// AquaGuard - SensorGaugeWidget Testleri
//
// Taşma/istisna kontrolü + farklı değer/aralık kombinasyonlarında doğru
// (0..1 aralığına clamp edilmiş) render.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/widgets/sensor_gauge_widget.dart';

Widget _sar(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('normal aralik icinde deger tasma/istisna olmadan cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        const SensorGaugeWidget(
          deger: 7.2,
          minDeger: 0,
          maxDeger: 14,
          birim: '',
          renk: Colors.brown,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('7.20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deger min altindaysa clamp edilir, istisna olmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        const SensorGaugeWidget(
          deger: -5,
          minDeger: 0,
          maxDeger: 6,
          birim: 'LPM',
          renk: Colors.blue,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
  });

  testWidgets('deger max ustundeyse clamp edilir, istisna olmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        const SensorGaugeWidget(
          deger: 999,
          minDeger: 0,
          maxDeger: 50,
          birim: 'NTU',
          renk: Colors.orange,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
  });

  testWidgets('min==max (sifir aralik) icin bolme hatasi olmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        const SensorGaugeWidget(
          deger: 5,
          minDeger: 5,
          maxDeger: 5,
          birim: '',
          renk: Colors.red,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
  });
}
