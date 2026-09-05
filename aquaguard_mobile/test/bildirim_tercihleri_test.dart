// AquaGuard - BildirimTercihleri Testleri
//
// 4 kategorili bildirim tercihi modelinin varsayilanlarini, kismi
// guncellemesini (digerlerini etkilemeden) ve JSON round-trip'ini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/bildirim_tercihleri.dart';

void main() {
  test('varsayilan olarak tum kategoriler acik', () {
    const tercih = BildirimTercihleri();
    expect(tercih.tespit, isTrue);
    expect(tercih.tedaviBaslangic, isTrue);
    expect(tercih.tedaviTamamlanma, isTrue);
    expect(tercih.dusukPil, isTrue);
  });

  test('kopyalaVeGuncelle sadece belirtilen alani degistirir', () {
    const tercih = BildirimTercihleri();
    final guncel = tercih.kopyalaVeGuncelle(tespit: false);

    expect(guncel.tespit, isFalse);
    expect(guncel.tedaviBaslangic, isTrue);
    expect(guncel.tedaviTamamlanma, isTrue);
    expect(guncel.dusukPil, isTrue);
  });

  test('toJson -> fromJson tum alanlari korur', () {
    const tercih = BildirimTercihleri(
      tespit: false,
      tedaviBaslangic: true,
      tedaviTamamlanma: false,
      dusukPil: true,
    );

    final geriYuklenen = BildirimTercihleri.fromJson(tercih.toJson());

    expect(geriYuklenen.tespit, isFalse);
    expect(geriYuklenen.tedaviBaslangic, isTrue);
    expect(geriYuklenen.tedaviTamamlanma, isFalse);
    expect(geriYuklenen.dusukPil, isTrue);
  });

  test('fromJson eksik alanlarda varsayilan (true) kullanir', () {
    final tercih = BildirimTercihleri.fromJson({});
    expect(tercih.tespit, isTrue);
    expect(tercih.tedaviBaslangic, isTrue);
    expect(tercih.tedaviTamamlanma, isTrue);
    expect(tercih.dusukPil, isTrue);
  });
}
