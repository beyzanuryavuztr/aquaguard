// AquaGuard - Sema v2 (ACK/NACK) Testleri
//
// MqttServisi.komutGonder()'in baglanti YOKKEN bile cokmeden bir komut_id
// urettigini (UygulamaDurumu._komutGonderVeOnayBekle bunu zaman asimina
// birakir, coke degil) ve uretilen id'lerin benzersiz oldugunu dogrular.
// Gercek bir MQTT baglantisi GEREKTIRMEZ -- bu proje daha once gercek
// MQTT-over-WebSocket baglantisinin bu ortamda guvenilmez oldugunu
// gozlemlemisti (bkz. proje hafizasi), bu yuzden bu testler bilerek
// aga hic cikmayan yollari kapsar.

import 'package:flutter_test/flutter_test.dart';

import 'package:aquaguard_mobile/models/bekleyen_komut.dart';
import 'package:aquaguard_mobile/services/mqtt_servisi.dart';

void main() {
  group('KomutSonucu', () {
    test('tam olarak 3 deger tasir', () {
      expect(KomutSonucu.values.length, 3);
      expect(KomutSonucu.values, contains(KomutSonucu.uygulandi));
      expect(KomutSonucu.values, contains(KomutSonucu.reddedildi));
      expect(KomutSonucu.values, contains(KomutSonucu.zamanAsimi));
    });
  });

  group('MqttServisi.komutGonder (baglanti kurulmadan)', () {
    late MqttServisi servis;

    setUp(() {
      servis = MqttServisi(
        veriGeldiginde: (_) {},
        zonDurumuDegistiginde: (_, _) {},
        baglantiDurumuDegistiginde: (_) {},
      );
    });

    test('baglanti hic kurulmamisken bile bir komut_id doner, cokmez', () {
      final id = servis.komutGonder(1, {'komut': 'tedavi_baslat'});
      expect(id, isNotEmpty);
    });

    test('ardisik cagrilar BENZERSIZ komut_id uretir', () {
      final id1 = servis.komutGonder(1, {'komut': 'tedavi_baslat'});
      final id2 = servis.komutGonder(1, {'komut': 'tedavi_durdur'});
      expect(id1, isNot(equals(id2)));
    });

    test('bagliMi baglanti kurulmadan false doner', () {
      expect(servis.bagliMi, isFalse);
    });
  });
}
