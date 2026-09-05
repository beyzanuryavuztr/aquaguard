// AquaGuard - AktifTedavilerBolumu Widget Testleri
//
// Genel Bakis'taki aktif tedaviler mini listesinin: (1) tedavisi olmayan
// zonlari HARIC tuttugunu, (2) aktif tedavisi olan zonu ilerleme cubuguyla
// gosterdigini, (3) dokunmaninin dogru zonu bildirdigini, tasma/istisna
// olmadan dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/widgets/aktif_tedaviler_bolumu.dart';

SensorOkuma _okuma({required int zone, required TedaviTuru tedavi}) =>
    SensorOkuma(
      zaman: DateTime(2026, 9, 4, 10),
      zone: zone,
      ph: 6.8,
      ec: 1.2,
      orp: 300,
      turbidite: 2.0,
      debi: 4.1,
      deltaBasinc: 0.1,
      durum: TeshisDurumu.tespitEdildi,
      tikanmaTuru: TikanmaTuru.kimyasal,
      guven: 90,
      tedaviAktif: tedavi,
      durulamaAktif: false,
    );

void main() {
  testWidgets('aktif tedavisi olmayan zonlar listede görünmez, boşsa hiçbir şey çizmez', (
    tester,
  ) async {
    final okumalar = {1: _okuma(zone: 1, tedavi: TedaviTuru.yok)};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AktifTedavilerBolumu(
            zonlar: const [1],
            okumaGetir: (z) => okumalar[z],
            baslangicGetir: (_) => null,
            onZonSecildi: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('aktif tedavisi olan zon ilerleme çubuğuyla gösterilir, dokunma zonu bildirir', (
    tester,
  ) async {
    int? secilenZon;
    final okumalar = {
      2: _okuma(zone: 2, tedavi: TedaviTuru.asitDozlama),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AktifTedavilerBolumu(
            zonlar: const [2],
            okumaGetir: (z) => okumalar[z],
            baslangicGetir: (_) => DateTime.now(),
            onZonSecildi: (z) => secilenZon = z,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Zon 2'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(secilenZon, 2);
  });
}
