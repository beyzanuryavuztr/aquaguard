// AquaGuard - tedaviBasarisiniHesapla Testleri
//
// Tedavi Geçmişi ekranindaki "Ortalama Başarı Oranı" kartinin dayandigi
// saf fonksiyon -- referans debiye (4.0 LPM) toleransli donen/donmeyen
// tedavileri dogru sayip saymadigini ve birden fazla zonun sonucunu
// dogru birlestirip birlestirmedigini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tedavi_basari_analizi.dart';

SensorOkuma _okuma({
  required DateTime zaman,
  required double debi,
  TedaviTuru tedavi = TedaviTuru.yok,
  bool durulama = false,
}) => SensorOkuma(
  zaman: zaman,
  zone: 1,
  ph: 7.0,
  ec: 1.1,
  orp: 350,
  turbidite: 3,
  debi: debi,
  deltaBasinc: 0.1,
  durum: TeshisDurumu.normal,
  tikanmaTuru: TikanmaTuru.yok,
  guven: 100,
  tedaviAktif: tedavi,
  durulamaAktif: durulama,
);

void main() {
  final t0 = DateTime(2026, 9, 5, 8, 0);
  DateTime dk(int n) => t0.add(Duration(minutes: n));

  test('2den az kayit varsa 0/0 doner', () {
    final sonuc = tedaviBasarisiniHesapla([]);
    expect(sonuc.tamamlananSayisi, 0);
    expect(sonuc.basariOrani, 0.0);
  });

  test('hic tamamlanmis tedavi yoksa oran 0 olur', () {
    final gecmis = [
      _okuma(zaman: dk(1), debi: 4.0),
      _okuma(zaman: dk(0), debi: 4.0),
    ];
    final sonuc = tedaviBasarisiniHesapla(gecmis);
    expect(sonuc.tamamlananSayisi, 0);
    expect(sonuc.basariOrani, 0.0);
  });

  test('debi referansa (toleransla) dondugunde basarili sayilir', () {
    final kronolojik = [
      _okuma(zaman: dk(0), debi: 4.0),
      _okuma(zaman: dk(1), debi: 2.0, tedavi: TedaviTuru.asitDozlama),
      _okuma(zaman: dk(2), debi: 3.0, durulama: true),
      _okuma(zaman: dk(3), debi: 4.1), // referansdan +0.1 -- basarili
    ];
    final sonuc = tedaviBasarisiniHesapla(kronolojik.reversed.toList());

    expect(sonuc.tamamlananSayisi, 1);
    expect(sonuc.basariliSayisi, 1);
    expect(sonuc.basariOrani, 1.0);
  });

  test('debi referanstan tolerans disi kaldiginda basarisiz sayilir', () {
    final kronolojik = [
      _okuma(zaman: dk(0), debi: 4.0),
      _okuma(zaman: dk(1), debi: 1.5, tedavi: TedaviTuru.yuksekBasincliYikama),
      _okuma(zaman: dk(2), debi: 2.0, durulama: true),
      _okuma(zaman: dk(3), debi: 2.2), // referanstan -1.8 -- basarisiz
    ];
    final sonuc = tedaviBasarisiniHesapla(kronolojik.reversed.toList());

    expect(sonuc.tamamlananSayisi, 1);
    expect(sonuc.basariliSayisi, 0);
    expect(sonuc.basariOrani, 0.0);
  });

  test('iki zonun sonucu birlestir ile dogru toplanir', () {
    const zon1 = TedaviBasariAnalizi(tamamlananSayisi: 3, basariliSayisi: 2);
    const zon2 = TedaviBasariAnalizi(tamamlananSayisi: 1, basariliSayisi: 1);

    final birlesik = TedaviBasariAnalizi.birlestir([zon1, zon2]);

    expect(birlesik.tamamlananSayisi, 4);
    expect(birlesik.basariliSayisi, 3);
    expect(birlesik.basariOrani, 0.75);
  });
}
