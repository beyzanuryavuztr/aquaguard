// AquaGuard - MQTT kimlik bilgisi testleri (D1)
//
// Kullanici adi/parolanin kaydedildigini, null parolanin mevcut parolayi
// KORUDUGUNU, bos kullanici adinin kimligi sildigini ve arayuzun TLS
// kapaliyken uyari gosterdigini dogrular. Demo Modu acik (varsayilan)
// oldugu icin gercek bir ag baglantisi KURULMAZ.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquaguard_mobile/providers/uygulama_durumu.dart';
import 'package:aquaguard_mobile/widgets/ayarlar/mqtt_baglanti_karti.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'kimlik kaydedilir, null parola korur, bos kullanici adi siler',
    () async {
      final durum = UygulamaDurumu();
      await durum.baslat();
      final cihaz = durum.cihazProvider;

      await cihaz.mqttAyarlariniGuncelle(
        host: 'broker.ornek',
        port: 8883,
        guvenli: true,
        kullaniciAdi: 'operator',
        parola: 'gizli',
      );
      expect(cihaz.mqttKullaniciAdi, 'operator');
      expect(cihaz.mqttParolaTanimli, isTrue);

      // Parola verilmezse (null) mevcut parola korunur.
      await cihaz.mqttAyarlariniGuncelle(
        host: 'broker.ornek',
        port: 8883,
        guvenli: true,
        kullaniciAdi: 'operator2',
      );
      expect(cihaz.mqttKullaniciAdi, 'operator2');
      expect(cihaz.mqttParolaTanimli, isTrue);

      // Eski tarz cagri (kimlik parametresiz) kimligi SILMEZ.
      await cihaz.mqttAyarlariniGuncelle(
        host: 'broker.ornek',
        port: 8883,
        guvenli: true,
      );
      expect(cihaz.mqttKullaniciAdi, 'operator2');

      // Bos kullanici adi kimligi tamamen siler (anonim).
      await cihaz.mqttAyarlariniGuncelle(
        host: 'broker.ornek',
        port: 8883,
        guvenli: true,
        kullaniciAdi: '',
      );
      expect(cihaz.mqttKullaniciAdi, isEmpty);
      expect(cihaz.mqttParolaTanimli, isFalse);

      durum.dispose();
    },
  );

  testWidgets('kullanici adi girilip TLS kapaliyken uyari gorunur', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final durum = UygulamaDurumu();
    await durum.baslat();

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
    expect(find.textContaining('şifresiz gider'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kullanıcı Adı (opsiyonel)'),
      'operator',
    );
    await tester.pump();

    expect(find.textContaining('şifresiz gider'), findsOneWidget);
    durum.dispose();
  });
}
