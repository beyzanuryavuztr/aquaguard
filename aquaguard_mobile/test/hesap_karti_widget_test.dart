// AquaGuard - HesapKarti Widget Testleri

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aquaguard_mobile/providers/kimlik_dogrulama_provider.dart';
import 'package:aquaguard_mobile/services/kimlik_dogrulama_servisi.dart';
import 'package:aquaguard_mobile/widgets/ayarlar/hesap_karti.dart';

class _SahteKimlikDogrulamaServisi implements KimlikDogrulamaServisi {
  KullaniciBilgisi? _kullanici;

  @override
  KullaniciBilgisi? get mevcutKullanici => _kullanici;

  @override
  Stream<KullaniciBilgisi?> get kullaniciDegisiklikleri => const Stream.empty();

  @override
  Future<KullaniciBilgisi> kayitOl(String eposta, String sifre) async {
    _kullanici = KullaniciBilgisi(uid: 'u1', eposta: eposta);
    return _kullanici!;
  }

  @override
  Future<KullaniciBilgisi> girisYap(String eposta, String sifre) async {
    _kullanici = KullaniciBilgisi(uid: 'u1', eposta: eposta);
    return _kullanici!;
  }

  @override
  Future<void> cikisYap() async => _kullanici = null;
}

void main() {
  testWidgets('oturum acik e-postayi gosterir, Cikis Yap ile temizlenir', (
    tester,
  ) async {
    final provider = KimlikDogrulamaProvider(
      servis: _SahteKimlikDogrulamaServisi(),
    );
    await provider.girisYap('ciftci@aquaguard.com', '123456');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: HesapKarti())),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('ciftci@aquaguard.com'), findsOneWidget);

    await tester.tap(find.text('Çıkış Yap'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Misafir olarak kullanılıyor'), findsOneWidget);
  });
}
