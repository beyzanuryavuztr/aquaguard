// AquaGuard - DurumRenkleri.onceligiBelirle Testleri
//
// Bu fonksiyon, tarla kartinin (en oncelikli zonu bulma) ve
// UygulamaDurumu.durumOzetiHesapla'nin (ozet sayaclari) TEK ORTAK
// siniflandirma kaynagidir. Onceden bu ikisi birbirinden FARKLI sirali
// elle yazilmis kopyalardi (tarla karti "tespit"i tedaviden daha oncelikli
// sayiyordu, ozet ise tam tersini) -- bu test o regresyonu bir daha
// yasanmayacak sekilde kilitler. Ayrica "durulama surerken duz yesil
// gosterme" tutarsizligini da kapsar.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/widgets/durum_renkleri.dart';

SensorOkuma _okuma({
  required TeshisDurumu durum,
  TedaviTuru tedaviAktif = TedaviTuru.yok,
  bool durulamaAktif = false,
}) {
  return SensorOkuma(
    zaman: DateTime(2026, 9, 3),
    zone: 1,
    ph: 7,
    ec: 1.2,
    orp: 300,
    turbidite: 5,
    debi: 4,
    deltaBasinc: 0.1,
    durum: durum,
    tikanmaTuru: TikanmaTuru.yok,
    guven: 100,
    tedaviAktif: tedaviAktif,
    durulamaAktif: durulamaAktif,
  );
}

void main() {
  group('DurumRenkleri.onceligiBelirle', () {
    test('cevrimdisi (veri yok veya cevrimici degil) en dusuk oncelik', () {
      expect(
        DurumRenkleri.onceligiBelirle(okuma: null, cevrimici: true),
        ZonOnceligi.cevrimdisi,
      );
      expect(
        DurumRenkleri.onceligiBelirle(
          okuma: _okuma(durum: TeshisDurumu.tespitEdildi),
          cevrimici: false,
        ),
        ZonOnceligi.cevrimdisi,
      );
    });

    test('durulama aktifken (tedaviAktif=yok olsa bile) tedavide sayilir', () {
      final okuma = _okuma(durum: TeshisDurumu.normal, durulamaAktif: true);
      expect(
        DurumRenkleri.onceligiBelirle(okuma: okuma, cevrimici: true),
        ZonOnceligi.tedavide,
      );
      // Renk ve ozet metni de bu tutarliligi yansitmali (duz yesil/normal
      // GOSTERMEMELI -- ayni ekranda "zorunlu durulama sürüyor" banneriyle
      // celisir).
      expect(
        DurumRenkleri.renkGetir(okuma: okuma, cevrimici: true),
        DurumRenkleri.tedaviAktif,
      );
      expect(
        DurumRenkleri.ozetMetniGetir(okuma: okuma, cevrimici: true),
        'Zorunlu durulama sürüyor',
      );
    });

    test('tedavide, tespitEdildi\'den DAHA oncelikli (index buyuk)', () {
      final tedavide = DurumRenkleri.onceligiBelirle(
        okuma: _okuma(
          durum: TeshisDurumu.tespitEdildi,
          tedaviAktif: TedaviTuru.asitDozlama,
        ),
        cevrimici: true,
      );
      final tespitSadece = DurumRenkleri.onceligiBelirle(
        okuma: _okuma(durum: TeshisDurumu.tespitEdildi),
        cevrimici: true,
      );
      expect(tedavide.index, greaterThan(tespitSadece.index));
    });

    test('siralama tam olarak: cevrimdisi < normal < belirsiz < tespitEdildi < tedavide', () {
      final siraliDegerler = [
        DurumRenkleri.onceligiBelirle(okuma: null, cevrimici: true),
        DurumRenkleri.onceligiBelirle(
          okuma: _okuma(durum: TeshisDurumu.normal),
          cevrimici: true,
        ),
        DurumRenkleri.onceligiBelirle(
          okuma: _okuma(durum: TeshisDurumu.belirsiz),
          cevrimici: true,
        ),
        DurumRenkleri.onceligiBelirle(
          okuma: _okuma(durum: TeshisDurumu.tespitEdildi),
          cevrimici: true,
        ),
        DurumRenkleri.onceligiBelirle(
          okuma: _okuma(
            durum: TeshisDurumu.tespitEdildi,
            tedaviAktif: TedaviTuru.klorEnjeksiyon,
          ),
          cevrimici: true,
        ),
      ];

      for (var i = 1; i < siraliDegerler.length; i++) {
        expect(
          siraliDegerler[i].index,
          greaterThan(siraliDegerler[i - 1].index),
          reason: 'sira ${i - 1} -> $i artan olmali',
        );
      }
    });
  });
}
