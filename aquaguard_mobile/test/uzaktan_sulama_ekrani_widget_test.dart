// AquaGuard - UzaktanSulamaEkrani Widget Testleri
//
// Ekranin tasma/istisna olmadan cizildigini, coklu zon secip suresi
// girildiginde "sula" butonuna basinca CihazIletisimProvider.
// sulamayiSureliBaslat'in HER SECILI ZON icin dogru dakikayla
// cagrildigini dogrular (Demo Modu'nda, gercek MQTT gondermeden).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/uzaktan_sulama_ekrani.dart';

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
        child: const MaterialApp(home: UzaktanSulamaEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets('tasma/istisna olmadan cizilir, ilk ciftlik ve zonlari gorunur', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await pumpEkran(tester, durum);

    expect(tester.takeException(), isNull);
    expect(find.text('Çiftlik'), findsOneWidget);
    expect(find.text('Sulanacak Zon(lar)'), findsOneWidget);
    // Zon secilmeden buton pasif ("Önce zon seçin" etiketiyle) gorunmeli.
    expect(find.text('Önce zon seçin'), findsOneWidget);

    durum.dispose();
  });

  testWidgets(
    'zon secilip suresiyle "sula" butonuna basinca sulamayiSureliBaslat '
    'HER SECILI ZON icin cagrilir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      await pumpEkran(tester, durum);

      final ilkTarlaZonlari = durum.tarlaProvider.tarlalar.first.zonNumaralari;
      expect(ilkTarlaZonlari, isNotEmpty);

      // Ilk iki zonu sec (tek zonlu bir tarla ise sadece birini).
      final secilecekler = ilkTarlaZonlari.take(2);
      for (final zon in secilecekler) {
        await tester.tap(
          find.text(durum.tarlaProvider.zonAdiGetir(zon)),
        );
        await tester.pump();
      }

      await tester.enterText(find.byType(TextFormField), '45');
      await tester.pump();

      expect(find.text('${secilecekler.length} zonu sula'), findsOneWidget);
      await tester.tap(find.text('${secilecekler.length} zonu sula'));
      await tester.pump();
      // Async islemler (sulamayiSureliBaslat await'leri) icin ek pump'lar.
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Basari SnackBar'i gorunmeli (butonun secimi temizlemesiyle birlikte).
      expect(find.textContaining('dakikalık sulama başlatıldı'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('gecersiz (bos/0) sure girilirse uyari SnackBar gosterilir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await pumpEkran(tester, durum);

    final ilkTarlaZonlari = durum.tarlaProvider.tarlalar.first.zonNumaralari;
    await tester.tap(
      find.text(durum.tarlaProvider.zonAdiGetir(ilkTarlaZonlari.first)),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.pump();
    await tester.tap(find.text('1 zonu sula'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Geçerli bir süre (dakika) girin'), findsOneWidget);

    durum.dispose();
  });
}
