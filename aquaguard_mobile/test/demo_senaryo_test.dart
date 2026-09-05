// AquaGuard - demoSenaryosuTetikle Testleri
//
// Jüri onunde tek dokunusla senaryo tetikleme (Asama 4) -- her senaryonun
// dogru aciklamayla tek bir konsolide aktivite kaydi urettigini, Demo Modu
// kapaliyken sessizce hicbir sey yapmadigini ve (bir senaryo icin) gercekten
// hedeflenen zonun verisini degistirdigini dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sağlıklı senaryo, aktivite gecmisine konsolide TEK kayit ekler', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    final oncekiUzunluk = durum.aktiviteGecmisi.length;

    await durum.demoSenaryosuTetikle(DemoSenaryosu.saglikli);

    expect(durum.aktiviteGecmisi.length, oncekiUzunluk + 1);
    expect(durum.aktiviteGecmisi.first.tur, AktiviteTuru.manuelMudahale);
    expect(
      durum.aktiviteGecmisi.first.mesaj,
      'Demo senaryosu tetiklendi: Sağlıklı Sistem',
    );

    durum.dispose();
  });

  test('kimyasal senaryo, Zon 2yi hedefleyen aciklamayla kayit ekler', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.demoSenaryosuTetikle(DemoSenaryosu.kimyasal);

    expect(
      durum.aktiviteGecmisi.first.mesaj,
      'Demo senaryosu tetiklendi: Kimyasal Tıkanma (Zon 2)',
    );

    durum.dispose();
  });

  test('mutex kilidi senaryosu, iki zonu birden hedefleyen aciklamayla kayit ekler', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.demoSenaryosuTetikle(DemoSenaryosu.mutexKilidi);

    expect(
      durum.aktiviteGecmisi.first.mesaj,
      'Demo senaryosu tetiklendi: Mutex Kilit Gösterimi (Zon 2 + Zon 4)',
    );

    durum.dispose();
  });

  test('Demo Modu kapaliyken sessizce hicbir sey yapmaz', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await durum.demoModunuKapat();
    final oncekiUzunluk = durum.aktiviteGecmisi.length;

    await durum.demoSenaryosuTetikle(DemoSenaryosu.kimyasal);

    expect(durum.aktiviteGecmisi.length, oncekiUzunluk);

    durum.dispose();
  });

  test(
    'kimyasal senaryo tetiklendikten sonra bir sonraki zamanlayici tikinde Zon 2 gercekten kimyasal tedaviye gecer',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat(); // demo modu varsayilan 3sn araliginda calisir

      await durum.demoSenaryosuTetikle(DemoSenaryosu.kimyasal);
      await Future<void>.delayed(const Duration(milliseconds: 3500));

      final okuma = durum.sonOkuma(2);
      expect(okuma, isNotNull);
      expect(okuma!.tedaviAktif, TedaviTuru.asitDozlama);

      durum.dispose();
    },
  );
}
