// AquaGuard - Oturum zaman asimi testleri (D3)
//
// Arka plandan uzun sure sonra donuste PIN'in yeniden istendigini, kisa
// surede donuste ISTENMEDIGINI ve PIN kapaliyken hicbir sey olmadigini
// dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/guvenlik_provider.dart';
import 'package:aquaguard_mobile/screens/pin_kilit_ekrani.dart';
import 'package:aquaguard_mobile/widgets/oturum_zaman_asimi.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final t0 = DateTime(2026, 9, 19, 12);

  test('PIN kapaliyken zaman asimi kilitlemez', () {
    final g = GuvenlikProvider();
    g.arkaplanaAlindi(simdi: t0);
    g.planaDonuldu(simdi: t0.add(const Duration(hours: 1)));
    expect(g.pinKilitliSuAn, isFalse);
    expect(g.zamanAsimiylaKilitlendi, isFalse);
  });

  group('PIN acikken', () {
    Future<GuvenlikProvider> acikGuvenlik() async {
      final g = GuvenlikProvider();
      // Soguk acilis kilidini acmis, oturumu kilitsiz bir kullanici.
      g.debugOturumuKilitsizYap();
      return g;
    }

    test('kisa arka plan suresi kilitlemez', () async {
      final g = await acikGuvenlik();
      g.arkaplanaAlindi(simdi: t0);
      g.planaDonuldu(simdi: t0.add(const Duration(minutes: 4)));
      expect(g.pinKilitliSuAn, isFalse);
    });

    test('zaman asimi asilinca yeniden kilitlenir', () async {
      final g = await acikGuvenlik();
      g.arkaplanaAlindi(simdi: t0);
      g.planaDonuldu(simdi: t0.add(const Duration(minutes: 5)));
      expect(g.pinKilitliSuAn, isTrue);
      expect(g.zamanAsimiylaKilitlendi, isTrue);
    });

    test('biyometrik acilis zaman asimi bayragini temizler', () async {
      final g = await acikGuvenlik();
      g.arkaplanaAlindi(simdi: t0);
      g.planaDonuldu(simdi: t0.add(const Duration(minutes: 6)));
      g.pinKilidiniBiyometrikIleAc();
      expect(g.pinKilitliSuAn, isFalse);
      expect(g.zamanAsimiylaKilitlendi, isFalse);
    });
  });

  testWidgets('zaman asimiyla kilitlenince PIN ekrani icerigin USTUNE biner', (
    tester,
  ) async {
    final g = GuvenlikProvider()..debugOturumuKilitsizYap();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: g,
        child: const MaterialApp(
          home: OturumZamanAsimi(child: Scaffold(body: Text('ana icerik'))),
        ),
      ),
    );
    expect(find.byType(PinKilitEkrani), findsNothing);

    g.arkaplanaAlindi(simdi: DateTime(2026, 9, 19, 12));
    g.planaDonuldu(simdi: DateTime(2026, 9, 19, 13));
    await tester.pump();

    expect(find.byType(PinKilitEkrani), findsOneWidget);
    expect(find.text('ana icerik'), findsOneWidget);
  });
}
