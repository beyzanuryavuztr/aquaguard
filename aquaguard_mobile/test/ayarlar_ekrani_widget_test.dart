// AquaGuard - AyarlarEkrani Widget Testleri (Asama 7 genislemesi)
//
// Yeni bolumlerin (4 bildirim anahtari, Zon Isimleri, Sensor Kalibrasyonu,
// Esik Degerleri -- hepsi salt-okunur kalibrasyon/esik disinda) tasma/
// istisna olmadan cizildigini ve zon takma adi verme akisinin gercekten
// UygulamaDurumu'nu guncelledigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/l10n/app_localizations.dart';
import 'package:aquaguard_mobile/models/yazi_boyutu.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/ayarlar_ekrani.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpUzunYuzeyle(
    WidgetTester tester,
    UygulamaDurumu durum,
  ) async {
    // 9000 (once 4600'du, ondan once 4200/3900): kategoriler artik 5
    // katlanir AyarlarKategorisi grubuna toplandi (2026-09-25) -- bu test
    // yardimcisi HEPSINI acar (asagida), yani ListView'in sliver lazy
    // layout'u (RenderSliverList) artik 15 bolumun TAMAMINI ayni anda
    // layout etmek zorunda + 5 ExpansionTile baslik/kenar payi. Yukseklik
    // buna gore buyutuldu -- sadece kirpma/tasma alani buyutulmedi.
    await tester.binding.setSurfaceSize(const Size(500, 9000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.ayarlarProvider),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
          ChangeNotifierProvider.value(value: durum.tarlaProvider),
          ChangeNotifierProvider.value(value: durum.bakimProvider),
          ChangeNotifierProvider.value(value: durum.guvenlikProvider),
        ],
        // AyarlarEkrani'nin Görünüm bolumu AppLocalizations kullanir (i18n
        // pilotu, bkz. lib/l10n/app_tr.arb) -- delegate'ler verilmezse
        // "No AppLocalizations found" istisnasiyla cokerdi. `locale`
        // ACIKCA 'tr' verilir -- main.dart'ta HER ZAMAN durum.uygulamaDili
        // uzerinden acikca verilir (bkz. o dosyanin dosya basi notu),
        // ACIK verilmezse test ortami varsayilani (Ingilizce) kullanilir
        // ve bu kartin metinleri BEKLENMEDIK sekilde Ingilizce cikardi.
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AyarlarEkrani(),
        ),
      ),
    );
    await tester.pump();
    // ACIMASIZ DENETIM (2026-09-25): bolumler artik 5 katlanir ust
    // kategoriye (AyarlarKategorisi/ExpansionTile) gruplandi, varsayilan
    // KAPALI -- asagidaki testler icerigin kendisini dogruladigi icin,
    // hepsini asagida ACIYORUZ (collapse/expand davranisinin kendisi ayri
    // bir testte -- 'kategoriler varsayilan kapali...' -- dogrulaniyor).
    // pumpAndSettle GUVENLI -- bu ekranda (Genel Bakış'in aksine) surekli
    // tekrarlanan bir animasyon yok, ExpansionTile'in acilma gecisinin
    // TAMAMEN bitmesini bekliyoruz ki alttaki kategorinin nihai konumuna
    // gore yapilan sonraki dokunuslar doGru widget'i hedeflesin.
    for (final kategori in [
      'Hesap ve Profil',
      'Bağlantı',
      'Sistem Yapılandırması',
      'Bildirim ve Güvenlik',
      'Diğer',
    ]) {
      await tester.tap(find.text(kategori));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'kategoriler varsayilan kapali gelir, basliga dokununca icerik acilir '
    '(ACIMASIZ DENETIM 2026-09-25: eskiden 15 bolum tek duz listede acikti)',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await tester.binding.setSurfaceSize(const Size(500, 4600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: durum),
            ChangeNotifierProvider.value(value: durum.ayarlarProvider),
            ChangeNotifierProvider.value(value: durum.cihazProvider),
            ChangeNotifierProvider.value(value: durum.tarlaProvider),
            ChangeNotifierProvider.value(value: durum.bakimProvider),
            ChangeNotifierProvider.value(value: durum.guvenlikProvider),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: AyarlarEkrani(),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // 5 kategori basligi hemen gorunur olmali...
      expect(find.text('Hesap ve Profil'), findsOneWidget);
      expect(find.text('Bağlantı'), findsOneWidget);
      expect(find.text('Sistem Yapılandırması'), findsOneWidget);
      expect(find.text('Bildirim ve Güvenlik'), findsOneWidget);
      expect(find.text('Diğer'), findsOneWidget);
      // ...ama ic icerik (orn. Kullanıcı Profili'nin İsim alani) KAPALI
      // oldugu icin agac icinde OLMAMALI.
      expect(find.text('İsim'), findsNothing);
      expect(find.text('Zon İsimleri'), findsNothing);

      await tester.tap(find.text('Hesap ve Profil'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Sadece dokunulan kategori acilir -- digerleri hala kapali.
      expect(find.text('İsim'), findsOneWidget);
      expect(find.text('Zon İsimleri'), findsNothing);

      durum.dispose();
    },
  );

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
      expect(find.text('Kullanıcı Profili'), findsOneWidget);
      expect(find.text('İsim'), findsOneWidget);

      durum.dispose();
    },
  );

  testWidgets(
    'kullanici profili doldurulup Profili Kaydet\'e dokununca UygulamaDurumu guncellenir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await pumpUzunYuzeyle(tester, durum);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'İsim'),
        'Beyzanur',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'İşletme / Çiftlik Adı'),
        'Ana Çiftlik',
      );
      await tester.tap(find.text('Profili Kaydet'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(durum.kullaniciProfili.isim, 'Beyzanur');
      expect(durum.kullaniciProfili.isletmeAdi, 'Ana Çiftlik');

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

  testWidgets(
    'Titreşim Geri Bildirimi anahtari varsayilan ACIK, dokununca kapanir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await pumpUzunYuzeyle(tester, durum);

      expect(durum.titresimAktif, isTrue);
      expect(find.text('Titreşim Geri Bildirimi'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Titreşim Geri Bildirimi'),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(durum.titresimAktif, isFalse);

      durum.dispose();
    },
  );

  testWidgets(
    'Yazı Boyutu segmenti varsayilan Normal, Büyük secilince guncellenir',
    (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();

      await pumpUzunYuzeyle(tester, durum);

      expect(durum.yaziBoyutu, YaziBoyutu.normal);
      expect(find.text('Yazı Boyutu'), findsOneWidget);

      await tester.tap(find.text('Büyük'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(durum.yaziBoyutu, YaziBoyutu.buyuk);

      durum.dispose();
    },
  );
}
