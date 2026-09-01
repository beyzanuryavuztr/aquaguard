// AquaGuard - Temel Duman (Smoke) Testi
//
// Tarla Secim Ekrani'nin, UygulamaDurumu Provider'i ile birlikte hatasiz
// cizildigini (build oldugunu) dogrular. Bilerek gercek MQTT baglantisini
// tetiklemiyoruz (baslat() cagirilmiyor) -- boylece test ag baglantisina
// bagimli olmadan, hizli ve tekrarlanabilir kalir.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/screens/tarla_secim_ekrani.dart';

void main() {
  testWidgets('Tarla Secim Ekrani baslik ve yukleniyor gostergesini gosterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UygulamaDurumu(),
        child: const MaterialApp(home: TarlaSecimEkrani()),
      ),
    );

    expect(find.text('AquaGuard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
