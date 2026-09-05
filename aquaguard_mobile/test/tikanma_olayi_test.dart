// AquaGuard - tikanmaOlaylariniBul Testleri
//
// Tedavi Geçmişi ekranındaki filtrelenebilir olay günlüğünün dayandığı
// saf fonksiyon -- aynı devam eden tespitin TEKRAR TEKRAR değil, sadece
// BAŞLANGIÇ anında bir olay ürettiğini dogrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tikanma_olayi.dart';

SensorOkuma _okuma({
  required DateTime zaman,
  TeshisDurumu durum = TeshisDurumu.normal,
  TikanmaTuru tur = TikanmaTuru.yok,
  double guven = 100,
}) => SensorOkuma(
  zaman: zaman,
  zone: 2,
  ph: 7.0,
  ec: 1.1,
  orp: 350,
  turbidite: 3,
  debi: 4.0,
  deltaBasinc: 0.1,
  durum: durum,
  tikanmaTuru: tur,
  guven: guven,
  tedaviAktif: TedaviTuru.yok,
  durulamaAktif: false,
);

void main() {
  final t0 = DateTime(2026, 9, 5, 9, 0);
  DateTime dk(int n) => t0.add(Duration(minutes: n));

  test('bos gecmiste hic olay uretmez', () {
    expect(tikanmaOlaylariniBul([]), isEmpty);
  });

  test('hic tespit yoksa hic olay uretmez', () {
    final kronolojik = [
      _okuma(zaman: dk(0)),
      _okuma(zaman: dk(1)),
    ];
    expect(tikanmaOlaylariniBul(kronolojik), isEmpty);
  });

  test('devam eden AYNI tespit sadece BASLANGIC aninda bir olay uretir', () {
    final kronolojik = [
      _okuma(zaman: dk(0)),
      _okuma(
        zaman: dk(1),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.kimyasal,
        guven: 80,
      ),
      _okuma(
        zaman: dk(2),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.kimyasal,
        guven: 85,
      ),
      _okuma(
        zaman: dk(3),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.kimyasal,
        guven: 88,
      ),
    ];

    final olaylar = tikanmaOlaylariniBul(kronolojik).toList();

    expect(olaylar.length, 1);
    expect(olaylar.first.zaman, dk(1));
    expect(olaylar.first.tur, TikanmaTuru.kimyasal);
    expect(olaylar.first.guven, 80);
  });

  test('iki AYRI tespit episodu iki ayri olay uretir', () {
    final kronolojik = [
      _okuma(zaman: dk(0)),
      _okuma(
        zaman: dk(1),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.biyolojik,
      ),
      _okuma(zaman: dk(2)), // normale donus
      _okuma(
        zaman: dk(3),
        durum: TeshisDurumu.tespitEdildi,
        tur: TikanmaTuru.fiziksel,
      ),
    ];

    final olaylar = tikanmaOlaylariniBul(kronolojik).toList();

    expect(olaylar.length, 2);
    expect(olaylar[0].tur, TikanmaTuru.biyolojik);
    expect(olaylar[1].tur, TikanmaTuru.fiziksel);
  });
}
