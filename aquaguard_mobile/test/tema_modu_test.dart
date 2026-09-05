// AquaGuard - TemaModu Testleri (Oncelik 14)
//
// Etiket/ThemeMode eslemesini ve isimden ayristirmanin (kalici depodan
// okurken) bozuk/eksik veriye karsi guvenli fallback davranisini dogrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/tema_modu.dart';

void main() {
  group('TemaModuX', () {
    test('her mod icin dogru ThemeMode eslesir', () {
      expect(TemaModu.koyu.flutterModu, ThemeMode.dark);
      expect(TemaModu.acik.flutterModu, ThemeMode.light);
      expect(TemaModu.sistem.flutterModu, ThemeMode.system);
    });

    test('her mod icin bos olmayan bir etiket doner', () {
      for (final modu in TemaModu.values) {
        expect(modu.etiket, isNotEmpty);
      }
    });

    test('isimdenAyristir gecerli bir isim icin dogru modu doner', () {
      expect(TemaModuX.isimdenAyristir('acik'), TemaModu.acik);
      expect(TemaModuX.isimdenAyristir('sistem'), TemaModu.sistem);
      expect(TemaModuX.isimdenAyristir('koyu'), TemaModu.koyu);
    });

    test('isimdenAyristir null veya bilinmeyen bir isim icin koyu doner', () {
      expect(TemaModuX.isimdenAyristir(null), TemaModu.koyu);
      expect(TemaModuX.isimdenAyristir('gecersiz_deger'), TemaModu.koyu);
    });
  });
}
