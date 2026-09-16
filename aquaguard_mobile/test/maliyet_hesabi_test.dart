// AquaGuard - Maliyet Hesabi Testleri (saf fonksiyonlar)

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/maliyet_hesabi.dart';
import 'package:aquaguard_mobile/models/maliyet_parametreleri.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';

void main() {
  group('suMaliyetiHesapla', () {
    test('1000 litre = 1 m3, birim fiyatla dogrudan carpilir', () {
      final maliyet = suMaliyetiHesapla(litre: 1000, birimFiyatTLm3: 15.0);
      expect(maliyet, 15.0);
    });

    test('0 litre icin 0 maliyet doner', () {
      expect(suMaliyetiHesapla(litre: 0, birimFiyatTLm3: 15.0), 0.0);
    });
  });

  group('tedaviMaliyetiTahminiHesapla', () {
    const parametreler = MaliyetParametreleri(
      asitBirimFiyatiTLLitre: 8.0,
      klorBirimFiyatiTLLitre: 6.0,
      asitDozlamaOraniLDk: 0.5,
      klorDozlamaOraniLDk: 0.5,
    );

    test('kimyasal tur icin pozitif bir maliyet doner', () {
      final maliyet = tedaviMaliyetiTahminiHesapla(
        tur: TikanmaTuru.kimyasal,
        parametreler: parametreler,
      );
      // 30sn (asit) = 0.5 dk * 0.5 L/dk * 8 TL/L = 2.0 TL
      expect(maliyet, closeTo(2.0, 0.01));
    });

    test('biyolojik tur icin pozitif bir maliyet doner', () {
      final maliyet = tedaviMaliyetiTahminiHesapla(
        tur: TikanmaTuru.biyolojik,
        parametreler: parametreler,
      );
      // 30sn (klor) = 0.5 dk * 0.5 L/dk * 6 TL/L = 1.5 TL
      expect(maliyet, closeTo(1.5, 0.01));
    });

    test('fiziksel tur icin 0 doner (su maliyeti ayrica hesaplanir, cift sayim olmaz)', () {
      final maliyet = tedaviMaliyetiTahminiHesapla(
        tur: TikanmaTuru.fiziksel,
        parametreler: parametreler,
      );
      expect(maliyet, 0.0);
    });

    test('yok turu icin 0 doner', () {
      final maliyet = tedaviMaliyetiTahminiHesapla(
        tur: TikanmaTuru.yok,
        parametreler: parametreler,
      );
      expect(maliyet, 0.0);
    });
  });

  group('MaliyetParametreleri toJson/fromJson', () {
    test('round-trip tum alanlari korur', () {
      const parametreler = MaliyetParametreleri(
        suBirimFiyatiTLm3: 20.0,
        asitBirimFiyatiTLLitre: 9.5,
        klorBirimFiyatiTLLitre: 7.5,
      );
      final geriYuklenen = MaliyetParametreleri.fromJson(
        parametreler.toJson(),
      );
      expect(geriYuklenen.suBirimFiyatiTLm3, 20.0);
      expect(geriYuklenen.asitBirimFiyatiTLLitre, 9.5);
      expect(geriYuklenen.klorBirimFiyatiTLLitre, 7.5);
    });

    test('eksik alanlarda varsayilan degerler kullanilir', () {
      final parametreler = MaliyetParametreleri.fromJson({});
      const varsayilan = MaliyetParametreleri();
      expect(parametreler.suBirimFiyatiTLm3, varsayilan.suBirimFiyatiTLm3);
    });

    test('kopyalaVeGuncelle sadece belirtilen alani degistirir', () {
      const parametreler = MaliyetParametreleri();
      final guncel = parametreler.kopyalaVeGuncelle(suBirimFiyatiTLm3: 25.0);
      expect(guncel.suBirimFiyatiTLm3, 25.0);
      expect(
        guncel.asitBirimFiyatiTLLitre,
        parametreler.asitBirimFiyatiTLLitre,
      );
    });
  });
}
