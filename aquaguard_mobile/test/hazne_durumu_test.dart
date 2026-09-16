// AquaGuard - HazneDurumu Testleri

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/hazne_durumu.dart';

void main() {
  test('etiket her hazne turu icin bos olmayan bir metin doner', () {
    for (final tur in HazneTuru.values) {
      expect(tur.etiket, isNotEmpty);
    }
  });

  test('dusukSeviye %20 altinda true doner', () {
    const durum = HazneDurumu(tur: HazneTuru.asit, dolulukYuzdesi: 15);
    expect(durum.dusukSeviye, isTrue);
  });

  test('dusukSeviye %20 ve ustunde false doner', () {
    const durum = HazneDurumu(tur: HazneTuru.klor, dolulukYuzdesi: 20);
    expect(durum.dusukSeviye, isFalse);
  });
}
