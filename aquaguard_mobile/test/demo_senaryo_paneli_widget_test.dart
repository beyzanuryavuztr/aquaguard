// AquaGuard - DemoSenaryoPaneli Widget Testleri
//
// Panelin tasma/istisna olmadan cizildigini ve bir senaryo cipine
// dokununca UygulamaDurumu.demoSenaryosuTetikle'nin gercekten
// cagrildigini (aktivite gecmisine kayit dustugunu) dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/demo_hizi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/widgets/demo_senaryo_paneli.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('5 senaryo cipi de tasma/istisna olmadan cizilir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(
          home: Scaffold(body: DemoSenaryoPaneli()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sağlıklı'), findsOneWidget);
    expect(find.text('Kimyasal'), findsOneWidget);
    expect(find.text('Biyolojik'), findsOneWidget);
    expect(find.text('Fiziksel'), findsOneWidget);
    expect(find.text('Mutex Kilidi'), findsOneWidget);
    expect(find.text('Demo Hızı'), findsOneWidget);
    for (final hiz in DemoHizi.values) {
      expect(find.text(hiz.etiket), findsOneWidget);
    }

    durum.dispose();
  });

  testWidgets('hiz segmentine dokununca demoHiziniAyarla cagrilir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    expect(durum.demoHizi, DemoHizi.normal);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(
          home: Scaffold(body: DemoSenaryoPaneli()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Turbo'));
    await tester.pumpAndSettle();

    expect(durum.demoHizi, DemoHizi.turbo);
    expect(tester.takeException(), isNull);

    durum.dispose();
  });

  testWidgets('bir senaryo cipine dokununca demoSenaryosuTetikle cagrilir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    final oncekiUzunluk = durum.aktiviteGecmisi.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(
          home: Scaffold(body: DemoSenaryoPaneli()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fiziksel'));
    await tester.pumpAndSettle();

    expect(durum.aktiviteGecmisi.length, oncekiUzunluk + 1);
    expect(
      durum.aktiviteGecmisi.first.mesaj,
      contains('Fiziksel Tıkanma'),
    );
    expect(tester.takeException(), isNull);

    durum.dispose();
  });
}
