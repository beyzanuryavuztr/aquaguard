// AquaGuard - ZonSemasi Widget Testleri
//
// Genel Bakis'in yeni sematik SDI hat diyagraminin tasma/istisna olmadan
// cizildigini, cevrimdisi/cevrimici zonlari dogru ayirt ettigini ve
// dokunmanin dogru zon numarasiyla geri cagrildigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/widgets/zon_semasi.dart';

SensorOkuma _ornekOkuma(int zone) => SensorOkuma(
  zaman: DateTime(2026, 9, 4, 10),
  zone: zone,
  ph: 6.8,
  ec: 1.2,
  orp: 300,
  turbidite: 2.0,
  debi: 4.1,
  deltaBasinc: 0.1,
  durum: TeshisDurumu.normal,
  tikanmaTuru: TikanmaTuru.yok,
  guven: 100,
  tedaviAktif: TedaviTuru.yok,
  durulamaAktif: false,
);

void main() {
  testWidgets('4 zonlu semayı taşma/istisna olmadan çizer, dokunma doğru zonu bildirir', (
    tester,
  ) async {
    int? secilenZon;
    final okumalar = {for (final z in [1, 2, 3, 4]) z: _ornekOkuma(z)};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZonSemasi(
            zonlar: const [1, 2, 3, 4],
            okumaGetir: (z) => okumalar[z],
            cevrimiciMi: (_) => true,
            onZonSecildi: (z) => secilenZon = z,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Zon 1'), findsOneWidget);
    expect(find.text('Zon 4'), findsOneWidget);

    await tester.tap(find.text('Zon 2'));
    await tester.pumpAndSettle();
    expect(secilenZon, 2);
  });

  testWidgets('çevrimdışı zon "—" gösterir, taşma/istisna olmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZonSemasi(
            zonlar: const [1],
            okumaGetir: (_) => null,
            cevrimiciMi: (_) => false,
            onZonSecildi: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('boş zon listesinde bilgilendirme metni gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZonSemasi(
            zonlar: const [],
            okumaGetir: (_) => null,
            cevrimiciMi: (_) => false,
            onZonSecildi: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Henüz izlenen zon yok.'), findsOneWidget);
  });
}
