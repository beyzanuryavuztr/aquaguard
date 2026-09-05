// AquaGuard - tikanmaTuruBilgisiGetir Testleri
//
// Her tikanma turunun HER YERDE ayni ikon+renkle temsil edildigi tek
// kaynak -- 3 turun de birbirinden FARKLI renk dondurdugunu dogrular
// (durum rengiyle karismasin diye ayri bir renk seti kullanilir).

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/widgets/tikanma_turu_ikonu.dart';

void main() {
  test('her tikanma turu farkli bir renkle temsil edilir', () {
    final renkler = TikanmaTuru.values
        .map((t) => tikanmaTuruBilgisiGetir(t).renk)
        .toSet();

    expect(renkler.length, TikanmaTuru.values.length);
  });

  test('yok turu notr bir renk/ikon doner', () {
    final bilgi = tikanmaTuruBilgisiGetir(TikanmaTuru.yok);
    expect(bilgi.renk, isNotNull);
    expect(bilgi.ikon, isNotNull);
  });
}
