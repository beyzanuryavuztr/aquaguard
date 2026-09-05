// AquaGuard - Demo Hizi Testleri (Oncelik 1: Demo Hiz Kontrolu)
//
// Hiz enum'unun dogru sureleri dondugunu, UygulamaDurumu.demoHiziniAyarla'nin
// tercihi kalici kaydettigini VE calisan SimulasyonServisi'nin zamanlayicisini
// GERCEKTEN yeni hizla degistirdigini (iteratorleri sifirlamadan) dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/demo_hizi.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/services/simulasyon_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('her hiz seviyesi dogru sureyi doner', () {
    expect(DemoHizi.yavas.sure, const Duration(seconds: 3));
    expect(DemoHizi.normal.sure, const Duration(milliseconds: 1500));
    expect(DemoHizi.hizli.sure, const Duration(milliseconds: 500));
    expect(DemoHizi.turbo.sure, const Duration(milliseconds: 200));
  });

  test('varsayilan demo hizi Normal\'dir', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    expect(durum.demoHizi, DemoHizi.normal);
    durum.dispose();
  });

  test('demoHiziniAyarla kalici olarak kaydedilir ve yeniden acilista geri yuklenir', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.demoHiziniAyarla(DemoHizi.turbo);
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.demoHizi, DemoHizi.turbo);
    durum2.dispose();
  });

  test(
    'SimulasyonServisi.hiziDegistir, zon iteratorlerini SIFIRLAMADAN zamanlayiciyi degistirir',
    () async {
      final uretilenler = <SensorOkuma>[];
      final servis = SimulasyonServisi(
        zonlar: [1],
        veriUretildiginde: uretilenler.add,
      );
      servis.baslat(aralik: const Duration(milliseconds: 500));
      servis.manuelTedaviBaslat(1, TikanmaTuru.kimyasal);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      uretilenler.clear();

      // Hizi degistir -- devam eden tedavi senaryosu KESINTIYE UGRAMAMALI.
      servis.hiziDegistir(const Duration(milliseconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(uretilenler, isNotEmpty);
      expect(uretilenler.first.tedaviAktif, TedaviTuru.asitDozlama);

      servis.durdur();
    },
  );

  test('calismayan bir SimulasyonServisi\'nde hiziDegistir sessizce hicbir sey yapmaz', () {
    final servis = SimulasyonServisi(zonlar: [1], veriUretildiginde: (_) {});
    expect(
      () => servis.hiziDegistir(const Duration(milliseconds: 100)),
      returnsNormally,
    );
  });
}
