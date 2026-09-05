// AquaGuard - OnboardingEkrani Widget Testleri (Oncelik 6)
//
// 4 sayfanin da tasma/istisna olmadan cizildigini, "Ileri" ile sirayla
// gezildigini, "Atla"nin ve son sayfadaki "Başla"nin onboardingi
// tamamlayip GirisEkrani'na gectigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/giris_ekrani.dart';
import 'package:aquaguard_mobile/screens/onboarding_ekrani.dart';

Future<UygulamaDurumu> _hazirDurum() async {
  final durum = UygulamaDurumu();
  await durum.baslat();
  return durum;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ilk sayfa (AquaGuard Nedir?) tasma/istisna olmadan cizilir', (
    tester,
  ) async {
    final durum = await _hazirDurum();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: OnboardingEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AquaGuard Nedir?'), findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('Ileri ile sirayla 4 sayfa gezilir, sonunda Basla gorunur', (
    tester,
  ) async {
    final durum = await _hazirDurum();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: OnboardingEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AquaGuard Nedir?'), findsOneWidget);

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text('Nasıl Çalışır?'), findsOneWidget);

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text('Tıkanma Türleri'), findsOneWidget);

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text('Haydi Başlayalım'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
    expect(tester.takeException(), isNull);

    durum.dispose();
  });

  testWidgets('Atla, onboardingi tamamlar ve GirisEkrani\'na gecer', (
    tester,
  ) async {
    final durum = await _hazirDurum();
    expect(durum.onboardingGoruldu, isFalse);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: OnboardingEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(durum.onboardingGoruldu, isTrue);
    expect(find.byType(GirisEkrani), findsOneWidget);

    durum.dispose();
  });

  testWidgets('son sayfadaki Basla, onboardingi tamamlar ve GirisEkrani\'na gecer', (
    tester,
  ) async {
    final durum = await _hazirDurum();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: OnboardingEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('İleri'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(durum.onboardingGoruldu, isTrue);
    expect(find.byType(GirisEkrani), findsOneWidget);

    durum.dispose();
  });
}
