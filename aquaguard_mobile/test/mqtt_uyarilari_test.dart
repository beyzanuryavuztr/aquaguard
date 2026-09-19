// AquaGuard - MQTT guvenlik uyarilari testleri (K4 + Y4)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/models/mqtt_uyarilari.dart';
import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/widgets/ayarlar/mqtt_baglanti_karti.dart';

void main() {
  group('genelBrokerUyarisi', () {
    test('herkese acik test broker\'larinda uyari verir', () {
      expect(genelBrokerUyarisi('test.mosquitto.org'), isNotNull);
      expect(genelBrokerUyarisi('  BROKER.HIVEMQ.COM '), isNotNull);
      expect(genelBrokerUyarisi('broker.emqx.io'), isNotNull);
      expect(genelBrokerUyarisi('mosquitto.org'), isNotNull);
    });

    test('kendi broker\'inda ve bos adreste uyari vermez', () {
      expect(genelBrokerUyarisi('mqtt.ciftligim.com'), isNull);
      expect(genelBrokerUyarisi('192.168.1.20'), isNull);
      expect(genelBrokerUyarisi(''), isNull);
    });

    test('benzer ama farkli alan adlarini YANLIS eslestirmez', () {
      expect(genelBrokerUyarisi('notmosquitto.org.evil.com'), isNull);
      expect(genelBrokerUyarisi('fakemosquitto.org'), isNull);
    });
  });

  group('webTlsUyarisi', () {
    test('web + https + TLS kapali -> uyari', () {
      expect(webTlsUyarisi(web: true, https: true, guvenli: false), isNotNull);
    });

    test('TLS aciksa, https degilse ya da web degilse uyari yok', () {
      expect(webTlsUyarisi(web: true, https: true, guvenli: true), isNull);
      expect(webTlsUyarisi(web: true, https: false, guvenli: false), isNull);
      expect(webTlsUyarisi(web: false, https: true, guvenli: false), isNull);
    });
  });

  testWidgets('genel broker adresi girilince uyari kutusu gorunur', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({'aquaguard_demo_modu_acik': false});
    final durum = UygulamaDurumu();
    await tester.runAsync(() => durum.baslat());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: durum.cihazProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: MqttBaglantiKarti()),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Broker Adresi'),
      'mqtt.ciftligim.com',
    );
    await tester.pump();
    expect(find.textContaining('TEST broker'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Broker Adresi'),
      'test.mosquitto.org',
    );
    await tester.pump();
    expect(find.textContaining('TEST broker'), findsOneWidget);
    durum.dispose();
  });
}
