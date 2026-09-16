// AquaGuard - AksanRengi/Saha Modu Testleri
//
// Tema.dart'a eklenen aksan rengi + saha modu parametrelerinin doğru
// paletleri seçtiğini ve depolama round-trip'inin çalıştığını doğrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/config/tema.dart';
import 'package:aquaguard_mobile/models/aksan_rengi.dart';
import 'package:aquaguard_mobile/services/depolama_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('aksanPaletleri her AksanRengi degeri icin bir kayit tasir', () {
    for (final aksan in AksanRengi.values) {
      expect(aksanPaletleri.containsKey(aksan), isTrue);
    }
  });

  test('etiket her aksan icin bos olmayan bir metin doner', () {
    for (final aksan in AksanRengi.values) {
      expect(aksan.etiket, isNotEmpty);
    }
  });

  test('koyuTema/acikTema secilen aksanin primary rengini kullanir', () {
    final koyu = AquaGuardTema.koyuTema(aksan: AksanRengi.toprak);
    expect(koyu.colorScheme.primary, aksanPaletleri[AksanRengi.toprak]!.renk);

    final acik = AquaGuardTema.acikTema(aksan: AksanRengi.toprak);
    expect(acik.colorScheme.primary, aksanPaletleri[AksanRengi.toprak]!.renk);
  });

  test('varsayilan aksan teal ile mevcut marka rengini korur', () {
    final koyu = AquaGuardTema.koyuTema();
    expect(koyu.colorScheme.primary, const Color(0xFF00BFA6));
  });

  test('sahaModu acikken kart kenarligi kalinlasir', () {
    final normal = AquaGuardTema.koyuTema();
    final saha = AquaGuardTema.koyuTema(sahaModu: true);
    final normalKenar = (normal.cardTheme.shape as RoundedRectangleBorder)
        .side
        .width;
    final sahaKenar = (saha.cardTheme.shape as RoundedRectangleBorder).side
        .width;
    expect(sahaKenar, greaterThan(normalKenar));
  });

  test('DepolamaServisi aksanRengiGetir/Kaydet round-trip', () async {
    final depolama = DepolamaServisi();
    await depolama.aksanRengiKaydet(AksanRengi.toprak);
    final geri = await depolama.aksanRengiGetir();
    expect(geri, AksanRengi.toprak);
  });

  test('DepolamaServisi sahaModuGetir/Kaydet round-trip', () async {
    final depolama = DepolamaServisi();
    await depolama.sahaModuKaydet(true);
    final geri = await depolama.sahaModuGetir();
    expect(geri, isTrue);
  });
}
