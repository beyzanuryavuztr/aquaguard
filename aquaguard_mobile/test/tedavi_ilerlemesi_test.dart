// AquaGuard - TedaviIlerlemesi.hesapla Testleri
//
// AktifTedaviEkrani ve AktifTedavilerBolumu'nun paylastigi tek ilerleme
// hesabi -- baslangic zamani null/gecmis/simdi durumlarinda dogru
// oran/kalan-sure uretilip uretilmedigini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tedavi_ilerlemesi.dart';

void main() {
  test('baslangic null ise oran 0, kalan sure toplam sureye esit', () {
    final sonuc = TedaviIlerlemesi.hesapla(
      tedavi: TedaviTuru.asitDozlama,
      baslangic: null,
    );

    expect(sonuc.oran, 0.0);
    expect(sonuc.kalanSaniye, sonuc.toplamSaniye);
    expect(sonuc.toplamSaniye, 30); // AyarlarSabitleri.tedaviSuresiSaniye
  });

  test('baslangictan bu yana gecen sure toplam sureyi asarsa oran 1.0da sabitlenir', () {
    final cokEskiBaslangic = DateTime.now().subtract(const Duration(hours: 1));

    final sonuc = TedaviIlerlemesi.hesapla(
      tedavi: TedaviTuru.yuksekBasincliYikama,
      baslangic: cokEskiBaslangic,
    );

    expect(sonuc.oran, 1.0);
    expect(sonuc.kalanSaniye, 0);
  });

  test('tedavi yeni basladiysa oran 0a yakin, kalan sure toplam sureye yakin olur', () {
    final simdi = DateTime.now();

    final sonuc = TedaviIlerlemesi.hesapla(
      tedavi: TedaviTuru.klorEnjeksiyon,
      baslangic: simdi,
    );

    expect(sonuc.oran, closeTo(0.0, 0.1));
    expect(sonuc.kalanSaniye, closeTo(30, 3));
  });
}
