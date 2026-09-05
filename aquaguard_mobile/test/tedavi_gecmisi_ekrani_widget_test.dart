// AquaGuard - TedaviGecmisiEkrani Widget Testleri (Asama 5)
//
// Yeni ekranin (pasta grafik + tedavi sayilari + YENI basari orani karti +
// etki karti + filtrelenebilir tespit gunlugu) tasma/istisna olmadan
// cizildigini ve bir filtre cipine dokunmanin istisna olusturmadigini
// dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/tedavi_gecmisi_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // NOT: UygulamaDurumu.baslat() gercek bir Timer.periodic (demo tikeri)
  // baslatir -- pumpAndSettle+scrollUntilVisible gibi coklu-adimli
  // etkilesimler bu canli tikerle CAKISIRSA (rebuild sirasinda) nadiren
  // kararsiz (flaky) davranabilir. Bunu tamamen onlemek icin test yuzeyini
  // TUM icerigi (kaydirmadan) kapsayacak kadar uzun yapiyoruz -- boylece
  // scrollUntilVisible'a hic gerek kalmiyor.
  Future<void> pumpUzunYuzeyle(WidgetTester tester, UygulamaDurumu durum) async {
    await tester.binding.setSurfaceSize(const Size(500, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: TedaviGecmisiEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'ekran tasma/istisna olmadan cizilir, basari orani ve filtre satirlari gorunur',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await pumpUzunYuzeyle(tester, durum);

      expect(tester.takeException(), isNull);
      expect(find.text('Tedavi Geçmişi'), findsOneWidget);
      expect(find.text('Ortalama Başarı Oranı'), findsOneWidget);
      expect(find.text('Projelendirilen Etki'), findsOneWidget);
      expect(find.text('Tespit Günlüğü'), findsOneWidget);
      expect(find.text('Zon'), findsOneWidget);
      expect(find.text('Tür'), findsOneWidget);
      expect(find.text('Dönem'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('bir tür filtresi cipine dokununca istisna olusmaz', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await pumpUzunYuzeyle(tester, durum);

    await tester.tap(find.text('Kimyasal').last);
    await tester.pump();

    expect(tester.takeException(), isNull);

    durum.dispose();
  });
}
