// AquaGuard - HakkindaEkrani Widget Testleri (Oncelik 5)
//
// Sayfanin tasma/istisna olmadan cizildigini, takim/danisman/universite
// bilgilerinin gorundugunu ve Ayarlar'daki "Hakkında" satirinin gercekten
// bu ekrana gectigini dogrular.

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
    expect(find.text('Proje'), findsOneWidget);
    expect(find.text('Takım'), findsOneWidget);
    expect(find.text('Arge-T HydroLab (Takım No: 993372)'), findsOneWidget);
    expect(find.text('Üyeler'), findsOneWidget);
    expect(find.text('Danışman'), findsOneWidget);
    expect(find.text('Dr. Öğr. Üyesi Tuğçem Partal'), findsOneWidget);
    expect(find.text('Üniversite'), findsOneWidget);
    expect(find.text('Recep Tayyip Erdoğan Üniversitesi'), findsOneWidget);
    expect(find.text('Lisanslar'), findsOneWidget);
    expect(
      find.text('Doğru Teşhis, Doğru Tedavi, Sürdürülebilir Sulama'),
      findsOneWidget,
    );
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
    await tester.binding.setSurfaceSize(const Size(500, 2600));
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
