// AquaGuard - Tema Modu Entegrasyon Testleri (Oncelik 14)
//
// UygulamaDurumu'nun varsayilan olarak Koyu tema ile basladigini,
// temaModuAyarla'nin degeri KALICI olarak (yeniden acilista da) korudugunu
// dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/tema_modu.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('varsayilan tema modu Koyu', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.temaModu, TemaModu.koyu);

    durum.dispose();
  });

  test('temaModuAyarla degeri gunceller ve yeniden acilista korunur', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.temaModuAyarla(TemaModu.acik);
    expect(durum1.temaModu, TemaModu.acik);
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.temaModu, TemaModu.acik);

    durum2.dispose();
  });

  test('Sistem modu da dogru kaydedilip geri yuklenir', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.temaModuAyarla(TemaModu.sistem);
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.temaModu, TemaModu.sistem);

    durum2.dispose();
  });
}
