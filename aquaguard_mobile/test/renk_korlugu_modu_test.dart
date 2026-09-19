// AquaGuard - Renk korlugu modu testleri (C4)
//
// Modun durum renklerini degistirdigini, kalici oldugunu ve Ayarlar'daki
// anahtarin gercekten calistigini dogrular. DurumRenkleri statik oldugu
// icin her test sonunda varsayilana dondurulur.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/providers/ayarlar_provider.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/widgets/ayarlar/gorunum_dil_karti.dart';
import 'package:aquaguard_mobile/widgets/durum_renkleri.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    DurumRenkleri.renkKorluguModu = false;
  });

  test('mod acikken kirmizi/yesil yerine mavi/turuncu palet kullanilir', () {
    final varsayilan = [
      DurumRenkleri.normal,
      DurumRenkleri.belirsiz,
      DurumRenkleri.tespitEdildi,
      DurumRenkleri.tedaviAktif,
    ];
    DurumRenkleri.renkKorluguModu = true;
    final korlukUyumlu = [
      DurumRenkleri.normal,
      DurumRenkleri.belirsiz,
      DurumRenkleri.tespitEdildi,
      DurumRenkleri.tedaviAktif,
    ];

    for (var i = 0; i < varsayilan.length; i++) {
      expect(korlukUyumlu[i], isNot(varsayilan[i]));
    }
    // 4 durum renginin hepsi birbirinden ayri kalmali.
    expect(korlukUyumlu.toSet().length, 4);
  });

  test('tercih kalici: yeni AyarlarProvider ayni modu yukler', () async {
    await AyarlarProvider().renkKorluguModuAyarla(true);
    DurumRenkleri.renkKorluguModu = false;

    final yeni = AyarlarProvider();
    await yeni.baslat();
    expect(yeni.renkKorluguModu, isTrue);
    expect(DurumRenkleri.renkKorluguModu, isTrue);
  });

  testWidgets('Ayarlar anahtari modu acar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum.ayarlarProvider,
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: GorunumDilKartlari()),
          ),
        ),
      ),
    );
    expect(DurumRenkleri.renkKorluguModu, isFalse);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Renk Körlüğü Uyumlu Renkler'),
    );
    await tester.pump();
    await tester.pump();

    expect(durum.ayarlarProvider.renkKorluguModu, isTrue);
    expect(DurumRenkleri.renkKorluguModu, isTrue);
    durum.dispose();
  });
}
