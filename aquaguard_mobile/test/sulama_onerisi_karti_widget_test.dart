// AquaGuard - SulamaOnerisiKarti Widget Testleri (Faz 4)
//
// GPS'siz ciftlikte agin HIC cagrilmadigini (davet metni gosterildigini),
// GPS'li ciftlikte MockClient uzerinden gelen tahmine gore dogru oneri
// metninin goruldugunu ve bitki turu secicinin TarlaProvider'i dogru
// guncelledigini dogrular. Gercek aga HIC cikmaz.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/bitki_turu.dart';
import 'package:aquaguard_mobile/models/tarla.dart';
import 'package:aquaguard_mobile/providers/tarla_provider.dart';
import 'package:aquaguard_mobile/widgets/sulama_onerisi_karti.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const gpsizTarla = Tarla(
    id: 't1',
    ad: 'Test Çiftlik',
    zonNumaralari: [1, 2],
  );

  const gpsliTarla = Tarla(
    id: 't2',
    ad: 'GPS\'li Çiftlik',
    zonNumaralari: [1, 2],
    enlem: 37.16,
    boylam: 38.79,
  );

  Future<TarlaProvider> providerOlustur() async {
    final provider = TarlaProvider();
    await provider.baslat();
    return provider;
  }

  testWidgets('GPS yoksa ag HIC cagrilmaz, davet metni gosterilir', (
    tester,
  ) async {
    var cagrildiMi = false;
    final istemci = MockClient((request) async {
      cagrildiMi = true;
      return http.Response('{}', 200);
    });
    final provider = await providerOlustur();

    await tester.pumpWidget(
      ChangeNotifierProvider<TarlaProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: SulamaOnerisiKarti(
              tarla: gpsizTarla,
              testIstemci: istemci,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(cagrildiMi, isFalse);
    expect(find.textContaining('GPS konumu'), findsOneWidget);
  });

  testWidgets(
    'GPS varsa MockClient yanitina gore dogru oneri metni gosterilir',
    (tester) async {
      final istemci = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-09-25', '2026-09-26', '2026-09-27'],
              'temperature_2m_max': [28.0, 30.0, 27.0],
              'temperature_2m_min': [16.0, 17.0, 15.0],
              'precipitation_probability_max': [10, 80, 20],
              'precipitation_sum': [0.0, 12.0, 0.0],
            },
          }),
          200,
        );
      });
      final provider = await providerOlustur();

      await tester.pumpWidget(
        ChangeNotifierProvider<TarlaProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SulamaOnerisiKarti(
                tarla: gpsliTarla,
                testIstemci: istemci,
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // yukleniyor
      await tester.pump(const Duration(milliseconds: 100)); // Future tamamlanir

      expect(tester.takeException(), isNull);
      // Yarin (2026-09-26) yagis ihtimali %80 -- erteleme onerilmeli.
      // ("%80" hem ust bilgi satirinda hem oneri mesaji icinde gorunur.)
      expect(find.textContaining('%80'), findsWidgets);
      expect(find.textContaining('erteley'), findsOneWidget);
    },
  );

  testWidgets('ag hatasinda ekran COKMEZ, "alinamadi" mesaji gosterilir', (
    tester,
  ) async {
    final istemci = MockClient((request) async {
      return http.Response('hata', 500);
    });
    final provider = await providerOlustur();

    await tester.pumpWidget(
      ChangeNotifierProvider<TarlaProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: SulamaOnerisiKarti(
              tarla: gpsliTarla,
              testIstemci: istemci,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('alınamadı'), findsOneWidget);
  });

  testWidgets('bitki turu secilince TarlaProvider guncellenir', (
    tester,
  ) async {
    final istemci = MockClient((request) async => http.Response('{}', 200));
    final provider = await providerOlustur();
    await provider.tarlaEkle(gpsizTarla);

    await tester.pumpWidget(
      ChangeNotifierProvider<TarlaProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: SulamaOnerisiKarti(
              tarla: gpsizTarla,
              testIstemci: istemci,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(bitkiTuruEtiketi(BitkiTuru.sebze)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final guncelTarla = provider.tarlalar.firstWhere((t) => t.id == 't1');
    expect(guncelTarla.bitkiTuru, BitkiTuru.sebze);
  });
}
