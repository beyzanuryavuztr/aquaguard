// AquaGuard - ModelPerformansiEkrani Widget Testleri (Faz 1)
//
// Ekranin tasma/istisna olmadan cizildigini, 5 gorselin (Image.asset) ve
// durustluk cumlesinin (Katman 2 canli teshiste kullanilmaz) goründuğünü
// dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/screens/model_performansi_ekrani.dart';

void main() {
  testWidgets(
    'tasma/istisna olmadan cizilir, 5 gorsel ve durustluk cumlesi gorunur',
    (tester) async {
      // Butun gorselleri (InteractiveViewer icinde) kaydirmadan gormek icin
      // uzun bir yuzey -- ayni desen: tedavi_gecmisi_ekrani_widget_test.dart.
      await tester.binding.setSurfaceSize(const Size(500, 4500));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: ModelPerformansiEkrani()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('İki Katmanlı Karar Motoru'), findsOneWidget);
      expect(
        find.text(
          'Yapay zeka (Katman 2) yalnızca çevrimdışı doğrulama '
          'içindir, canlı teşhiste kullanılmaz.',
        ),
        findsOneWidget,
      );
      expect(find.text('Çapraz Doğrulama Doğruluğu'), findsOneWidget);
      expect(find.text('Karışıklık Matrisi'), findsOneWidget);
      expect(find.text('Sınıf Bazlı Performans'), findsOneWidget);
      expect(find.text('Özellik Önemi'), findsOneWidget);
      expect(find.text('Sensör Dağılımları'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(5));
    },
  );
}
