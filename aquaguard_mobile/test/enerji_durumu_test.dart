// AquaGuard - EnerjiDurumu Testleri
//
// Simule pil yuzdesi formulunun deterministik oldugunu (ayni gun ayni
// deger) ve dongu boyunca esigin ALTINA da inebildigini (dusuk pil
// bildiriminin gercekten tetiklenebilmesi icin sart) dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/enerji_durumu.dart';

void main() {
  test('ayni tarih icin her zaman ayni pil yuzdesini doner (deterministik)', () {
    final tarih = DateTime(2026, 9, 10);
    final birinci = EnerjiDurumu.pilYuzdesiHesapla(simdi: tarih);
    final ikinci = EnerjiDurumu.pilYuzdesiHesapla(simdi: tarih);
    expect(birinci, ikinci);
  });

  test('10 gunluk dongu icinde esigin altina inen en az bir gun vardir', () {
    final t0 = DateTime(2026, 1, 1);
    final degerler = List.generate(
      10,
      (i) => EnerjiDurumu.pilYuzdesiHesapla(simdi: t0.add(Duration(days: i))),
    );

    expect(
      degerler.any((d) => d < EnerjiDurumu.dusukPilEsigi),
      isTrue,
      reason: 'dusuk pil bildiriminin test edilebilmesi icin gerekli',
    );
  });

  test('pil yuzdesi 0-100 araliginin disina cikmaz', () {
    for (var i = 0; i < 30; i++) {
      final deger = EnerjiDurumu.pilYuzdesiHesapla(
        simdi: DateTime(2026, 1, 1).add(Duration(days: i)),
      );
      expect(deger, inInclusiveRange(0, 100));
    }
  });
}
