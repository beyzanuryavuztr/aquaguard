// AquaGuard - AyarlarEkrani Widget Testleri (Asama 7 genislemesi)
//
// Yeni bolumlerin (4 bildirim anahtari, Zon Isimleri, Sensor Kalibrasyonu,
// Esik Degerleri -- hepsi salt-okunur kalibrasyon/esik disinda) tasma/
// istisna olmadan cizildigini ve zon takma adi verme akisinin gercekten
// UygulamaDurumu'nu guncelledigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/ayarlar_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpUzunYuzeyle(WidgetTester tester, UygulamaDurumu durum) async {
    await tester.binding.setSurfaceSize(const Size(500, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: AyarlarEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'yeni bolumler (bildirimler, zon isimleri, kalibrasyon, esikler) tasma/istisna olmadan cizilir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await pumpUzunYuzeyle(tester, durum);

      expect(tester.takeException(), isNull);
      expect(find.text('Tıkanma tespiti'), findsOneWidget);
      expect(find.text('Tedavi başlangıcı'), findsOneWidget);
      expect(find.text('Tedavi tamamlanma'), findsOneWidget);
      expect(find.text('Düşük pil'), findsOneWidget);
      expect(find.text('Zon İsimleri'), findsOneWidget);
      expect(find.text('Zon 1'), findsOneWidget);
      expect(find.text('Sensör Kalibrasyonu'), findsOneWidget);
      expect(find.text('pH ofset'), findsOneWidget);
      expect(find.text('Eşik Değerleri'), findsOneWidget);
      expect(find.text('Referans debi'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('bir bildirim anahtarina dokununca sadece o kategori degisir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await pumpUzunYuzeyle(tester, durum);

    await tester.tap(find.text('Tıkanma tespiti'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(durum.bildirimTercihleri.tespit, isFalse);
    expect(durum.bildirimTercihleri.tedaviBaslangic, isTrue);

    durum.dispose();
  });

  testWidgets('zon adina dokununca diyalog acilir, yeni ad kaydedilir', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await pumpUzunYuzeyle(tester, durum);

    await tester.tap(find.widgetWithText(ListTile, 'Zon 1'));
    await tester.pump();

    expect(find.text('Zon 1 Takma Adı'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Kuzeydoğu Parseli',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(durum.zonAdiGetir(1), 'Kuzeydoğu Parseli');

    durum.dispose();
  });
}
