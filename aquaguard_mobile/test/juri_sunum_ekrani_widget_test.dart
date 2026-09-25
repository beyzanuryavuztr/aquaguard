// AquaGuard - JuriSunumEkrani Widget Testleri (Faz 4)
//
// Ekranin tasma/istisna olmadan cizildigini, Ileri/Geri ile adimlar
// arasinda gezinmenin calistigini ve bir "Bu Adımı Tetikle" butonuna
// basinca UygulamaDurumu.demoSenaryosuTetikle'nin gercekten cagrildigini
// (aktivite gecmisine kayit dustugunu) dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/sunum_adimi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/ana_kabuk.dart';
import 'package:aquaguard_mobile/screens/juri_sunum_ekrani.dart';

// AnaKabuk'un IndexedStack'i TUM sekmeleri (Ayarlar dahil) hemen kurar --
// Ayarlar'daki GorunumDilKarti (i18n pilot ekrani) AppLocalizations.of(context)!
// cagirir, bu yuzden AnaKabuk'u iceren her test localizationsDelegates
// saglamali (bkz. giris_ekrani_widget_test.dart ayni desen).
Widget _uygulamaSarici(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tasma/istisna olmadan cizilir, ilk adim gorunur', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
        ],
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adım 1 / ${sunumAdimlari.length}'), findsOneWidget);
    expect(find.text(sunumAdimlari.first.baslik), findsOneWidget);
    // Ilk adimin tetikleme senaryosu yok -- buton gorunmemeli.
    expect(find.text('Bu Adımı Tetikle'), findsNothing);

    durum.dispose();
  });

  testWidgets('İleri ile 2. adıma geçilince tetikleme butonu görünür', (
    tester,
  ) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
        ],
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('İleri'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adım 2 / ${sunumAdimlari.length}'), findsOneWidget);
    expect(find.text(sunumAdimlari[1].baslik), findsOneWidget);
    expect(find.text('Bu Adımı Tetikle'), findsOneWidget);

    durum.dispose();
  });

  testWidgets('Geri ile önceki adıma dönülür', (tester) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
        ],
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('İleri'));
    await tester.pump();
    await tester.tap(find.text('Geri'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Adım 1 / ${sunumAdimlari.length}'), findsOneWidget);

    durum.dispose();
  });

  testWidgets(
    '"Bu Adımı Tetikle" butonuna basınca demoSenaryosuTetikle çağrılır',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final oncekiUzunluk = durum.aktiviteGecmisi.length;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
          ],
          child: const MaterialApp(home: JuriSunumEkrani()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('İleri')); // 2. adım -- Sağlıklı Sistem
      await tester.pump();
      await tester.tap(find.text('Bu Adımı Tetikle'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(durum.aktiviteGecmisi.length, greaterThan(oncekiUzunluk));

      durum.dispose();
    },
  );

  testWidgets(
    '"Bu Adımı Tetikle" basınca ekranda görünür bir onay belirir '
    '(ruthless audit: SnackBar bu ekranda bastırıldığı için buton hiçbir '
    'görsel değişiklik yapmıyormuş gibi görünüyordu)',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
          ],
          child: const MaterialApp(home: JuriSunumEkrani()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('İleri')); // 2. adım -- Sağlıklı Sistem
      await tester.pump();
      expect(
        find.textContaining('Tetiklendi'),
        findsNothing, // henuz basilmadi
      );

      await tester.tap(find.text('Bu Adımı Tetikle'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Tetiklendi'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets('son adımda İleri butonu devre dışı kalır', (tester) async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
        ],
        child: const MaterialApp(home: JuriSunumEkrani()),
      ),
    );
    await tester.pump();

    for (var i = 0; i < sunumAdimlari.length - 1; i++) {
      await tester.tap(find.text('İleri'));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    expect(
      find.text('Adım ${sunumAdimlari.length} / ${sunumAdimlari.length}'),
      findsOneWidget,
    );
    final bittiButonu = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Bitti'),
    );
    expect(bittiButonu.onPressed, isNull);

    durum.dispose();
  });

  testWidgets(
    'AnaKabuk uzerine PUSH edilmisken canli bildirim banner olarak '
    'gosterilmez (Geri/Ileri butonlarinin ustune binmesin diye); '
    'geri donulunce sonraki bildirim yine gosterilir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
            ChangeNotifierProvider.value(value: durum.tarlaProvider),
            ChangeNotifierProvider.value(value: durum.bakimProvider),
            ChangeNotifierProvider.value(value: durum.aktiviteProvider),
            ChangeNotifierProvider.value(value: durum.ayarlarProvider),
          ],
          child: _uygulamaSarici(const AnaKabuk()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(builder: (_) => const JuriSunumEkrani()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jüri Sunum Modu'), findsOneWidget);

      // Kabuk hala monteli (IndexedStack) ama artik GUNCEL rota degil --
      // bu bildirim banner olarak GORUNMEMELI.
      durum.aktiviteProvider.aktiviteKaydiEkle(
        AktiviteKaydi(
          zaman: DateTime.now(),
          zone: 1,
          mesaj: 'Test: kabuk arka plandayken gelen bildirim',
          tur: AktiviteTuru.tespit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(
        find.text('Test: kabuk arka plandayken gelen bildirim'),
        findsNothing,
      );
      // Yine de kalici gecmise/rozete islenmis olmali -- sadece toast
      // bastirildi, veri kaybolmadi.
      expect(
        durum.aktiviteProvider.bildirimGecmisi.any(
          (k) => k.mesaj == 'Test: kabuk arka plandayken gelen bildirim',
        ),
        isTrue,
      );

      // Jüri Sunum Modu'ndan geri donulunce Kabuk yeniden GUNCEL rota olur.
      // pumpAndSettle DEGIL: alttaki Genel Bakış (ZonSemasi nabiz animasyonu)
      // surekli calisiyor, asla "durulmaz" (bkz. giris_ekrani_widget_test.dart
      // ayni not).
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      durum.aktiviteProvider.aktiviteKaydiEkle(
        AktiviteKaydi(
          zaman: DateTime.now(),
          zone: 1,
          mesaj: 'Test: kabuk guncel rotadayken gelen bildirim',
          tur: AktiviteTuru.tespit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // findsOneWidget DEGIL: mesaj hem banner'da (toast) hem Genel
      // Bakış'in "Son Aktiviteler" listesinde (kalici) ayni anda gorunur --
      // burada asil kontrol edilen, banner'in GERCEKTEN gosterildigi.
      expect(
        find.descendant(
          of: find.byType(MaterialBanner),
          matching: find.text('Test: kabuk guncel rotadayken gelen bildirim'),
        ),
        findsOneWidget,
      );

      durum.dispose();
    },
  );

  testWidgets(
    'Genel Bakış\'ta ZATEN gösterilmekte olan bir banner, Jüri Sunum '
    'Modu\'na geçildiği an temizlenir (suresi dolmasini beklemez)',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
            ChangeNotifierProvider.value(value: durum.tarlaProvider),
            ChangeNotifierProvider.value(value: durum.bakimProvider),
            ChangeNotifierProvider.value(value: durum.aktiviteProvider),
            ChangeNotifierProvider.value(value: durum.ayarlarProvider),
          ],
          child: _uygulamaSarici(const AnaKabuk()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Kabuk hala GUNCEL rotadayken bir bildirim gelir -- banner
      // gosterilir (suresi 4 sn, henuz KAPANMAMIS olacak).
      durum.aktiviteProvider.aktiviteKaydiEkle(
        AktiviteKaydi(
          zaman: DateTime.now(),
          zone: 1,
          mesaj: 'Test: gecis aninda hala gosterilen bildirim',
          tur: AktiviteTuru.tespit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.descendant(
          of: find.byType(MaterialBanner),
          matching: find.text('Test: gecis aninda hala gosterilen bildirim'),
        ),
        findsOneWidget,
      );

      // Banner suresi DOLMADAN (4 sn) Jüri Sunum Modu'na gecilir.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(builder: (_) => const JuriSunumEkrani()),
      );
      await tester.pump();
      // Banner'in kapanma animasyonunun (clearMaterialBanners) TAMAMEN
      // bitmesini bekle -- pumpAndSettle DEGIL (Genel Bakış'taki nabiz
      // animasyonu asla durulmaz), sabit sureli birkac pump yeterli.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Jüri Sunum Modu'), findsOneWidget);
      // Eski banner, suresi dolmamis olsa da ARTIK GORUNMEMELI -- ekran
      // acilir acilmaz temizlenir.
      expect(
        find.text('Test: gecis aninda hala gosterilen bildirim'),
        findsNothing,
      );

      durum.dispose();
    },
  );
}
