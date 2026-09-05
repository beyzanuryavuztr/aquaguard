// AquaGuard - Onboarding Durumu Testleri (Oncelik 6)
//
// UygulamaDurumu.onboardingGoruldu'nun varsayilan olarak false oldugunu,
// onboardingiTamamla() ile kalici olarak true'ya donup yeniden acilista
// GERI YUKLENDIGINI dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('varsayilan olarak onboarding GORULMEMIS sayilir', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    expect(durum.onboardingGoruldu, isFalse);
    durum.dispose();
  });

  test('onboardingiTamamla, kalici olarak true yapar ve yeniden acilista korunur', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.onboardingiTamamla();
    expect(durum1.onboardingGoruldu, isTrue);
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.onboardingGoruldu, isTrue);
    durum2.dispose();
  });

  test('zaten tamamlanmis onboardingi tekrar tamamlamak hata vermez', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await durum.onboardingiTamamla();
    expect(() => durum.onboardingiTamamla(), returnsNormally);
    durum.dispose();
  });
}
