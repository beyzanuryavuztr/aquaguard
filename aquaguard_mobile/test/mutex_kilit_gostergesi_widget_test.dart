// AquaGuard - MutexKilitGostergesi Widget Testleri
//
// Firmware'deki mutex kuralinin (asit/klor/yikama kanallarindan ayni anda
// SADECE biri calisabilir) gorsel karsiliginin dogru kanali "aktif",
// digerlerini "kilitli" gosterdigini, hicbiri aktif degilken hicbirinin
// kilitli gorunmedigini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/widgets/mutex_kilit_gostergesi.dart';

void main() {
  testWidgets('hicbir tedavi aktif degilken hicbir kanal kilitli gorunmez', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MutexKilitGostergesi(aktifTedavi: TedaviTuru.yok),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('bir tedavi aktifken DIGER IKI kanal kilitli isaretlenir', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MutexKilitGostergesi(
            aktifTedavi: TedaviTuru.asitDozlama,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // Aktif olan (asit) HARIC diger 2 kanal (klor, yikama) kilitli olmali.
    expect(find.byIcon(Icons.lock), findsNWidgets(2));
  });
}
