// AquaGuard - tedaviOncesiSonrasiBul Testleri
//
// Zon Detay'daki "Son Tedavi Etkisi" kartinin dayandigi saf fonksiyon.
// Tedavi asamasinin bitisi (tedaviAktif->yok) ile zorunlu durulamanin
// GERCEKTEN bitisinin (durulamaAktif->false) FARKLI anlar oldugunu, ve
// fonksiyonun ikisini de dogru ayirt ettigini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tedavi_karsilastirmasi.dart';

SensorOkuma _okuma({
  required DateTime zaman,
  required double debi,
  TedaviTuru tedavi = TedaviTuru.yok,
  bool durulama = false,
  TeshisDurumu durum = TeshisDurumu.normal,
}) => SensorOkuma(
  zaman: zaman,
  zone: 1,
  ph: 7.0,
  ec: 1.1,
  orp: 350,
  turbidite: 3,
  debi: debi,
  deltaBasinc: 0.1,
  durum: durum,
  tikanmaTuru: TikanmaTuru.yok,
  guven: 100,
  tedaviAktif: tedavi,
  durulamaAktif: durulama,
);

void main() {
  final t0 = DateTime(2026, 9, 4, 10, 0);
  DateTime dk(int n) => t0.add(Duration(minutes: n));

  test('2den az kayit varsa null doner', () {
    expect(tedaviOncesiSonrasiBul([]), isNull);
    expect(tedaviOncesiSonrasiBul([_okuma(zaman: t0, debi: 4.0)]), isNull);
  });

  test('hic tedavi tetiklenmemisse null doner', () {
    final gecmis = [
      _okuma(zaman: dk(2), debi: 4.1),
      _okuma(zaman: dk(1), debi: 4.0),
      _okuma(zaman: dk(0), debi: 4.0),
    ]; // zaten en yeni once sirali

    expect(tedaviOncesiSonrasiBul(gecmis), isNull);
  });

  test(
    'tedavi + durulama TAM tamamlandiysa once/sonra debiyi ve baslangic zamanini dogru bulur',
    () {
      // Kronolojik (eskiden yeniye) senaryo:
      // 0: normal, debi 4.0
      // 1: tespit edildi, debi 2.0            <- tedavi baslamadan hemen once
      // 2: tedavi (asit), debi 2.0            <- tedavi basladi
      // 3: tedavi (asit), debi 2.6
      // 4: durulama (tedaviAktif=yok), debi 3.2   <- tedavi bitti, durulama basladi
      // 5: durulama (tedaviAktif=yok), debi 3.6   <- durulama hala suruyor
      // 6: normal (tedaviAktif=yok, durulama=false), debi 4.0  <- TAM tamamlandi
      final kronolojik = [
        _okuma(zaman: dk(0), debi: 4.0),
        _okuma(
          zaman: dk(1),
          debi: 2.0,
          durum: TeshisDurumu.tespitEdildi,
        ),
        _okuma(zaman: dk(2), debi: 2.0, tedavi: TedaviTuru.asitDozlama),
        _okuma(zaman: dk(3), debi: 2.6, tedavi: TedaviTuru.asitDozlama),
        _okuma(zaman: dk(4), debi: 3.2, durulama: true),
        _okuma(zaman: dk(5), debi: 3.6, durulama: true),
        _okuma(zaman: dk(6), debi: 4.0),
      ];
      final enYeniOnce = kronolojik.reversed.toList();

      final sonuc = tedaviOncesiSonrasiBul(enYeniOnce);

      expect(sonuc, isNotNull);
      expect(sonuc!.onceDebi, 2.0); // tedavi baslamadan hemen onceki deger
      expect(sonuc.sonraDebi, 4.0); // durulama TAM bittikten sonraki deger
      expect(sonuc.tedaviBaslangicZamani, dk(2));
    },
  );

  test(
    'tedavi bitti ama durulama elimizdeki veri icinde HENUZ tamamlanmadiysa null doner',
    () {
      final kronolojik = [
        _okuma(zaman: dk(0), debi: 4.0),
        _okuma(zaman: dk(1), debi: 2.0, tedavi: TedaviTuru.klorEnjeksiyon),
        _okuma(zaman: dk(2), debi: 3.0, durulama: true), // hala suruyor
      ];
      final enYeniOnce = kronolojik.reversed.toList();

      expect(tedaviOncesiSonrasiBul(enYeniOnce), isNull);
    },
  );

  test('tedavi baslamadan onceki kayit yoksa (baslangic en bastaysa) null doner', () {
    final kronolojik = [
      _okuma(
        zaman: dk(0),
        debi: 2.0,
        tedavi: TedaviTuru.yuksekBasincliYikama,
      ),
      _okuma(zaman: dk(1), debi: 4.0),
    ];
    final enYeniOnce = kronolojik.reversed.toList();

    expect(tedaviOncesiSonrasiBul(enYeniOnce), isNull);
  });
}
