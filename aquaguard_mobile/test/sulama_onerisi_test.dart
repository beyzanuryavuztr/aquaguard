// AquaGuard - Sulama Onerisi Mantigi Testleri (Faz 4)
//
// sulamaOnerisiUret() saf bir fonksiyondur -- ag/GPS/UI'dan bagimsiz,
// dogrudan test edilir. Uc senaryonun (ertele/normal/artir) dogru
// eslendigini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/bitki_turu.dart';
import 'package:aquaguard_mobile/models/hava_tahmini.dart';
import 'package:aquaguard_mobile/models/sulama_onerisi.dart';

GunlukHavaTahmini _tahmin({
  double maksSicaklik = 25,
  int yagisIhtimali = 10,
}) {
  return GunlukHavaTahmini(
    tarih: DateTime(2026, 9, 26),
    maksSicaklikC: maksSicaklik,
    minSicaklikC: maksSicaklik - 10,
    yagisIhtimaliYuzde: yagisIhtimali,
    toplamYagisMm: 0,
  );
}

void main() {
  group('sulamaOnerisiUret', () {
    test('yagis ihtimali yuksekse (>=60) bitki turune BAKMAKSIZIN erteleme onerir', () {
      final oneri = sulamaOnerisiUret(
        yarininTahmini: _tahmin(yagisIhtimali: 75),
        bitkiTuru: BitkiTuru.sebze,
      );
      expect(oneri.seviye, SulamaOneriSeviyesi.erteleyebilirsiniz);
      expect(oneri.mesaj, contains('%75'));
    });

    test('sicak gun + yuksek su ihtiyacli bitki + dusuk yagis -> artirma onerir', () {
      final oneri = sulamaOnerisiUret(
        yarininTahmini: _tahmin(maksSicaklik: 36, yagisIhtimali: 5),
        bitkiTuru: BitkiTuru.sebze, // yuksek su ihtiyaci
      );
      expect(oneri.seviye, SulamaOneriSeviyesi.artirabilirsiniz);
    });

    test('sicak gun ama dusuk su ihtiyacli bitki -> sadece normal onerir (asiri iddiali degil)', () {
      final oneri = sulamaOnerisiUret(
        yarininTahmini: _tahmin(maksSicaklik: 36, yagisIhtimali: 5),
        bitkiTuru: BitkiTuru.diger, // orta su ihtiyaci -- yuksek DEGIL
      );
      expect(oneri.seviye, SulamaOneriSeviyesi.normal);
    });

    test('sicak degil, yagis dusuk -> normal onerir', () {
      final oneri = sulamaOnerisiUret(
        yarininTahmini: _tahmin(maksSicaklik: 22, yagisIhtimali: 10),
        bitkiTuru: BitkiTuru.meyveAgaci,
      );
      expect(oneri.seviye, SulamaOneriSeviyesi.normal);
    });

    test('orta yagis ihtimali (30-59) sicak gunde artirma ONERMEZ (belirsizlik payi)', () {
      final oneri = sulamaOnerisiUret(
        yarininTahmini: _tahmin(maksSicaklik: 36, yagisIhtimali: 45),
        bitkiTuru: BitkiTuru.sebze,
      );
      expect(oneri.seviye, isNot(SulamaOneriSeviyesi.artirabilirsiniz));
    });

    test('mesaj hicbir zaman bos olmaz', () {
      for (final yagis in [0, 30, 60, 90]) {
        for (final sicaklik in [15.0, 25.0, 35.0]) {
          final oneri = sulamaOnerisiUret(
            yarininTahmini: _tahmin(
              maksSicaklik: sicaklik,
              yagisIhtimali: yagis,
            ),
            bitkiTuru: BitkiTuru.tarlaBitkisi,
          );
          expect(oneri.mesaj, isNotEmpty);
        }
      }
    });
  });
}
