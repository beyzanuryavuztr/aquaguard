// AquaGuard - HakkindaEkrani Widget Testleri (Oncelik 5)
//
// Sayfanin tasma/istisna olmadan cizildigini, yarisma/takim bilgisi
// ICERMEDIGINI (kullanicinin kesin talebi) ve Ayarlar'daki "Hakkında"
// satirinin gercekten bu ekrana gectigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/ayarlar_ekrani.dart';
import 'package:aquaguard_mobile/screens/hakkinda_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tasma/istisna olmadan cizilir, tum bilgi kartlari gorunur', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: HakkindaEkrani()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AquaGuard'), findsOneWidget);
    expect(find.text('Uygulama Hakkında'), findsOneWidget);
    expect(find.text('Lisanslar'), findsOneWidget);
    expect(
      find.text('Doğru Teşhis, Doğru Tedavi, Sürdürülebilir Sulama'),
      findsOneWidget,
    );

    // Yarışma/takım/üniversite bilgisi BİLEREK yok.
    expect(find.text('Takım'), findsNothing);
    expect(find.text('Arge-T HydroLab (Takım No: 993372)'), findsNothing);
    expect(find.text('Üyeler'), findsNothing);
    expect(find.text('Danışman'), findsNothing);
    expect(find.text('Üniversite'), findsNothing);
    expect(find.textContaining('TEKNOFEST'), findsNothing);
  });

  testWidgets('Lisanslar satirina dokununca lisans sayfasi acilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HakkindaEkrani()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lisanslar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('Ayarlar ekranindaki Hakkinda satiri HakkindaEkrani\'na gecer', (
    tester,
  ) async {
    // NOT: durum.baslat() gercek bir Timer.periodic (demo tikeri) baslatir --
    // scrollUntilVisible gibi coklu-adimli etkilesimler bununla nadiren
    // cakisabilir (bkz. onceki asamalarda bulunan flakiness). Test yuzeyini
    // TUM icerigi kapsayacak kadar uzun yaparak kaydirmaya hic gerek birakmiyoruz.
    // Yukseklik 2600 -> 3800: yeni "Bakım Takvimi" karti (4 gorev satiri,
    // her biri isThreeLine) eklendi, Hakkında satiri artik daha asagida
    // (bkz. Oncelik 12).
    await tester.binding.setSurfaceSize(const Size(500, 3800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: AyarlarEkrani()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HakkindaEkrani), findsOneWidget);

    durum.dispose();
  });
}
