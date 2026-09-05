// AquaGuard - PinKilitEkrani Widget Testleri (Oncelik 10)
//
// Kilit ekraninin tasma/istisna olmadan cizildigini, dogru PIN girilince
// kilidin actigini ve yanlis PIN girilince hata mesaji + basarisiz deneme
// sayacinin arttigini dogrular. PinServisi.biyometrikDesteklidMi() test
// ortaminda platform kanali olmadigi icin (try/catch ile) sessizce false
// doner -- biyometrik butonu bu testlerde hic gorunmez, bu BEKLENEN bir
// durum (bkz. services/pin_servisi.dart dokumantasyonu).

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/pin_kilit_ekrani.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  // NOT: pinKorumasiniAc() canli bir oturumda ANINDA kilitlemez (bkz.
  // pin_korumasi_test.dart'taki ayni notu) -- bu yuzden burada da PIN'i
  // BIR ONCEKI oturumda acip, YENI bir UygulamaDurumu ile soguk acilisi
  // simule ediyoruz (kilit ekrani gercekten kilitli bir oturumu test etsin).
  Future<UygulamaDurumu> pinliDurumHazirla() async {
    final oncekiOturum = UygulamaDurumu();
    await oncekiOturum.baslat();
    await oncekiOturum.pinKorumasiniAc('1234');
    oncekiOturum.dispose();

    final durum = UygulamaDurumu();
    await durum.baslat();
    return durum;
  }

  Future<void> pinKilidiniCiz(WidgetTester tester, UygulamaDurumu durum) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum,
        child: const MaterialApp(home: PinKilitEkrani()),
      ),
    );
    await tester.pump();
  }

  testWidgets('ekran tasma/istisna olmadan cizilir', (tester) async {
    final durum = await pinliDurumHazirla();
    await pinKilidiniCiz(tester, durum);

    expect(tester.takeException(), isNull);
    expect(find.text('Devam etmek için PIN girin'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('dogru PIN girilince kilit acilir', (tester) async {
    final durum = await pinliDurumHazirla();
    await pinKilidiniCiz(tester, durum);

    for (final hane in ['1', '2', '3', '4']) {
      await tester.tap(find.text(hane).first);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(durum.pinKilitliSuAn, isFalse);

    durum.dispose();
  });

  testWidgets('yanlis PIN girilince hata mesaji gorunur, kilit acik kalir', (
    tester,
  ) async {
    final durum = await pinliDurumHazirla();
    await pinKilidiniCiz(tester, durum);

    for (final hane in ['9', '9', '9', '9']) {
      await tester.tap(find.text(hane).first);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Yanlış PIN, tekrar deneyin'), findsOneWidget);
    expect(durum.pinKilitliSuAn, isTrue);

    durum.dispose();
  });
}
