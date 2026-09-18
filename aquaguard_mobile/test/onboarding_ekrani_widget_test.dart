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

  testWidgets(
    'Atla, gizlilik onayi verilmemisse SON sayfaya yonlendirir, onboardingi TAMAMLAMAZ',
    (tester) async {
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
      // Onboarding TAMAMLANMADI -- Atla, onay adimini BYPASS edemez.
      expect(durum.onboardingGoruldu, isFalse);
      expect(find.byType(GirisEkrani), findsNothing);
      // Son sayfaya (onay kutusunun oldugu) yonlendirilmis olmali.
      expect(find.text('Haydi Başlayalım'), findsOneWidget);
      expect(
        find.textContaining('Gizlilik Politikası'),
        findsWidgets,
        reason: 'kullaniciyi neden yonlendirdigimizi anlatan uyari gorunmeli',
      );

      durum.dispose();
    },
  );

  testWidgets(
    'gizlilik onaylanmisken Atla, onboardingi tamamlar ve GirisEkrani\'na gecer',
    (tester) async {
      final durum = await _hazirDurum();
      await durum.gizlilikOnayiniAyarla(true);

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
    },
  );

  testWidgets(
    'son sayfada Basla, gizlilik onayi verilmeden DEVRE DISI kalir',
    (tester) async {
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

      final buton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buton.onPressed, isNull);

      await tester.tap(find.text('Başla'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(durum.onboardingGoruldu, isFalse);
      expect(find.byType(GirisEkrani), findsNothing);

      durum.dispose();
    },
  );

  testWidgets(
    'onay kutusu isaretlenince son sayfadaki Basla ETKINLESIR ve onboardingi tamamlar',
    (tester) async {
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

      // find.byType(CheckboxListTile) merkeze dokunur -- bu, ic ice
      // gomulu "Gizlilik Politikası" baglantisinin (InkWell) TAM ustune
      // denk gelip navigasyonu tetikleyebilir. Checkbox'in KENDISINE
      // dokunmak daha kesin.
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(durum.gizlilikOnaylandi, isTrue);
      final buton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buton.onPressed, isNotNull);

      await tester.tap(find.text('Başla'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(durum.onboardingGoruldu, isTrue);
      expect(find.byType(GirisEkrani), findsOneWidget);

      durum.dispose();
    },
  );
}
