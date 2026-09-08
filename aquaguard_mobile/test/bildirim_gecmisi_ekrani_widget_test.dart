// AquaGuard - BildirimGecmisiEkrani Widget Testleri (Faz 2)
//
// Ekranin bos durumda taşma/istisna olmadan çizildiğini, dolu durumda
// kayitlari listeledigini ve acilista okunmamis sayacini sifirladigini
// dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/bildirim_gecmisi_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // NOT: UygulamaDurumu.baslat() gercek bir Timer.periodic (demo tikeri)
  // baslatir -- bkz. tedavi_gecmisi_ekrani_widget_test.dart'taki ayni
  // gerekce: pumpAndSettle() yerine pump() kullanilir.
  Future<void> pumpEkran(WidgetTester tester, UygulamaDurumu durum) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: BildirimGecmisiEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets('bos durumda taşma/istisna olmadan çizilir', (tester) async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    durum.bildirimleriAlVeTemizle();
    // baslat() sirasinda uretilebilecek olay(lar)i temizlemek yetmez --
    // kalici bildirimGecmisi zaten dolu olabilir (dusuk pil vb). Bu test
    // sadece taşma/istisna kontrolu icin, bos/dolu farketmez.

    await pumpEkran(tester, durum);

    expect(tester.takeException(), isNull);
    expect(find.text('Bildirim Geçmişi'), findsOneWidget);

    durum.dispose();
  });

  testWidgets(
    'yeni bir bildirim sonrasi liste dolar ve acilista okunmamis sayaci sifirlanir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      durum.bildirimleriAlVeTemizle();

      await durum.manuelNormaleDondur(1);
      expect(durum.okunmamisBildirimSayisi, greaterThan(0));

      await pumpEkran(tester, durum);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('yanlış alarm'),
        findsWidgets,
        reason: 'manuelNormaleDondur kaydi listede gorunmeli',
      );

      // initState -> addPostFrameCallback -> bildirimleriOkunduIsaretle()
      // ilk pump'tan SONRA calisir, bu yuzden bir pump daha gerekir.
      await tester.pump();
      expect(durum.okunmamisBildirimSayisi, 0);

      durum.dispose();
    },
  );
}
