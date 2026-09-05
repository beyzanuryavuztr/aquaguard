// AquaGuard - AquaGuardTema Testleri (Oncelik 14)
//
// acikTema()'nin gecerli, ACIK parlaklikta bir ThemeData urettigini ve
// koyuTema()'nin hala KOYU kaldigini (regresyon olmadigini) dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/config/tema.dart';

void main() {
  test('acikTema() ACIK parlaklikta bir ColorScheme uretir', () {
    final tema = AquaGuardTema.acikTema();

    expect(tema.brightness, Brightness.light);
    expect(tema.colorScheme.primary, AquaGuardTema.vurguRenk);
  });

  test('koyuTema() KOYU parlaklikta kalir (regresyon kontrolu)', () {
    final tema = AquaGuardTema.koyuTema();

    expect(tema.brightness, Brightness.dark);
    expect(tema.colorScheme.primary, AquaGuardTema.vurguRenk);
  });

  test('acik ve koyu tema AYNI marka vurgu rengini kullanir', () {
    expect(
      AquaGuardTema.acikTema().colorScheme.primary,
      AquaGuardTema.koyuTema().colorScheme.primary,
    );
  });
}
