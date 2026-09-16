// AquaGuard - KuyruklanmisKomut ve DepolamaServisi Testleri (Offline Mod)

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/kuyruklanmis_komut.dart';
import 'package:aquaguard_mobile/services/depolama_servisi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KuyruklanmisKomut.suresiGecmisMi', () {
    test('gecerlilik suresi icindeyse false doner', () {
      final komut = KuyruklanmisKomut(
        zone: 1,
        komut: const {'komut': 'sulama_durdur'},
        olusturmaZamani: DateTime(2026, 1, 1, 12, 0),
      );
      final simdi = DateTime(2026, 1, 1, 12, 3); // 3 dk sonra
      expect(
        komut.suresiGecmisMi(const Duration(minutes: 5), simdi),
        isFalse,
      );
    });

    test('gecerlilik suresini asinca true doner', () {
      final komut = KuyruklanmisKomut(
        zone: 1,
        komut: const {'komut': 'sulama_durdur'},
        olusturmaZamani: DateTime(2026, 1, 1, 12, 0),
      );
      final simdi = DateTime(2026, 1, 1, 12, 6); // 6 dk sonra
      expect(
        komut.suresiGecmisMi(const Duration(minutes: 5), simdi),
        isTrue,
      );
    });
  });

  group('KuyruklanmisKomut toJson/fromJson round-trip', () {
    test('tum alanlar korunur', () {
      final orijinal = KuyruklanmisKomut(
        zone: 3,
        komut: const {'komut': 'tedavi_baslat', 'tedavi_turu': 'asit_dozlama'},
        olusturmaZamani: DateTime(2026, 9, 16, 10, 30),
      );
      final geriYuklenen = KuyruklanmisKomut.fromJson(orijinal.toJson());

      expect(geriYuklenen.zone, 3);
      expect(geriYuklenen.komut, orijinal.komut);
      expect(geriYuklenen.olusturmaZamani, orijinal.olusturmaZamani);
    });
  });

  group('DepolamaServisi kuyruklananKomutlariGetir/Kaydet', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('kayit yoksa bos liste doner', () async {
      final depolama = DepolamaServisi();
      final komutlar = await depolama.kuyruklananKomutlariGetir();
      expect(komutlar, isEmpty);
    });

    test('round-trip: kaydedilen komutlar aynen geri yuklenir', () async {
      final depolama = DepolamaServisi();
      final komutlar = [
        KuyruklanmisKomut(
          zone: 1,
          komut: const {'komut': 'sulama_durdur'},
          olusturmaZamani: DateTime(2026, 9, 16, 8, 0),
        ),
        KuyruklanmisKomut(
          zone: 2,
          komut: const {'komut': 'normale_dondur'},
          olusturmaZamani: DateTime(2026, 9, 16, 8, 5),
        ),
      ];
      await depolama.kuyruklananKomutlariKaydet(komutlar);

      final geriYuklenen = await depolama.kuyruklananKomutlariGetir();
      expect(geriYuklenen.length, 2);
      expect(geriYuklenen[0].zone, 1);
      expect(geriYuklenen[1].komut['komut'], 'normale_dondur');
    });
  });
}
