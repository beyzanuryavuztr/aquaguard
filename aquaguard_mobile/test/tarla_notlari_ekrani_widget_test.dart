// AquaGuard - TarlaNotlariEkrani ve TarlaProfilKarti Widget Testleri
//
// Not ekleme/silme akisinin ve profil kartinin (fotografli/fotografsiz)
// tasma veya istisna olmadan calistigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/tarla.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/tarla_notlari_ekrani.dart';
import 'package:aquaguard_mobile/widgets/tarla_profil_karti.dart';

Widget _sarmala(UygulamaDurumu durum, Widget child) {
  return ChangeNotifierProvider.value(
    value: durum,
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TarlaNotlariEkrani', () {
    testWidgets('bos durumda "henüz not eklenmedi" gosterir, tasma olmaz', (
      tester,
    ) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final tarla = durum.tarlalar.first;

      await tester.pumpWidget(_sarmala(durum, TarlaNotlariEkrani(tarla: tarla)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Henüz not eklenmedi.'), findsOneWidget);

      durum.dispose();
    });

    testWidgets('metin girip ekle butonuna basinca not listeye eklenir', (
      tester,
    ) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final tarla = durum.tarlalar.first;

      await tester.pumpWidget(_sarmala(durum, TarlaNotlariEkrani(tarla: tarla)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Yeni test notu');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Yeni test notu'), findsOneWidget);
      expect(durum.tarlaNotlari(tarla.id).length, 1);

      durum.dispose();
    });

    testWidgets('sil ikonuna basinca not kaldirilir', (tester) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final tarla = durum.tarlalar.first;
      await durum.notEkle(tarla.id, 'Silinecek not');

      await tester.pumpWidget(_sarmala(durum, TarlaNotlariEkrani(tarla: tarla)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Silinecek not'), findsNothing);
      expect(durum.tarlaNotlari(tarla.id), isEmpty);

      durum.dispose();
    });
  });

  group('TarlaProfilKarti', () {
    testWidgets('fotografsiz durumda "fotoğraf ekle" ipucu gosterir, tasma olmaz', (
      tester,
    ) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      const tarla = Tarla(
        id: 'tarla-test',
        ad: 'Test Tarlası',
        zonNumaralari: [1],
        konum: 'Test Konumu',
        aciklama: 'Test açıklaması',
      );

      await tester.pumpWidget(
        _sarmala(
          durum,
          Scaffold(body: SingleChildScrollView(child: TarlaProfilKarti(tarla: tarla))),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tarla Fotoğrafı Ekle'), findsOneWidget);
      expect(find.text('Test Konumu'), findsOneWidget);
      expect(find.text('Test açıklaması'), findsOneWidget);

      durum.dispose();
    });

    testWidgets('konum/aciklama olmadan da tasma olmadan cizilir', (
      tester,
    ) async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      const tarla = Tarla(id: 'tarla-bos', ad: 'Boş Tarla', zonNumaralari: [1]);

      await tester.pumpWidget(
        _sarmala(
          durum,
          Scaffold(body: SingleChildScrollView(child: TarlaProfilKarti(tarla: tarla))),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      durum.dispose();
    });
  });
}
