// AquaGuard - ManuelMudahalePaneli Widget (Gorsel/Overflow) Testleri
//
// Demo modundaki rastgele senaryo zamanlamasina bagli kalmadan (bir zonun
// "belirsiz" ya da "tedavide" durumuna gelmesi saniyeler surebilir), bu
// panelin HER IKI gorunumunun de (tedavi secimi / tedavi durdurma) tasma
// (RenderFlex overflow) veya istisna olmadan cizildigini ve dogru
// butonlari gosterdigini dogrudan dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  testWidgets('belirsiz durumda 3 tedavi secenegi ve yanlis alarm butonu tasmadan gosterilir', (
    tester,
  ) async {
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
  });

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
}
