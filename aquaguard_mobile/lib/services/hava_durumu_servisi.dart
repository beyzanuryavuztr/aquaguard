/// AquaGuard - Hava Durumu Servisi (Faz 4, 2026-09-25)
/// =========================================================
///
/// Amac:
///   Open-Meteo'nun ucretsiz, API-anahtarsiz tahmin uc noktasindan
///   (https://open-meteo.com/en/docs) bir tarlanin GPS konumu icin 3
///   gunluk gunluk tahmin ceker. SADECE Tarla.gpsKonumuVarMi true olan
///   ciftlikler icin anlamlidir -- konum yoksa cagrilmaz (bkz.
///   widgets/sulama_onerisi_karti.dart).
///
///   DURUSTLUK/DAYANIKLILIK: bu, uygulamanin TEK gercek zamanli harici
///   ag bagimliligidir (MQTT haricinde). Baglanti/servis hatasinda
///   İSTİSNA FIRLATMAZ -- null doner, cagiran taraf "hava durumu su an
///   alinamadi" gibi noturmluk bir durum gosterir, UYGULAMA COKMEZ.
///   Onbellege ALINMAZ (kasitli, kucuk kapsam) -- her cagrida taze
///   veri cekilir; sik cagrilmamasi cagiran tarafin sorumlulugundadir.
///
/// Tarih:  2026-09-25
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hava_tahmini.dart';

class HavaDurumuServisi {
  HavaDurumuServisi._();

  static const _zamanAsimi = Duration(seconds: 10);

  /// [istemci] test icin enjekte edilebilir (bkz. test/hava_durumu_servisi_test.dart
  /// -- package:http/testing.dart MockClient) -- verilmezse gercek ag istegi
  /// yapan varsayilan bir http.Client kullanilir.
  static Future<HavaTahmini?> tahminGetir({
    required double enlem,
    required double boylam,
    http.Client? istemci,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': enlem.toString(),
      'longitude': boylam.toString(),
      'daily':
          'temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum',
      'forecast_days': '3',
      'timezone': 'auto',
    });

    final gercekIstemciMi = istemci == null;
    final kullanilacakIstemci = istemci ?? http.Client();
    try {
      final yanit = await kullanilacakIstemci.get(uri).timeout(_zamanAsimi);
      if (yanit.statusCode != 200) {
        return null;
      }
      final json = jsonDecode(yanit.body) as Map<String, dynamic>;
      return HavaTahmini.fromOpenMeteoJson(json, enlem: enlem, boylam: boylam);
    } catch (_) {
      // Ag hatasi, zaman asimi, JSON ayristirma hatasi -- hepsi ayni
      // sekilde ele alinir: sessizce null, uygulama normal (hava durumu
      // olmadan) calismaya devam eder.
      return null;
    } finally {
      // SADECE kendi olusturdugumuz (test tarafindan enjekte edilmemis)
      // istemciyi kapatiyoruz -- MockClient gibi enjekte edilmis bir
      // istemcinin yasam dongusu cagiranin sorumlulugundadir.
      if (gercekIstemciMi) kullanilacakIstemci.close();
    }
  }
}
