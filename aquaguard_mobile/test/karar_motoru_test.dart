// AquaGuard - Karar Motoru Testleri
//
// karar_motoru.dart, python/aquaguard_karar_motoru.py ve
// firmware/decision_engine.h dosyalarindaki AYNI algoritmanin UCUNCU
// birebir kopyasidir -- bu, en cok kopyalanmis (ve dolayisiyla en riskli)
// koddur. Bu testler, her literatur imzasinin (brief SS6) kendi turune
// dogru siniflandirildigini ve esik/guven mantiginin dogru calistigini
// dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/config/sensor_imzalari.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/services/karar_motoru.dart';

Map<String, double> _sinifinTamOrtalamasi(String sinif) {
  final imza = sensorImzalari[sinif]!;
  return {for (final sensor in sensorSirasi) sensor: imza[sensor]!.ortalama};
}

void main() {
  group('Esik tetikleyicileri (Katman 1 - Asama A)', () {
    test('Hicbir esik asilmazsa durum normal olmali', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('normal'));
      expect(sonuc.durum, TeshisDurumu.normal);
      expect(sonuc.tur, TikanmaTuru.yok);
      expect(sonuc.guven, 100.0);
    });

    test('Debi tam esik degerinde (>=) tikanma tetiklenmeli', () {
      final ornek = _sinifinTamOrtalamasi('normal');
      ornek['debi'] = referansDebi - debiDususEsigi; // tam sinirda
      final sonuc = KararMotoru.teshisEt(ornek);
      expect(sonuc.durum, isNot(TeshisDurumu.normal));
    });

    test('Turbidite esik degerinin hemen altinda tetiklenmemeli', () {
      final ornek = _sinifinTamOrtalamasi('normal');
      ornek['turbidite'] = turbiditeEsigi - 0.01;
      final sonuc = KararMotoru.teshisEt(ornek);
      expect(sonuc.durum, TeshisDurumu.normal);
    });
  });

  group('Tur siniflandirmasi (Katman 1 - Asama B)', () {
    test('Kimyasal imzasinin tam ortalamasi -> kimyasal, yuksek guven', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('kimyasal'));
      expect(sonuc.durum, TeshisDurumu.tespitEdildi);
      expect(sonuc.tur, TikanmaTuru.kimyasal);
      expect(sonuc.guven, greaterThan(90));
    });

    test('Biyolojik imzasinin tam ortalamasi -> biyolojik, yuksek guven', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('biyolojik'));
      expect(sonuc.durum, TeshisDurumu.tespitEdildi);
      expect(sonuc.tur, TikanmaTuru.biyolojik);
      expect(sonuc.guven, greaterThan(90));
    });

    test('Fiziksel imzasinin tam ortalamasi -> fiziksel, yuksek guven', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('fiziksel'));
      expect(sonuc.durum, TeshisDurumu.tespitEdildi);
      expect(sonuc.tur, TikanmaTuru.fiziksel);
      expect(sonuc.guven, greaterThan(90));
    });
  });

  group('Tetikleyici kombinasyonlari', () {
    test(
      'Tek tetikleyici (sadece debi dususu, kimya normale yakin) -- '
      'kimya en yakin oldugu turu (fiziksel) secer',
      () {
        final ornek = {
          'ph': 7.00,
          'ec': 1.15,
          'orp': 375.0,
          'turbidite': 3.0,
          'debi': referansDebi - debiDususEsigi - 0.1, // SADECE bu esigi asiyor
          'delta_basinc': 0.10,
        };
        final sonuc = KararMotoru.teshisEt(ornek);
        expect(sonuc.durum, TeshisDurumu.tespitEdildi);
        // 'normal' ve 'fiziksel' siniflari ph/ec'de AYNI, orp'de yakin --
        // tek fizisel tetikleyici (dusuk debi) ile birlikte en yakin
        // kimya profili 'fiziksel'e cikar.
        expect(sonuc.tur, TikanmaTuru.fiziksel);
      },
    );

    test(
      'Tum tetikleyiciler ayni anda tetiklense bile TUR SADECE ph/ec/orp '
      'kimyasina gore belirlenir (debi/basinc/turbidite sadece VAR/YOK bilgisi verir)',
      () {
        final ornek = {
          'ph': 8.30,
          'ec': 2.75,
          'orp': 310.0, // kimyasal imzasinin tam ortalamasi
          'turbidite': 40.0, // esigin cok uzerinde
          'debi': 1.0, // esigin cok altinda
          'delta_basinc': 0.8, // esigin cok uzerinde
        };
        final sonuc = KararMotoru.teshisEt(ornek);
        expect(sonuc.durum, TeshisDurumu.tespitEdildi);
        expect(sonuc.tur, TikanmaTuru.kimyasal);
        expect(sonuc.guven, greaterThan(99));
      },
    );
  });

  group('Guven esigi siniri (%50 -- belirsiz/tespit ayrimi)', () {
    // Asagidaki degerler, kimyasal<->fiziksel kimyasi arasinda dogrusal
    // interpolasyonla TARANARAK bulunmus GERCEK sinir noktalaridir (bkz.
    // gelistirme notlari) -- guvenEsigi=50.0'in HEMEN iki yaninda.
    test('guven %50nin hemen USTUNDEYSE tespit edildi sayilir', () {
      final ornek = {
        'ph': 8.30 * 0.4 + 7.00 * 0.6,
        'ec': 2.75 * 0.4 + 1.15 * 0.6,
        'orp': 310.0 * 0.4 + 350.0 * 0.6,
        'turbidite': 15.0,
        'debi': 4.0,
        'delta_basinc': 0.1,
      };
      final sonuc = KararMotoru.teshisEt(ornek);
      expect(sonuc.guven, greaterThanOrEqualTo(guvenEsigi));
      expect(sonuc.durum, TeshisDurumu.tespitEdildi);
    });

    test(
      'guven %50nin HEMEN ALTINDAYSA (esik asilmis olsa bile) belirsiz sayilir',
      () {
        const t = 0.601;
        final ornek = {
          'ph': 8.30 * (1 - t) + 7.00 * t,
          'ec': 2.75 * (1 - t) + 1.15 * t,
          'orp': 310.0 * (1 - t) + 350.0 * t,
          'turbidite': 15.0, // esik asildi (tikanmaVar=true)
          'debi': 4.0,
          'delta_basinc': 0.1,
        };
        final sonuc = KararMotoru.teshisEt(ornek);
        expect(sonuc.guven, lessThan(guvenEsigi));
        expect(sonuc.durum, TeshisDurumu.belirsiz);
      },
    );
  });

  group('Aciklanabilirlik (uc turun guven dokumu)', () {
    test('guven alanlari toplami yaklasik %100 olmali (softmax ozelligi)', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('biyolojik'));
      final toplam = sonuc.guvenKimyasal + sonuc.guvenBiyolojik + sonuc.guvenFiziksel;
      expect(toplam, closeTo(100.0, 0.01));
    });

    test('normal durumda uc guven alani da 0 olmali', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('normal'));
      expect(sonuc.guvenKimyasal, 0.0);
      expect(sonuc.guvenBiyolojik, 0.0);
      expect(sonuc.guvenFiziksel, 0.0);
    });

    test('kazanan turun guveni, o turun guven alanina esit olmali', () {
      final sonuc = KararMotoru.teshisEt(_sinifinTamOrtalamasi('fiziksel'));
      expect(sonuc.guven, sonuc.guvenFiziksel);
    });
  });
}
