// AquaGuard - Semantics kapsami testleri (C1)
//
// Renk/ikonla anlatilan durumlarin ekran okuyucu icin acik etiket/deger
// tasidigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/sensor_saglik_durumu.dart';
import 'package:aquaguard_mobile/widgets/enerji_gostergesi.dart';
import 'package:aquaguard_mobile/widgets/mutex_kilit_gostergesi.dart';
import 'package:aquaguard_mobile/widgets/sensor_karti.dart';

Widget _sar(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('SensorKarti: etiket, deger, secili ve saglik uyarisi okunur', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _sar(
        SensorKarti(
          ikon: Icons.water,
          baslik: 'pH',
          birim: '',
          deger: 6.8,
          renk: Colors.teal,
          secili: true,
          onTap: () {},
          saglikDurumu: SensorSaglikDurumu.aniSicrama,
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('pH sensörü'));
    expect(node.value, contains('6.80'));
    expect(node.value, contains('uyarı'));
    expect(node.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets(
    'MutexKilitGostergesi: aktif kanal calisiyor, digerleri kilitli',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _sar(const MutexKilitGostergesi(aktifTedavi: TedaviTuru.asitDozlama)),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Asit kanalı')).value,
        'çalışıyor',
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Klor kanalı')).value,
        'kilitli',
      );
      handle.dispose();
    },
  );

  testWidgets('EnerjiGostergesi: pil ve WiFi tek anlamli metin olarak okunur', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_sar(const EnerjiGostergesi()));

    final node = tester.getSemantics(
      find.bySemanticsLabel('Cihaz enerji durumu, simüle gösterge'),
    );
    expect(node.value, startsWith('Pil yüzde'));
    handle.dispose();
  });
}
