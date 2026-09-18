// AquaGuard - Temel Duman (Smoke) Testi
//
// Genel Bakis Ekrani'nin, UygulamaDurumu Provider'i ile birlikte hatasiz
// cizildigini (build oldugunu) dogrular. Bilerek gercek MQTT baglantisini
// tetiklemiyoruz (baslat() cagirilmiyor) -- boylece test ag baglantisina
// bagimli olmadan, hizli ve tekrarlanabilir kalir.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/genel_bakis_ekrani.dart';

void main() {
  testWidgets('Genel Bakis Ekrani baslik ve yukleniyor gostergesini gosterir',
      (WidgetTester tester) async {
    // GenelBakisEkrani, Faz "ekran migrasyonu" kapsaminda facade yerine
    // dogrudan CihazIletisimProvider/TarlaProvider/BakimProvider/
    // AktiviteBildirimProvider'i izler -- test agacinda da saglanmasi gerekir.
    final durum = UygulamaDurumu();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: durum),
          ChangeNotifierProvider.value(value: durum.cihazProvider),
          ChangeNotifierProvider.value(value: durum.tarlaProvider),
          ChangeNotifierProvider.value(value: durum.bakimProvider),
          ChangeNotifierProvider.value(value: durum.aktiviteProvider),
        ],
        child: const MaterialApp(home: GenelBakisEkrani()),
      ),
    );

    expect(find.text('AquaGuard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    durum.dispose();
  });
}
