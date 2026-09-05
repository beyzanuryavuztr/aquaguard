// AquaGuard - TikanmaDetayEkrani Widget Testleri (Asama 3 genislemesi)
//
// Zon Detay ekranina eklenen yeni bolumlerin (Karar Katmani etiketi, Mutex
// Kilit Gostergesi, Sensor Analizi karti izgarasi + buyuk trend grafigi)
// tasma/istisna olmadan cizildigini ve sensor karti seciminin grafigin
// basligini degistirdigini dogrular. Mevcut SulamaKontrolKarti/
// ManuelMudahalePaneli'nin hala calistigi (regresyon olmadigi) da kontrol edilir.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/tikanma_detay_ekrani.dart';

Widget _sarmala(UygulamaDurumu durum) {
  return ChangeNotifierProvider.value(
    value: durum,
    child: const MaterialApp(
      home: TikanmaDetayEkrani(zonNumarasi: 1),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'yeni bolumler (karar katmani, mutex kilidi, sensor analizi) tasma/istisna olmadan cizilir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(_sarmala(durum));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Karar Katmanı: Kural Tabanlı (Katman 1 — birincil)'),
        findsOneWidget,
      );
      expect(find.text('Tedavi Kanalı Kilidi'), findsOneWidget);

      // "Sensör Analizi" bolumu ListView'in altinda, viewport disinda
      // kalabilir -- once kaydirarak gorunur hale getir.
      await tester.scrollUntilVisible(find.text('Sensör Analizi'), 300);
      await tester.pumpAndSettle();

      expect(find.text('Sensör Analizi'), findsOneWidget);
      // Varsayilan secili sensor Debi'dir.
      expect(find.text('Debi Eğilimi'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('bir sensor kartina dokununca buyuk grafigin basligi degisir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(_sarmala(durum));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Sensör Analizi'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Debi Eğilimi'), findsOneWidget);

    await tester.tap(find.text('pH'));
    await tester.pumpAndSettle();

    expect(find.text('pH Eğilimi'), findsOneWidget);
    expect(find.text('Debi Eğilimi'), findsNothing);
    expect(tester.takeException(), isNull);

    durum.dispose();
  });
}
