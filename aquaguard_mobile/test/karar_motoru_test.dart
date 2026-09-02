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
