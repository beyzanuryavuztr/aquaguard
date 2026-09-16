// AquaGuard - Bildirim Onceligi + Sessiz Saat Testleri

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/bildirim_onceligi.dart';
import 'package:aquaguard_mobile/models/bildirim_tercihleri.dart';

void main() {
  group('oncelikGetir', () {
    test('tespit kritik onceliktedir', () {
      expect(oncelikGetir(AktiviteTuru.tespit), Oncelik.kritik);
    });

    test('dusukPil dusuk onceliktedir', () {
      expect(oncelikGetir(AktiviteTuru.dusukPil), Oncelik.dusuk);
    });

    test('her AktiviteTuru degeri icin bir eslesme vardir (crash olmaz)', () {
      for (final tur in AktiviteTuru.values) {
        expect(() => oncelikGetir(tur), returnsNormally);
      }
    });
  });

  group('sessizSaattaBastirilmaliMi', () {
    const gecelikTercih = BildirimTercihleri(
      sessizBaslangicDakika: 22 * 60, // 22:00
      sessizBitisDakika: 7 * 60, // 07:00 (gece yarisini gecen aralik)
    );

    test('kritik oncelik sessiz saatte BILE bastirilmaz', () {
      final geceYarisi = DateTime(2026, 1, 1, 23, 0);
      expect(
        sessizSaattaBastirilmaliMi(gecelikTercih, Oncelik.kritik, geceYarisi),
        isFalse,
      );
    });

    test('gece yarisini gecen aralikta (23:00) orta oncelik bastirilir', () {
      final saat23 = DateTime(2026, 1, 1, 23, 0);
      expect(
        sessizSaattaBastirilmaliMi(gecelikTercih, Oncelik.orta, saat23),
        isTrue,
      );
    });

    test('gece yarisindan sonra (03:00) hala sessiz araliktadir', () {
      final saat03 = DateTime(2026, 1, 1, 3, 0);
      expect(
        sessizSaattaBastirilmaliMi(gecelikTercih, Oncelik.orta, saat03),
        isTrue,
      );
    });

    test('gunduz (14:00) sessiz saat DISINDADIR, bastirilmaz', () {
      final ogleden = DateTime(2026, 1, 1, 14, 0);
      expect(
        sessizSaattaBastirilmaliMi(gecelikTercih, Oncelik.orta, ogleden),
        isFalse,
      );
    });

    test('sessiz saat KAPALIYKEN (varsayilan) hicbir zaman bastirilmaz', () {
      const kapaliTercih = BildirimTercihleri();
      final geceYarisi = DateTime(2026, 1, 1, 23, 0);
      expect(
        sessizSaattaBastirilmaliMi(kapaliTercih, Oncelik.orta, geceYarisi),
        isFalse,
      );
    });

    test('duz (gece yarisini gecmeyen) aralikta sinir kontrolu dogru calisir', () {
      const oglenAraligi = BildirimTercihleri(
        sessizBaslangicDakika: 13 * 60, // 13:00
        sessizBitisDakika: 15 * 60, // 15:00
      );
      expect(
        sessizSaattaBastirilmaliMi(
          oglenAraligi,
          Oncelik.orta,
          DateTime(2026, 1, 1, 14, 0),
        ),
        isTrue,
      );
      expect(
        sessizSaattaBastirilmaliMi(
          oglenAraligi,
          Oncelik.orta,
          DateTime(2026, 1, 1, 16, 0),
        ),
        isFalse,
      );
    });
  });
}
