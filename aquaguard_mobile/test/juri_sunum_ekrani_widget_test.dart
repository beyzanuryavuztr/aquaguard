// AquaGuard - JuriSunumEkrani Widget Testleri (Faz 4)
//
// Ekranin tasma/istisna olmadan cizildigini, Ileri/Geri ile adimlar
// arasinda gezinmenin calistigini ve bir "Bu Adımı Tetikle" butonuna
// basinca UygulamaDurumu.demoSenaryosuTetikle'nin gercekten cagrildigini
// (aktivite gecmisine kayit dustugunu) dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/sunum_adimi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/juri_sunum_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tasma/istisna olmadan cizilir, ilk adim gorunur', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adım 1 / ${sunumAdimlari.length}'), findsOneWidget);
    expect(find.text(sunumAdimlari.first.baslik), findsOneWidget);
    // Ilk adimin tetikleme senaryosu yok -- buton gorunmemeli.
    expect(find.text('Bu Adımı Tetikle'), findsNothing);

    durum.dispose();
  });

  testWidgets('İleri ile 2. adıma geçilince tetikleme butonu görünür', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('İleri'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adım 2 / ${sunumAdimlari.length}'), findsOneWidget);
    expect(find.text(sunumAdimlari[1].baslik), findsOneWidget);
    expect(find.text('Bu Adımı Tetikle'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('Geri ile önceki adıma dönülür', (tester) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('İleri'));
    await tester.pump();
    await tester.tap(find.text('Geri'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adım 1 / ${sunumAdimlari.length}'), findsOneWidget);

    durum.dispose();
  });

  testWidgets(
    '"Bu Adımı Tetikle" butonuna basınca demoSenaryosuTetikle çağrılır',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final oncekiUzunluk = durum.aktiviteGecmisi.length;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: durum,
          child: const MaterialApp(home: JuriSunumEkrani()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('İleri')); // 2. adım -- Sağlıklı Sistem
      await tester.pump();
      await tester.tap(find.text('Bu Adımı Tetikle'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(durum.aktiviteGecmisi.length, greaterThan(oncekiUzunluk));

      durum.dispose();
    },
  );

  testWidgets('son adımda İleri butonu devre dışı kalır', (tester) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    for (var i = 0; i < sunumAdimlari.length - 1; i++) {
      await tester.tap(find.text('İleri'));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    expect(
      find.text('Adım ${sunumAdimlari.length} / ${sunumAdimlari.length}'),
      findsOneWidget,
    );
    final bittiButonu = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Bitti'),
    );
    expect(bittiButonu.onPressed, isNull);

    durum.dispose();
  });
}
