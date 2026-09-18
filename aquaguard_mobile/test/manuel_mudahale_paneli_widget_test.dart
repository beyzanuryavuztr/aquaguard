// AquaGuard - ManuelMudahalePaneli Widget (Gorsel/Overflow) Testleri
//
// Demo modundaki rastgele senaryo zamanlamasina bagli kalmadan (bir zonun
// "belirsiz" ya da "tedavide" durumuna gelmesi saniyeler surebilir), bu
// panelin HER IKI gorunumunun de (tedavi secimi / tedavi durdurma) tasma
// (RenderFlex overflow) veya istisna olmadan cizildigini ve dogru
// butonlari gosterdigini dogrudan dogrular.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/widgets/manuel_mudahale_paneli.dart';

SensorOkuma _okuma({
  required TeshisDurumu durum,
  TedaviTuru tedaviAktif = TedaviTuru.yok,
  TikanmaTuru tur = TikanmaTuru.yok,
}) {
  return SensorOkuma(
    zaman: DateTime(2026, 9, 3, 12),
    zone: 1,
    ph: 7.0,
    ec: 1.2,
    orp: 300,
    turbidite: 15,
    debi: 2.5,
    deltaBasinc: 0.3,
    durum: durum,
    tikanmaTuru: tur,
    guven: 42,
    tedaviAktif: tedaviAktif,
    durulamaAktif: false,
  );
}

Widget _sarmala(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => UygulamaDurumu(),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets(
    'belirsiz durumda 3 tedavi secenegi ve yanlis alarm butonu tasmadan gosterilir',
    (tester) async {
      await tester.pumpWidget(
        _sarmala(
          ManuelMudahalePaneli(
            zonNumarasi: 1,
            okuma: _okuma(durum: TeshisDurumu.belirsiz),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Operatör Kontrolü Gerekiyor'), findsOneWidget);
      expect(find.text('Asit Dozlama'), findsOneWidget);
      expect(find.text('Klor Enjeksiyonu'), findsOneWidget);
      expect(find.text('Yüksek Basınçlı Yıkama'), findsOneWidget);
      expect(find.textContaining('Yanlış Alarm'), findsOneWidget);
    },
  );

  testWidgets('aktif tedavide sadece durdurma karti gosterilir, tasma olmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sarmala(
        ManuelMudahalePaneli(
          zonNumarasi: 1,
          okuma: _okuma(
            durum: TeshisDurumu.tespitEdildi,
            tedaviAktif: TedaviTuru.klorEnjeksiyon,
            tur: TikanmaTuru.biyolojik,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Operatör Müdahalesi'), findsOneWidget);
    expect(find.text('Tedaviyi Durdur'), findsOneWidget);
    expect(find.text('Asit Dozlama'), findsNothing);
  });

  testWidgets('normal durumda panel hicbir sey gostermez (SizedBox.shrink)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sarmala(
        ManuelMudahalePaneli(
          zonNumarasi: 1,
          okuma: _okuma(durum: TeshisDurumu.normal),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('Tedaviyi Durdur butonuna basinca onay diyalogu acilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sarmala(
        ManuelMudahalePaneli(
          zonNumarasi: 1,
          okuma: _okuma(
            durum: TeshisDurumu.tespitEdildi,
            tedaviAktif: TedaviTuru.asitDozlama,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tedaviyi Durdur'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
  });

  testWidgets('kimyasal tedavi baslatma onayinda 3 saniyelik geri sayim var, '
      'buton sure dolana kadar devre disi kalir', (tester) async {
    await tester.pumpWidget(
      _sarmala(
        ManuelMudahalePaneli(
          zonNumarasi: 1,
          okuma: _okuma(durum: TeshisDurumu.belirsiz),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asit Dozlama'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    // Geri sayim BASLAT metniyle birlikte gosterilmeli, buton devre disi.
    expect(find.text('Başlat (3)'), findsOneWidget);
    var buton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buton.onPressed, isNull);

    // Her saniye tik: sayac azalmali, buton HALA devre disi.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Başlat (2)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Başlat (1)'), findsOneWidget);

    // 3. saniye dolunca buton ETKINLESMELI, metin sade "Başlat" olmali.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Başlat'), findsOneWidget);
    buton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buton.onPressed, isNotNull);
  });

  testWidgets('Tedaviyi Durdur onayinda geri sayim YOK, buton hemen etkin', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sarmala(
        ManuelMudahalePaneli(
          zonNumarasi: 1,
          okuma: _okuma(
            durum: TeshisDurumu.tespitEdildi,
            tedaviAktif: TedaviTuru.asitDozlama,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tedaviyi Durdur'));
    await tester.pumpAndSettle();

    final buton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buton.onPressed, isNotNull);
    expect(find.text('Durdur'), findsOneWidget);
  });

  group('Titreşim geri bildirimi (Ayarlar > Titreşim Geri Bildirimi)', () {
    // Bu iki test, diger testlerin kullandigi _sarmala()'yi BILEREK
    // kullanmaz -- AyarlarProvider'a ihtiyac duyarlar (haptic kontrolu
    // icin), digerleri duymaz; mevcut 6 testi riske atmamak icin ayri
    // bir saracak fonksiyon.
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<List<String>> haptikleriYakala(
      WidgetTester tester,
      UygulamaDurumu durum,
    ) async {
      final yakalananlar = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            yakalananlar.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.ayarlarProvider),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ManuelMudahalePaneli(
                zonNumarasi: 1,
                okuma: _okuma(durum: TeshisDurumu.belirsiz),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Asit Dozlama'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.text('Başlat'));
      await tester.pump();
      await tester.pump();

      return yakalananlar;
    }

    testWidgets(
      'titresim ACIKKEN (varsayilan) kimyasal onay mediumImpact tetikler',
      (tester) async {
        final durum = UygulamaDurumu();

        final yakalananlar = await haptikleriYakala(tester, durum);

        expect(yakalananlar, contains('HapticFeedbackType.mediumImpact'));

        durum.dispose();
      },
    );

    testWidgets('titresim KAPATILINCA kimyasal onay HICBIR haptic tetiklemez', (
      tester,
    ) async {
      final durum = UygulamaDurumu();
      await durum.ayarlarProvider.titresimGeriBildirimiAyarla(false);

      final yakalananlar = await haptikleriYakala(tester, durum);

      expect(yakalananlar, isEmpty);

      durum.dispose();
    });
  });
}
