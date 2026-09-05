import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tedavi_basari_analizi.dart';
import 'package:aquaguard_mobile/models/tikanma_olayi.dart';
import 'package:aquaguard_mobile/services/rapor_pdf_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RaporPdfServisi', () {
    test('veri olmadan bile gecerli bir PDF belgesi uretir', () async {
      final belge = await RaporPdfServisi.olustur(
        turSayaclari: const {},
        tedaviSayaclari: const {},
        basariAnalizi: const TedaviBasariAnalizi(
          tamamlananSayisi: 0,
          basariliSayisi: 0,
        ),
        olaylar: const [],
        zonAdiGetir: (z) => 'Zon $z',
      );

      final baytlar = await belge.save();
      expect(baytlar, isNotEmpty);
      // PDF dosyalari '%PDF-' ile baslar (magic bytes).
      expect(String.fromCharCodes(baytlar.take(5)), '%PDF-');
    });

    test('tespit gunlugu ve ozet sayaclari ile dolu bir PDF uretir', () async {
      final olaylar = [
        TikanmaOlayi(
          zaman: DateTime(2026, 9, 1, 10, 30),
          zone: 1,
          tur: TikanmaTuru.kimyasal,
          guven: 87.5,
        ),
        TikanmaOlayi(
          zaman: DateTime(2026, 9, 2, 14, 0),
          zone: 3,
          tur: TikanmaTuru.fiziksel,
          guven: 91.2,
        ),
      ];

      final belge = await RaporPdfServisi.olustur(
        turSayaclari: const {
          TikanmaTuru.kimyasal: 1,
          TikanmaTuru.fiziksel: 1,
        },
        tedaviSayaclari: const {TedaviTuru.asitDozlama: 2},
        basariAnalizi: const TedaviBasariAnalizi(
          tamamlananSayisi: 4,
          basariliSayisi: 3,
        ),
        olaylar: olaylar,
        zonAdiGetir: (z) => 'Zon $z',
      );

      final baytlar = await belge.save();
      expect(baytlar, isNotEmpty);
      expect(baytlar.length, greaterThan(500));
    });

    test('dosyaAdiUret .pdf uzantili, aquaguard on ekli bir ad doner', () {
      final ad = RaporPdfServisi.dosyaAdiUret();
      expect(ad, startsWith('aquaguard_tedavi_raporu_'));
      expect(ad, endsWith('.pdf'));
    });
  });
}
