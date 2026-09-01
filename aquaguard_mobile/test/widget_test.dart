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
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UygulamaDurumu(),
        child: const MaterialApp(home: GenelBakisEkrani()),
      ),
    );

    expect(find.text('AquaGuard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
