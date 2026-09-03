// AquaGuard - AsistanEkrani Widget Testi
//
// Sohbet ekraninin acilista karsilama mesaji + ornek soru cipleriyle
// tasmadan cizildigini, bir soru gonderilince kullanici balonu + asistan
// yanit balonunun eklendigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/asistan_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('acilista karsilama mesaji ve ornek sorular gosterilir, tasma olmaz', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: AsistanEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Merhaba! Ben AquaGuard'), findsOneWidget);
    expect(find.text('Genel durum nasıl?'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('ornek soru cipine dokununca soru + yanit balonlari eklenir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: AsistanEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Genel durum nasıl?').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Soru artik hem cip olarak hem gonderilen mesaj balonu olarak
    // bulunabilir -- en az 2 kez gecmesi beklenir.
    expect(find.text('Genel durum nasıl?'), findsWidgets);
    expect(find.textContaining('zon normal'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('metin kutusuna yazip gonder ikonuna basinca yanit gelir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: AsistanEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zon 1 nasıl?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Zon 1'), findsWidgets);

    durum.dispose();
  });
}
