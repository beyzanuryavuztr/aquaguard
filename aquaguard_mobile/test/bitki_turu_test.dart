// AquaGuard - BitkiTuru Model Testleri (Faz 4)

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/bitki_turu.dart';

void main() {
  group('bitkiTuruAyristir / bitkiTuruKoduGetir round-trip', () {
    test('her BitkiTuru degeri kod uzerinden ayni degere geri doner', () {
      for (final tur in BitkiTuru.values) {
        final kod = bitkiTuruKoduGetir(tur);
        expect(bitkiTuruAyristir(kod), tur);
      }
    });

    test('null veya taninmayan deger "diger"e duser (uydurma varsayilan degil)', () {
      expect(bitkiTuruAyristir(null), BitkiTuru.diger);
      expect(bitkiTuruAyristir('boyle_bir_bitki_yok'), BitkiTuru.diger);
    });
  });

  group('bitkiTuruEtiketi', () {
    test('her deger icin bos olmayan bir etiket doner', () {
      for (final tur in BitkiTuru.values) {
        expect(bitkiTuruEtiketi(tur), isNotEmpty);
      }
    });
  });

  group('bitkiSuIhtiyaciEgilimi', () {
    test('sebze en yuksek su ihtiyacina sahip kabul edilir', () {
      expect(bitkiSuIhtiyaciEgilimi(BitkiTuru.sebze), SuIhtiyaciEgilimi.yuksek);
    });

    test('diger notr (orta) kabul edilir', () {
      expect(bitkiSuIhtiyaciEgilimi(BitkiTuru.diger), SuIhtiyaciEgilimi.orta);
    });
  });
}
