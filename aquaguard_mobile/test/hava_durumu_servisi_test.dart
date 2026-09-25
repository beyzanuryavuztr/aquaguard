// AquaGuard - HavaDurumuServisi Testleri (Faz 4)
//
// Gercek aga HIC cikmaz -- package:http/testing.dart MockClient ile
// enjekte edilen sahte yanitlar kullanilir. Basari, HTTP hatasi, zaman
// asimi ve bozuk JSON senaryolarinin hepsi UYGULAMAYI COKERTMEDEN null'a
// dustugunu dogrular (bkz. hava_durumu_servisi.dart durustluk notu).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aquaguard_mobile/services/hava_durumu_servisi.dart';

void main() {
  group('HavaDurumuServisi.tahminGetir', () {
    test('200 + gecerli JSON -> dogru HavaTahmini doner', () async {
      final istemci = MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.queryParameters['latitude'], '37.16');
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-09-25', '2026-09-26'],
              'temperature_2m_max': [30.0, 32.0],
              'temperature_2m_min': [18.0, 19.0],
              'precipitation_probability_max': [10, 20],
              'precipitation_sum': [0.0, 0.0],
            },
          }),
          200,
        );
      });

      final sonuc = await HavaDurumuServisi.tahminGetir(
        enlem: 37.16,
        boylam: 38.79,
        istemci: istemci,
      );

      expect(sonuc, isNotNull);
      expect(sonuc!.gunlukTahminler, hasLength(2));
      expect(sonuc.yarin?.maksSicaklikC, 32.0);
    });

    test('HTTP hata kodu (orn. 500) -> null doner, istisna FIRLATMAZ', () async {
      final istemci = MockClient((request) async {
        return http.Response('Sunucu hatasi', 500);
      });

      final sonuc = await HavaDurumuServisi.tahminGetir(
        enlem: 0,
        boylam: 0,
        istemci: istemci,
      );

      expect(sonuc, isNull);
    });

    test('bozuk/gecersiz JSON -> null doner, istisna FIRLATMAZ', () async {
      final istemci = MockClient((request) async {
        return http.Response('bu JSON degil {{{', 200);
      });

      final sonuc = await HavaDurumuServisi.tahminGetir(
        enlem: 0,
        boylam: 0,
        istemci: istemci,
      );

      expect(sonuc, isNull);
    });

    test('ag istisnasi (baglanti hatasi) -> null doner, istisna FIRLATMAZ', () async {
      final istemci = MockClient((request) async {
        throw const SocketExceptionStub();
      });

      final sonuc = await HavaDurumuServisi.tahminGetir(
        enlem: 0,
        boylam: 0,
        istemci: istemci,
      );

      expect(sonuc, isNull);
    });
  });
}

/// http.ClientException yerine kullanilabilecek, dart:io'ya bagimli
/// olmayan basit bir istisna stub'i (SocketException importu web/io
/// platform ayrimi gerektirebilir, testin kendisi platformdan bagimsiz
/// kalsin diye).
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketExceptionStub: baglanti kurulamadi (test)';
}
