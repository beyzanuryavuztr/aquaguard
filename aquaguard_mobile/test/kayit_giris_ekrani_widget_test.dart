// AquaGuard - KayitGirisEkrani Widget Testleri
//
// Gercek Firebase'e HIC cikmaz -- KimlikDogrulamaProvider'a sahte bir
// KimlikDogrulamaServisi enjekte edilir.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aquaguard_mobile/providers/kimlik_dogrulama_provider.dart';
import 'package:aquaguard_mobile/screens/kayit_giris_ekrani.dart';
import 'package:aquaguard_mobile/services/kimlik_dogrulama_servisi.dart';

class _SahteKimlikDogrulamaServisi implements KimlikDogrulamaServisi {
  KullaniciBilgisi? _kullanici;
  final bool basarisizMi;
  _SahteKimlikDogrulamaServisi({this.basarisizMi = false});

  @override
  KullaniciBilgisi? get mevcutKullanici => _kullanici;

  @override
  Stream<KullaniciBilgisi?> get kullaniciDegisiklikleri => const Stream.empty();

  @override
  Future<KullaniciBilgisi> kayitOl(String eposta, String sifre) async {
    if (basarisizMi) {
      throw const KimlikDogrulamaHatasi(
        'Bu e-posta adresiyle zaten bir hesap var.',
      );
    }
    _kullanici = KullaniciBilgisi(uid: 'u1', eposta: eposta);
    return _kullanici!;
  }

  @override
  Future<KullaniciBilgisi> girisYap(String eposta, String sifre) async {
    if (basarisizMi) {
      throw const KimlikDogrulamaHatasi('E-posta veya şifre hatalı.');
    }
    _kullanici = KullaniciBilgisi(uid: 'u1', eposta: eposta);
    return _kullanici!;
  }

  @override
  Future<void> cikisYap() async => _kullanici = null;
}

Widget _sarici(KimlikDogrulamaServisi servis) {
  return ChangeNotifierProvider(
    create: (_) => KimlikDogrulamaProvider(servis: servis),
    child: const MaterialApp(home: KayitGirisEkrani()),
  );
}

void main() {
  testWidgets('tasma/istisna olmadan cizilir, varsayilan Giris Yap modu', (
    tester,
  ) async {
    await tester.pumpWidget(_sarici(_SahteKimlikDogrulamaServisi()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Giriş Yap'), findsWidgets);
    expect(find.text('Şifre (Tekrar)'), findsNothing);
  });

  testWidgets('bos formla gonderilince dogrulama hatalari gosterilir', (
    tester,
  ) async {
    await tester.pumpWidget(_sarici(_SahteKimlikDogrulamaServisi()));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('E-posta girin'), findsOneWidget);
    expect(find.text('Şifre en az 6 karakter olmalı'), findsOneWidget);
  });

  testWidgets('gecerli bilgiyle basarili girişte hata gösterilmez', (
    tester,
  ) async {
    await tester.pumpWidget(_sarici(_SahteKimlikDogrulamaServisi()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-posta'),
      'test@aquaguard.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şifre'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('basarisiz giriste hata banner\'i gorunur', (tester) async {
    await tester.pumpWidget(
      _sarici(_SahteKimlikDogrulamaServisi(basarisizMi: true)),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-posta'),
      'test@aquaguard.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şifre'),
      '123456',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
  });

  testWidgets('Kayıt Ol moduna geçince Şifre (Tekrar) alanı görünür', (
    tester,
  ) async {
    await tester.pumpWidget(_sarici(_SahteKimlikDogrulamaServisi()));
    await tester.pump();

    await tester.tap(find.text('Hesabınız yok mu? Kayıt olun'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Şifre (Tekrar)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Kayıt Ol'), findsOneWidget);
  });

  testWidgets(
    'Kayıt modunda şifreler eşleşmezse dogrulama hatasi gosterilir',
    (tester) async {
      await tester.pumpWidget(_sarici(_SahteKimlikDogrulamaServisi()));
      await tester.pump();
      await tester.tap(find.text('Hesabınız yok mu? Kayıt olun'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'),
        'test@aquaguard.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Şifre'),
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Şifre (Tekrar)'),
        'farkli1',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kayıt Ol'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Şifreler eşleşmiyor'), findsOneWidget);
    },
  );

  testWidgets(
    '"Misafir olarak devam et" ile provider.girisGerekliMi false olur, '
    'ekran cokme yasamaz',
    (tester) async {
      final provider = KimlikDogrulamaProvider(
        servis: _SahteKimlikDogrulamaServisi(),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: KayitGirisEkrani()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Misafir olarak devam et'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(provider.girisGerekliMi, isFalse);
    },
  );
}
