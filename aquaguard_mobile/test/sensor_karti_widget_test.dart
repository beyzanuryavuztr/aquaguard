// AquaGuard - SensorKarti Saglik Rozeti Testleri
//
// SensorKarti'ye eklenen opsiyonel saglikDurumu parametresi, sensorun
// KENDISININ arizali/guvenilmez olabilecegini gosteren kucuk bir rozet
// cizer (bkz. models/sensor_saglik_durumu.dart). Bu testler, rozetin
// SADECE anomali durumunda gorundugunu ve normal durumda mevcut kart
// gorunumunu DEGISTIRMEDIGINI dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_saglik_durumu.dart';
import 'package:aquaguard_mobile/widgets/sensor_karti.dart';

Widget _sar(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('saglikDurumu normal iken rozet ikonu gorunmez', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        SensorKarti(
          ikon: Icons.science,
          baslik: 'pH',
          birim: '',
          deger: 7.0,
          renk: Colors.brown,
          secili: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.priority_high), findsNothing);
    expect(find.byIcon(Icons.pause_circle), findsNothing);
  });

  testWidgets('saglikDurumu aniSicrama iken uyari ikonu gorunur', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        SensorKarti(
          ikon: Icons.science,
          baslik: 'pH',
          birim: '',
          deger: 9.0,
          renk: Colors.brown,
          secili: false,
          onTap: () {},
          saglikDurumu: SensorSaglikDurumu.aniSicrama,
        ),
      ),
    );

    expect(find.byIcon(Icons.priority_high), findsOneWidget);
  });

  testWidgets('saglikDurumu sabitDeger iken duraklatma ikonu gorunur', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sar(
        SensorKarti(
          ikon: Icons.science,
          baslik: 'pH',
          birim: '',
          deger: 7.0,
          renk: Colors.brown,
          secili: false,
          onTap: () {},
          saglikDurumu: SensorSaglikDurumu.sabitDeger,
        ),
      ),
    );

    expect(find.byIcon(Icons.pause_circle), findsOneWidget);
  });
}
