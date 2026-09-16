// AquaGuard - Tarla Modeli GPS Alanlari Testleri (enlem/boylam, sema v2)

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/tarla.dart';

void main() {
  test('varsayilan olarak GPS konumu yok', () {
    const tarla = Tarla(id: 't1', ad: 'Test Tarla', zonNumaralari: [1]);
    expect(tarla.gpsKonumuVarMi, isFalse);
  });

  test('ikisi de ayarlaninca GPS konumu var sayilir', () {
    const tarla = Tarla(
      id: 't1',
      ad: 'Test Tarla',
      zonNumaralari: [1],
      enlem: 37.1591,
      boylam: 38.7969,
    );
    expect(tarla.gpsKonumuVarMi, isTrue);
  });

  test('kopyalaVeGuncelle: konum metni ile GPS konumu BIRBIRINDEN BAGIMSIZDIR', () {
    const tarla = Tarla(
      id: 't1',
      ad: 'Test Tarla',
      zonNumaralari: [1],
      konum: 'Şanlıurfa',
    );
    final guncel = tarla.kopyalaVeGuncelle(enlem: 37.0, boylam: 38.0);

    expect(guncel.konum, 'Şanlıurfa'); // korunmus olmali
    expect(guncel.gpsKonumuVarMi, isTrue);
  });

  test('toJson -> fromJson GPS alanlarini korur', () {
    const tarla = Tarla(
      id: 't1',
      ad: 'Test Tarla',
      zonNumaralari: [1, 2],
      enlem: 37.1591,
      boylam: 38.7969,
    );
    final geriYuklenen = Tarla.fromJson(tarla.toJson());

    expect(geriYuklenen.enlem, 37.1591);
    expect(geriYuklenen.boylam, 38.7969);
    expect(geriYuklenen.gpsKonumuVarMi, isTrue);
  });

  test('fromJson eksik GPS alanlarinda null kalir (eski kayitlarla uyumlu)', () {
    final tarla = Tarla.fromJson({
      'id': 't1',
      'ad': 'Eski Kayit',
      'zonNumaralari': [1],
    });
    expect(tarla.enlem, isNull);
    expect(tarla.boylam, isNull);
    expect(tarla.gpsKonumuVarMi, isFalse);
  });
}
