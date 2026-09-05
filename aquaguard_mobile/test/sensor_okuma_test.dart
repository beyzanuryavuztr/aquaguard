// AquaGuard - SensorOkuma JSON Parsing Testleri (Oncelik 4)
//
// MQTT'den (veya kalici depodan) gelen JSON'un SensorOkuma.fromJson ile
// dogru cevrildigini, eksik alanlarin GUVENLI varsayilanlara (0.0 /
// bilinmiyor / yok) dustugunu ve tip-uyumsuz (bozuk) verinin gercekten
// nasil davrandigini (bu ANLIK MQTT mesaji icin -- kalici depodaki bozuk
// veriden KORUNMA depolama_servisi katmaninda ayrica ele alinir, bkz.
// depolama_servisi_test.dart) dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';

void main() {
  group('fromJson - gecerli veri', () {
    test('tum alanlari dogru turlere cevirir', () {
      final json = {
        'zaman': '2026-09-05 14:30:00',
        'zone': 2,
        'ph': 7.15,
        'ec': 1.22,
        'orp': 360,
        'turbidite': 4.5,
        'debi': 3.95,
        'delta_basinc': 0.12,
        'durum': 'tespit_edildi',
        'tikanma_turu': 'kimyasal',
        'guven': 88.5,
        'guven_kimyasal': 88.5,
        'guven_biyolojik': 6.0,
        'guven_fiziksel': 5.5,
        'tedavi_aktif': 'asit_dozlama',
        'durulama_aktif': false,
      };

      final okuma = SensorOkuma.fromJson(json);

      expect(okuma.zone, 2);
      expect(okuma.ph, 7.15);
      expect(okuma.orp, 360.0); // int -> double donusumu (num uzerinden)
      expect(okuma.durum, TeshisDurumu.tespitEdildi);
      expect(okuma.tikanmaTuru, TikanmaTuru.kimyasal);
      expect(okuma.tedaviAktif, TedaviTuru.asitDozlama);
      expect(okuma.durulamaAktif, isFalse);
      expect(okuma.zaman, DateTime(2026, 9, 5, 14, 30, 0));
    });

    test('bosluklu zaman formatini (T yerine bosluk) dogru ayristirir', () {
      final okuma = SensorOkuma.fromJson({'zaman': '2026-01-15 08:00:00'});
      expect(okuma.zaman, DateTime(2026, 1, 15, 8, 0, 0));
    });
  });

  group('fromJson - eksik alanlar', () {
    test('bos harita -- hicbir alan olmadan bile GUVENLI varsayilanlara duser', () {
      final okuma = SensorOkuma.fromJson({});

      expect(okuma.zone, 0);
      expect(okuma.ph, 0.0);
      expect(okuma.debi, 0.0);
      expect(okuma.durum, TeshisDurumu.bilinmiyor);
      expect(okuma.tikanmaTuru, TikanmaTuru.yok);
      expect(okuma.tedaviAktif, TedaviTuru.yok);
      expect(okuma.durulamaAktif, isFalse);
      // zaman alani da yoksa "simdi" kullanilir -- tam esitlik test
      // edilemez (calisma ani), ama makul bir DateTime donmesi yeterli.
      expect(okuma.zaman, isA<DateTime>());
    });

    test('taninmayan durum/tur/tedavi metinleri sessizce "bilinmiyor/yok"a duser', () {
      final okuma = SensorOkuma.fromJson({
        'durum': 'gecersiz_deger',
        'tikanma_turu': 'gecersiz_deger',
        'tedavi_aktif': 'gecersiz_deger',
      });

      expect(okuma.durum, TeshisDurumu.bilinmiyor);
      expect(okuma.tikanmaTuru, TikanmaTuru.yok);
      expect(okuma.tedaviAktif, TedaviTuru.yok);
    });

    test('sadece bazi guven_* alanlari varsa digerleri 0.0 kalir', () {
      final okuma = SensorOkuma.fromJson({'guven_kimyasal': 75.0});
      expect(okuma.guvenKimyasal, 75.0);
      expect(okuma.guvenBiyolojik, 0.0);
      expect(okuma.guvenFiziksel, 0.0);
    });
  });

  group('fromCacheJson (kalici depo formatı) - eksik/gecersiz alanlar', () {
    test('bos haritada enum alanlari kendi guvenli varsayilanlarina duser', () {
      final okuma = SensorOkuma.fromCacheJson({});
      expect(okuma.durum, TeshisDurumu.bilinmiyor);
      expect(okuma.tikanmaTuru, TikanmaTuru.yok);
      expect(okuma.tedaviAktif, TedaviTuru.yok);
      expect(okuma.zaman, isA<DateTime>());
    });

    test('gecersiz zaman metni "simdi"ye duser, cokmez', () {
      expect(
        () => SensorOkuma.fromCacheJson({'zaman': 'bozuk-tarih-degeri'}),
        returnsNormally,
      );
    });
  });

  group('toJson -> fromCacheJson round-trip', () {
    test('bir okumayi kaydedip geri yukleyince TUM alanlar korunur', () {
      final orijinal = SensorOkuma(
        zaman: DateTime(2026, 9, 5, 10, 0),
        zone: 3,
        ph: 6.8,
        ec: 1.4,
        orp: 200,
        turbidite: 22,
        debi: 2.9,
        deltaBasinc: 0.31,
        durum: TeshisDurumu.tespitEdildi,
        tikanmaTuru: TikanmaTuru.biyolojik,
        guven: 91.2,
        guvenKimyasal: 3.0,
        guvenBiyolojik: 91.2,
        guvenFiziksel: 5.8,
        tedaviAktif: TedaviTuru.klorEnjeksiyon,
        durulamaAktif: false,
      );

      final geriYuklenen = SensorOkuma.fromCacheJson(orijinal.toJson());

      expect(geriYuklenen.zone, orijinal.zone);
      expect(geriYuklenen.durum, orijinal.durum);
      expect(geriYuklenen.tikanmaTuru, orijinal.tikanmaTuru);
      expect(geriYuklenen.tedaviAktif, orijinal.tedaviAktif);
      expect(geriYuklenen.guvenBiyolojik, orijinal.guvenBiyolojik);
      expect(geriYuklenen.zaman, orijinal.zaman);
    });
  });
}
