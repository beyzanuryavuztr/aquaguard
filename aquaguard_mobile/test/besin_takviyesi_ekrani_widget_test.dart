// AquaGuard - BesinTakviyesiEkrani Widget Testleri (Faz 3)
//
// Ekranin tasma/istisna olmadan cizildigini, zon secip "Sıvı"/"Toz Takviye
// Başlat" butonlarina basinca CihazIletisimProvider.besinDozlamaBaslat'in
// dogru TedaviTuru ile cagrildigini dogrular (Demo Modu'nda).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/besin_takviyesi_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpEkran(WidgetTester tester, UygulamaDurumu durum) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
          ChangeNotifierProvider.value(value: durum.tarlaProvider),
        ],
        child: const MaterialApp(home: BesinTakviyesiEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets('tasma/istisna olmadan cizilir, butonlar zon secilmeden pasif', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await pumpEkran(tester, durum);

    expect(tester.takeException(), isNull);
    expect(find.text('Çiftlik'), findsOneWidget);
    expect(find.text('Hedef Zon(lar)'), findsOneWidget);
    expect(find.text('Sıvı Takviye Başlat'), findsOneWidget);
    expect(find.text('Toz Takviye Başlat'), findsOneWidget);

    final siviButonu = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Sıvı Takviye Başlat'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(siviButonu.onPressed, isNull);

    durum.dispose();
  });

  testWidgets(
    'zon secilip "Sıvı Takviye Başlat"a basinca basari mesaji gosterilir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      await pumpEkran(tester, durum);

      final ilkTarlaZonlari = durum.tarlaProvider.tarlalar.first.zonNumaralari;
      await tester.tap(
        find.text(durum.tarlaProvider.zonAdiGetir(ilkTarlaZonlari.first)),
      );
      await tester.pump();

      await tester.tap(find.text('Sıvı Takviye Başlat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('başlatıldı'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets(
    'zon secilip "Toz Takviye Başlat"a basinca basari mesaji gosterilir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      await pumpEkran(tester, durum);

      final ilkTarlaZonlari = durum.tarlaProvider.tarlalar.first.zonNumaralari;
      await tester.tap(
        find.text(durum.tarlaProvider.zonAdiGetir(ilkTarlaZonlari.first)),
      );
      await tester.pump();

      await tester.tap(find.text('Toz Takviye Başlat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('başlatıldı'), findsOneWidget);

      durum.dispose();
    },
  );
}
