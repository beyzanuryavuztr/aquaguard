// AquaGuard - GirisEkrani Widget Testleri (Asama 6)
//
// Hazir olmadan once yukleniyor gostergesi gosterdigini, hazir olunca
// marka + Demo Modu karti + (varsa) ciftlik ozeti + "Devam Et" butonunu
// tasma/istisna olmadan cizdigini ve "Devam Et"e basinca AnaKabuk'a
// (Genel Bakış sekmesine) gecistigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/giris_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hazir olmadan once yukleniyor gostergesi gosterir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: GirisEkrani()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('AquaGuard'), findsNothing);

    durum.dispose();
  });

  testWidgets(
    'hazir olunca marka + Demo Modu karti + ciftlik ozeti + Devam Et gosterir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: durum,
          child: const MaterialApp(home: GirisEkrani()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AquaGuard'), findsOneWidget);
      expect(find.text('SDI Tıkanma Yönetim Merkezi'), findsOneWidget);
      expect(find.text('Demo Modu'), findsOneWidget);
      expect(find.text('1 çiftlik, 4 zon izleniyor'), findsOneWidget);
      // Yarışma/takım markalaması BİLEREK yok (kullanıcının kesin talebi).
      expect(find.text('Arge-T HydroLab • TEKNOFEST 2026'), findsNothing);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('"Devam Et"e basinca AnaKabuk\'a (Genel Bakış) gecer', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: GirisEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Devam Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Genel Bakış'), findsWidgets);
    // Giris Ekrani'nin kendine ozgu elemanlari artik agac disinda olmali.
    expect(find.text('SDI Tıkanma Yönetim Merkezi'), findsNothing);

    durum.dispose();
  });
}
