// AquaGuard - SulamaKontrolKarti Widget Testleri
//
// Panelin her iki gorunumunun de (acik/kapali) tasma veya istisna olmadan
// cizildigini ve dogru eylem butonunu gosterdigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/widgets/sulama_kontrol_karti.dart';

Widget _sarmala(UygulamaDurumu durum, Widget child) {
  return ChangeNotifierProvider.value(
    value: durum,
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sulama acikken "Durdur" butonu gosterilir, tasma olmaz', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      _sarmala(durum, const SulamaKontrolKarti(zonNumarasi: 1)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sulama: Açık'), findsOneWidget);
    expect(find.text('Durdur'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('sulama durdurulmusken yeniden baslatma karti gosterilir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await durum.sulamayiDurdur(1);

    await tester.pumpWidget(
      _sarmala(durum, const SulamaKontrolKarti(zonNumarasi: 1)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sulama Manuel Olarak Durduruldu'), findsOneWidget);
    expect(find.text('Sulamayı Yeniden Başlat'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('Durdur butonuna basinca onay diyalogu acilir ve onaylaninca durum degisir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      _sarmala(durum, const SulamaKontrolKarti(zonNumarasi: 1)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Durdur'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Durdur').last);
    await tester.pumpAndSettle();

    expect(durum.sulamasiDurduruldu(1), isTrue);

    durum.dispose();
  });
}
