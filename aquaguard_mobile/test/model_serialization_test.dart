// AquaGuard - Model Serilestirme Testleri
//
// SensorOkuma/Tarla/AktiviteKaydi, DepolamaServisi (SharedPreferences)
// araciligiyla JSON'a cevrilip geri okunuyor. Bu round-trip'te bir hata
// olursa, kullanicinin gecmisi/aktivite kaydi/tarla listesi SESSIZCE
// bozulur veya sifirlanir -- bu yuzden en az bir test onceden hic
// yoktu, simdi ekleniyor.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/aktivite_kaydi.dart';
import 'package:aquaguard_mobile/models/sensor_okuma.dart';
import 'package:aquaguard_mobile/models/tarla.dart';
import 'package:aquaguard_mobile/models/tarla_notu.dart';

void main() {
  group('SensorOkuma round-trip', () {
    final ornek = SensorOkuma(
      zaman: DateTime(2026, 9, 2, 14, 30, 5),
      zone: 3,
      ph: 6.62,
      ec: 1.50,
      orp: 175,
      turbidite: 20.5,
      debi: 3.0,
      deltaBasinc: 0.32,
      durum: TeshisDurumu.tespitEdildi,
      tikanmaTuru: TikanmaTuru.biyolojik,
      guven: 94.2,
      guvenKimyasal: 3.1,
      guvenBiyolojik: 94.2,
      guvenFiziksel: 2.7,
      tedaviAktif: TedaviTuru.klorEnjeksiyon,
      durulamaAktif: false,
    );

    test('toJson -> fromCacheJson tum alanlari korur (DepolamaServisi yolu)', () {
      final geriYuklenen = SensorOkuma.fromCacheJson(ornek.toJson());

      expect(geriYuklenen.zone, ornek.zone);
      expect(geriYuklenen.ph, ornek.ph);
      expect(geriYuklenen.ec, ornek.ec);
      expect(geriYuklenen.orp, ornek.orp);
      expect(geriYuklenen.turbidite, ornek.turbidite);
      expect(geriYuklenen.debi, ornek.debi);
      expect(geriYuklenen.deltaBasinc, ornek.deltaBasinc);
      expect(geriYuklenen.durum, ornek.durum);
      expect(geriYuklenen.tikanmaTuru, ornek.tikanmaTuru);
      expect(geriYuklenen.guven, ornek.guven);
      expect(geriYuklenen.guvenKimyasal, ornek.guvenKimyasal);
      expect(geriYuklenen.guvenBiyolojik, ornek.guvenBiyolojik);
      expect(geriYuklenen.guvenFiziksel, ornek.guvenFiziksel);
      expect(geriYuklenen.tedaviAktif, ornek.tedaviAktif);
      expect(geriYuklenen.durulamaAktif, ornek.durulamaAktif);
      expect(geriYuklenen.zaman, ornek.zaman);
    });

    test('fromJson (MQTT semasi) firmware/mock formatini dogru ayristirir', () {
      final mqttJson = {
        'zaman': '2026-09-02 14:30:05',
        'zone': 3,
        'ph': 6.62,
        'ec': 1.50,
        'orp': 175,
        'turbidite': 20.5,
        'debi': 3.0,
        'delta_basinc': 0.32,
        'durum': 'tespit_edildi',
        'tikanma_turu': 'biyolojik',
        'guven': 94.2,
        'guven_kimyasal': 3.1,
        'guven_biyolojik': 94.2,
        'guven_fiziksel': 2.7,
        'tedavi_aktif': 'klor_enjeksiyon',
        'durulama_aktif': false,
      };

      final okuma = SensorOkuma.fromJson(mqttJson);

      expect(okuma.zone, 3);
      expect(okuma.durum, TeshisDurumu.tespitEdildi);
      expect(okuma.tikanmaTuru, TikanmaTuru.biyolojik);
      expect(okuma.tedaviAktif, TedaviTuru.klorEnjeksiyon);
      expect(okuma.guvenBiyolojik, 94.2);
      // Firmware/mock "YYYY-MM-DD HH:MM:SS" gonderir (ISO degil) -- 'T' eklenerek ayristirilmali.
      expect(okuma.zaman, DateTime(2026, 9, 2, 14, 30, 5));
    });

    test('eksik guven_* alanlari varsayilan 0.0 olarak ayristirilir (geriye donuk uyum)', () {
      final eskiSemaJson = {
        'zaman': '2026-09-02 14:30:05',
        'zone': 1,
        'ph': 7.0,
        'ec': 1.15,
        'orp': 375,
        'turbidite': 3,
        'debi': 4.0,
        'delta_basinc': 0.10,
        'durum': 'normal',
        'tikanma_turu': 'yok',
        'guven': 100.0,
        'tedavi_aktif': 'yok',
        'durulama_aktif': false,
      };

      final okuma = SensorOkuma.fromJson(eskiSemaJson);
      expect(okuma.guvenKimyasal, 0.0);
      expect(okuma.guvenBiyolojik, 0.0);
      expect(okuma.guvenFiziksel, 0.0);
    });
  });

  group('Tarla round-trip', () {
    test('toJson -> fromJson tum alanlari korur (profil alanlari dahil)', () {
      const tarla = Tarla(
        id: 'tarla-2',
        ad: 'Güney Tarlası',
        zonNumaralari: [4, 5],
        konum: 'Şanlıurfa, Akçakale',
        aciklama: 'Mısır ekili',
        fotografBase64: 'aGVsbG8=',
      );
      final geriYuklenen = Tarla.fromJson(tarla.toJson());

      expect(geriYuklenen.id, tarla.id);
      expect(geriYuklenen.ad, tarla.ad);
      expect(geriYuklenen.zonNumaralari, tarla.zonNumaralari);
      expect(geriYuklenen.konum, tarla.konum);
      expect(geriYuklenen.aciklama, tarla.aciklama);
      expect(geriYuklenen.fotografBase64, tarla.fotografBase64);
    });

    test('profil alanlari opsiyoneldir, verilmezse null kalir', () {
      const tarla = Tarla(id: 'tarla-x', ad: 'Boş Tarla', zonNumaralari: [9]);
      final geriYuklenen = Tarla.fromJson(tarla.toJson());

      expect(geriYuklenen.konum, isNull);
      expect(geriYuklenen.aciklama, isNull);
      expect(geriYuklenen.fotografBase64, isNull);
    });

    test('kopyalaVeGuncelle fotografiKaldir:true ile fotografi temizler', () {
      const tarla = Tarla(
        id: 'tarla-3',
        ad: 'Sera',
        zonNumaralari: [6],
        fotografBase64: 'aGVsbG8=',
      );
      final guncellenen = tarla.kopyalaVeGuncelle(fotografiKaldir: true);

      expect(guncellenen.fotografBase64, isNull);
      expect(guncellenen.ad, tarla.ad); // digger alanlar etkilenmemeli
    });

    test('varsayilanListe() 3 tarla ve toplam 6 tekil zon icerir, hepsinin konum/aciklamasi var', () {
      final liste = Tarla.varsayilanListe();
      expect(liste.length, 3);

      final tumZonlar = liste.expand((t) => t.zonNumaralari).toList();
      expect(tumZonlar.toSet().length, tumZonlar.length, reason: 'zon numaralari tekil olmali');
      expect(tumZonlar.length, 6);

      for (final tarla in liste) {
        expect(tarla.konum, isNotNull);
        expect(tarla.aciklama, isNotNull);
      }
    });
  });

  group('TarlaNotu round-trip', () {
    test('toJson -> fromJson tum alanlari korur', () {
      final not = TarlaNotu(
        id: 'not-1',
        tarlaId: 'tarla-2',
        metin: '15.09 gübreleme yapıldı',
        zaman: DateTime(2026, 9, 15, 9, 30),
      );
      final geriYuklenen = TarlaNotu.fromJson(not.toJson());

      expect(geriYuklenen.id, not.id);
      expect(geriYuklenen.tarlaId, not.tarlaId);
      expect(geriYuklenen.metin, not.metin);
      expect(geriYuklenen.zaman, not.zaman);
    });
  });

  group('AktiviteKaydi round-trip', () {
    test('toJson -> fromJson tum alanlari korur', () {
      final kayit = AktiviteKaydi(
        zaman: DateTime(2026, 9, 2, 10),
        zone: 5,
        mesaj: 'Zon 5: Kimyasal tıkanma tespit edildi',
        tur: AktiviteTuru.tespit,
      );

      final geriYuklenen = AktiviteKaydi.fromJson(kayit.toJson());

      expect(geriYuklenen.zone, kayit.zone);
      expect(geriYuklenen.mesaj, kayit.mesaj);
      expect(geriYuklenen.tur, kayit.tur);
      expect(geriYuklenen.zaman, kayit.zaman);
    });
  });
}
