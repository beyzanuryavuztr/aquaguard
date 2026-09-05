// AquaGuard - Bakim Takvimi Entegrasyon Testleri (Oncelik 12)
//
// UygulamaDurumu'nun ilk acilista varsayilan bakim gorevlerini seed'ledigini,
// bunlarin kalici depoya yazildigini ve bakimGoreviTamamlandiIsaretle'nin
// dogru gorevi guncelleyip kaydettigini dogrular.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/bakim_gorevi.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/services/depolama_servisi.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ilk acilista 4 varsayilan bakim gorevi seed edilir, hicbiri uyari gerektirmez', () async {
    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.bakimGorevleri.length, 4);
    expect(durum.bakimUyarisiVarMi, isFalse);

    durum.dispose();
  });

  test('bakim gorevleri yeniden acilista KALICI olarak korunur (yeniden seed edilmez)', () async {
    final durum1 = UygulamaDurumu();
    await durum1.baslat();
    await durum1.bakimGoreviTamamlandiIsaretle('filtre_temizligi');
    final ilkGuncellemeTarihi = durum1.bakimGorevleri
        .firstWhere((g) => g.id == 'filtre_temizligi')
        .sonYapilmaTarihi;
    durum1.dispose();

    final durum2 = UygulamaDurumu();
    await durum2.baslat();

    expect(durum2.bakimGorevleri.length, 4);
    expect(
      durum2.bakimGorevleri
          .firstWhere((g) => g.id == 'filtre_temizligi')
          .sonYapilmaTarihi,
      ilkGuncellemeTarihi,
    );

    durum2.dispose();
  });

  test(
    'bakimGoreviTamamlandiIsaretle SADECE eslesen gorevi gunceller, digerlerine dokunmaz',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final oncekiVanaTarihi = durum.bakimGorevleri
          .firstWhere((g) => g.id == 'vana_kontrolu')
          .sonYapilmaTarihi;

      await durum.bakimGoreviTamamlandiIsaretle('filtre_temizligi');

      final filtreGorevi = durum.bakimGorevleri.firstWhere(
        (g) => g.id == 'filtre_temizligi',
      );
      final vanaGorevi = durum.bakimGorevleri.firstWhere(
        (g) => g.id == 'vana_kontrolu',
      );

      expect(filtreGorevi.durumu(), BakimDurumu.normal);
      expect(vanaGorevi.sonYapilmaTarihi, oncekiVanaTarihi);

      durum.dispose();
    },
  );

  test('bakimUyarisiVarMi, gecikmis bir gorev oldugunda true doner', () async {
    // Onceden kayitli, KASITLI gecikmis bir gorev listesi yazip baslat()'in
    // bunu (varsayilani seed etmeden) yukledigini ve uyarinin dogru
    // hesaplandigini dogruluyoruz.
    final cokEski = DateTime.now().subtract(const Duration(days: 400));
    await DepolamaServisi().bakimGorevleriniKaydet([
      BakimGorevi(
        id: 'filtre_temizligi',
        baslik: 'Filtre Temizliği',
        aciklama: '',
        periyotGun: 30,
        sonYapilmaTarihi: cokEski,
      ),
    ]);

    final durum = UygulamaDurumu();
    await durum.baslat();

    expect(durum.bakimGorevleri.length, 1);
    expect(durum.bakimUyarisiVarMi, isTrue);

    durum.dispose();
  });
}
