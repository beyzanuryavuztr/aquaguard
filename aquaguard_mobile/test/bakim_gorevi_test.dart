// AquaGuard - BakimGorevi Testleri (Oncelik 12)
//
// Saf tarih hesaplarini (sonrakiTarih, kalanGun, durumu) ve
// tamamlandiOlarakIsaretle'nin sonraki tarihi doğru ileri attigini dogrular.

import 'package:aquaguard_mobile/models/bakim_gorevi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BakimGorevi', () {
    test('sonrakiTarih, sonYapilmaTarihi + periyotGun olur', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: DateTime(2026, 1, 1),
      );

      expect(gorev.sonrakiTarih, DateTime(2026, 1, 31));
    });

    test('sonraki tarihten cok ONCEKI bir simdi icin durum normal doner', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: DateTime(2026, 1, 1),
      );

      // Sonraki tarih 31 Ocak; 1 Ocak'ta (henuz cok erken) normal olmali.
      expect(gorev.durumu(DateTime(2026, 1, 1)), BakimDurumu.normal);
    });

    test('yaklasiyor esigi icinde (periyodun %20si, max 7 gun) yaklasiyor doner', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: DateTime(2026, 1, 1),
      );
      // Sonraki tarih 31 Ocak. Esik = min(30*0.2, 7) yuvarlanmis = 6 gun.
      // 26 Ocak'ta kalan gun = 5 -> yaklasiyor.
      expect(gorev.durumu(DateTime(2026, 1, 26)), BakimDurumu.yaklasiyor);
    });

    test('sonraki tarih gecince gecikti doner', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: DateTime(2026, 1, 1),
      );

      expect(gorev.durumu(DateTime(2026, 2, 5)), BakimDurumu.gecikti);
    });

    test(
      'REGRESYON: sona erme tarihinden SADECE birkaç saat sonrası bile gecikti sayılır '
      '(Duration.inDays sıfıra yuvarlar, 2026-09-06 acımasız denetimde bulundu)',
      () {
        final gorev = BakimGorevi(
          id: 't1',
          baslik: 'Test',
          aciklama: '',
          periyotGun: 30,
          sonYapilmaTarihi: DateTime(2026, 1, 1),
        );
        // sonrakiTarih = 31 Ocak 00:00. Sadece 12 saat sonrasi (henuz TAM
        // bir gun bile gecmemis) -- Duration(hours: -12).inDays sifira
        // yuvarlanir, "kalan < 0" kontrolu bunu KACIRIRDI.
        final onIkiSaatSonra = DateTime(2026, 1, 31, 12);

        expect(gorev.durumu(onIkiSaatSonra), BakimDurumu.gecikti);
      },
    );

    test('kisa periyotta (30 gun) yaklasiyor penceresi 7 gunu GECMEZ', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: DateTime(2026, 1, 1),
      );
      // 10 gun kala (21 Ocak) HALA normal olmali -- esik sadece 6 gun.
      expect(gorev.durumu(DateTime(2026, 1, 21)), BakimDurumu.normal);
    });

    test('tamamlandiOlarakIsaretle sonYapilmaTarihi ni verilen tarihe gunceller', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: DateTime(2026, 1, 1),
      );

      final guncellenen = gorev.tamamlandiOlarakIsaretle(DateTime(2026, 6, 1));

      expect(guncellenen.sonYapilmaTarihi, DateTime(2026, 6, 1));
      expect(guncellenen.sonrakiTarih, DateTime(2026, 7, 1));
      expect(guncellenen.id, gorev.id);
      expect(guncellenen.periyotGun, gorev.periyotGun);
    });

    test('toJson/fromJson round-trip verileri korur', () {
      final gorev = BakimGorevi(
        id: 't1',
        baslik: 'Test Görevi',
        aciklama: 'Açıklama',
        periyotGun: 60,
        sonYapilmaTarihi: DateTime(2026, 3, 15),
      );

      final geriDonen = BakimGorevi.fromJson(gorev.toJson());

      expect(geriDonen.id, gorev.id);
      expect(geriDonen.baslik, gorev.baslik);
      expect(geriDonen.aciklama, gorev.aciklama);
      expect(geriDonen.periyotGun, gorev.periyotGun);
      expect(geriDonen.sonYapilmaTarihi, gorev.sonYapilmaTarihi);
    });
  });

  group('varsayilanBakimGorevleri', () {
    test('4 gorev doner, hepsi verilen baslangic tarihiyle baslar', () {
      final baslangic = DateTime(2026, 9, 5);
      final gorevler = varsayilanBakimGorevleri(baslangic);

      expect(gorevler.length, 4);
      for (final g in gorevler) {
        expect(g.sonYapilmaTarihi, baslangic);
        expect(g.durumu(baslangic), BakimDurumu.normal);
      }
      // Benzersiz id'ler olmali.
      expect(gorevler.map((g) => g.id).toSet().length, 4);
    });
  });
}
