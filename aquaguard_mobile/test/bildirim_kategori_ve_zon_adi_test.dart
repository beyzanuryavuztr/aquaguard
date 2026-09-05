// AquaGuard - Bildirim Kategorisi Gating + Zon Takma Adi Testleri (Asama 7)
//
// UygulamaDurumu.bildirimTercihleriniGuncelle'nin gercekten hangi olay
// turunun bildirim kuyruguna girip girmeyecegini kontrol ettigini,
// operatorun kendi eylemlerinin (manuelMudahale) HER ZAMAN bildirildigini
// ve zon takma adlarinin kalici olarak saklanip zonAdiGetir'e yansidigini
// dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/bildirim_tercihleri.dart';
import 'package:aquaguard_mobile/models/enerji_durumu.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tespit bildirimleri kapatilinca manuelNormaleDondur bildirimi HALA gelir (operator eylemi her zaman bildirilir)', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();
    await durum.bildirimTercihleriniGuncelle(
      const BildirimTercihleri(
        tespit: false,
        tedaviBaslangic: false,
        tedaviTamamlanma: false,
        dusukPil: false,
      ),
    );

    await durum.manuelNormaleDondur(1);
    final bildirimler = durum.bildirimleriAlVeTemizle();

    expect(bildirimler, isNotEmpty);
    expect(bildirimler.first, contains('yanlış alarm'));

    durum.dispose();
  });

  test('tercihler kaydedilip geri okunabilir', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.bildirimTercihleri.tespit, isTrue);

    await durum.bildirimTercihleriniGuncelle(
      durum.bildirimTercihleri.kopyalaVeGuncelle(tespit: false),
    );

    expect(durum.bildirimTercihleri.tespit, isFalse);
    expect(durum.bildirimTercihleri.tedaviBaslangic, isTrue);

    durum.dispose();
  });

  test('zon adi verilmemisse varsayilan "Zon N" doner', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.zonAdiGetir(1), 'Zon 1');

    durum.dispose();
  });

  test('zonTakmaAdiAyarla ile verilen ad zonAdiGetir\'e yansir', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.zonTakmaAdiAyarla(2, 'Kuzeydoğu Parseli');
    expect(durum.zonAdiGetir(2), 'Kuzeydoğu Parseli');
    expect(durum.zonAdiGetir(1), 'Zon 1'); // digerleri etkilenmedi

    durum.dispose();
  });

  test('bos/null ad verilince takma ad kaldirilir, varsayilana doner', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    await durum.zonTakmaAdiAyarla(2, 'Kuzeydoğu Parseli');
    await durum.zonTakmaAdiAyarla(2, '   ');

    expect(durum.zonAdiGetir(2), 'Zon 2');

    durum.dispose();
  });

  test('zon takma adi kalici depodan yeniden acilista geri yuklenir', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.zonTakmaAdiAyarla(3, 'Sera Bölmesi');
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();
    expect(durum2.zonAdiGetir(3), 'Sera Bölmesi');
    durum2.dispose();
  });

  test(
    'gercek gunun pil durumuna gore dusuk pil bildirim mekanizmasi dogru calisir',
    () async {
      final gercekPil = EnerjiDurumu.pilYuzdesiHesapla();
      final dusukMu = gercekPil < EnerjiDurumu.dusukPilEsigi;

      final durum = UygulamaDurumu();
      await durum.baslat();

      final dusukPilKayitlari = durum.aktiviteGecmisi
          .where((k) => k.tur == AktiviteTuru.dusukPil)
          .toList();
      expect(dusukPilKayitlari.length, dusukMu ? 1 : 0);

      if (dusukMu) {
        final bildirimler = durum.bildirimleriAlVeTemizle();
        expect(bildirimler, contains(dusukPilKayitlari.first.mesaj));
      }

      durum.dispose();
    },
  );

  test(
    'dusuk pil tercihi kapaliyken pil dusuk olsa bile bildirim KUYRUKLANMAZ',
    () async {
      // Once bir oturumda tercihi kapat (kalici depoya yazilir).
      final oncekiDurum = UygulamaDurumu();
      await oncekiDurum.baslat();
      await oncekiDurum.bildirimTercihleriniGuncelle(
        const BildirimTercihleri(dusukPil: false),
      );
      oncekiDurum.dispose();

      final durum = UygulamaDurumu();
      await durum.baslat();
      final bildirimler = durum.bildirimleriAlVeTemizle();

      expect(
        bildirimler.any((b) => b.contains('Pil seviyesi düşük')),
        isFalse,
      );

      durum.dispose();
    },
  );
}
