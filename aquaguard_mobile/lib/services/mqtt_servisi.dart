/// AquaGuard - MQTT Servis Katmani
/// ===================================
///
/// Amac:
///   Firmware (veya gelistirme asamasinda mock yayinci) tarafindan
///   yayinlanan sensor/teshis verisini dinler ve Dart nesnelerine
///   cevirerek uygulamanin geri kalanina (Provider katmani) iletir.
///
///   Platform farki (Web vs Mobil/Masaustu) mqtt_istemci_factory.dart
///   dosyasindaki kosullu ithalat ile cozulur; bu dosya hangi platformda
///   calistigini bilmeden ayni kodu kullanir.
///
/// Konu (topic) semasi (firmware/mqtt_handler.h ile ayni):
///   aquaguard/zone{N}/veri   -> JSON sensor/teshis verisi (retained)
///   aquaguard/zone{N}/durum  -> "online" / "offline"
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mqtt_client/mqtt_client.dart';

import '../config/ayarlar_sabitleri.dart';
import '../models/sensor_okuma.dart';
import 'mqtt_istemci_factory.dart';

/// MQTT baglanti durumu (UI'da "cevrimici / cevrimdisi / baglaniyor" gostermek icin)
enum MqttBaglantiDurumu { baglaniyor, bagli, baglantiKesildi, hata }

class MqttServisi {
  MqttClient? _istemci;

  final void Function(SensorOkuma okuma) veriGeldiginde;
  final void Function(int zone, bool cevrimici) zonDurumuDegistiginde;
  final void Function(MqttBaglantiDurumu durum) baglantiDurumuDegistiginde;

  MqttServisi({
    required this.veriGeldiginde,
    required this.zonDurumuDegistiginde,
    required this.baglantiDurumuDegistiginde,
  });

  bool get bagliMi =>
      _istemci?.connectionStatus?.state == MqttConnectionState.connected;

  /// Belirtilen brokera baglanir ve verilen zon numaralarinin konularina abone olur.
  /// Basarili olursa true, olmazsa false doner (hata firlatmaz -- UI'da
  /// "baglanamadi" mesaji gostermek daha kullanici dostu).
  Future<bool> baglan({
    required String host,
    required int port,
    required List<int> zonlar,
  }) async {
    baglantiDurumuDegistiginde(MqttBaglantiDurumu.baglaniyor);

    // MQTT 3.1.1 standardi, brokerlarin garanti kabul etmesi gereken
    // client-id uzunlugunu 23 karakterle sinirlar -- bazi brokerlar daha
    // uzununu reddeder. "aq" + son 10 basamak (saniyenin ~100000'de biri
    // hassasiyetinde, pratikte benzersiz) toplam 12 karakterdir.
    final clientId = 'aq${DateTime.now().millisecondsSinceEpoch % 10000000000}';

    final istemci = mqttIstemciOlustur(
      host: host,
      port: port,
      clientId: clientId,
    );

    istemci.keepAlivePeriod = 30;
    istemci.autoReconnect = true;
    istemci.resubscribeOnAutoReconnect = true;
    istemci.onDisconnected = () {
      baglantiDurumuDegistiginde(MqttBaglantiDurumu.baglantiKesildi);
    };
    istemci.onConnected = () {
      baglantiDurumuDegistiginde(MqttBaglantiDurumu.bagli);
    };
    istemci.logging(on: false);

    istemci.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    try {
      await istemci.connect();
    } on Exception catch (hata) {
      debugPrint('[AquaGuard/MQTT] Bağlantı istisnası: $hata');
      istemci.disconnect();
      baglantiDurumuDegistiginde(MqttBaglantiDurumu.hata);
      return false;
    }

    if (istemci.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('[AquaGuard/MQTT] Bağlantı kurulamadı: ${istemci.connectionStatus}');
      baglantiDurumuDegistiginde(MqttBaglantiDurumu.hata);
      return false;
    }

    debugPrint('[AquaGuard/MQTT] Bağlandı: $host:$port (zonlar: $zonlar)');
    _istemci = istemci;
    baglantiDurumuDegistiginde(MqttBaglantiDurumu.bagli);

    for (final zon in zonlar) {
      istemci.subscribe(AyarlarSabitleri.veriKonusu(zon), MqttQos.atLeastOnce);
      istemci.subscribe(AyarlarSabitleri.durumKonusu(zon), MqttQos.atLeastOnce);
    }

    istemci.updates?.listen(_mesajlariIsle);

    return true;
  }

  /// Uygulama calisirken yeni bir zon eklendiginde (ornegin yeni tarla
  /// olusturuldugunda) mevcut baglantiya ek abonelik acar.
  void zonuAbonelikleEkle(int zon) {
    final istemci = _istemci;
    if (istemci == null || !bagliMi) return;
    istemci.subscribe(AyarlarSabitleri.veriKonusu(zon), MqttQos.atLeastOnce);
    istemci.subscribe(AyarlarSabitleri.durumKonusu(zon), MqttQos.atLeastOnce);
  }

  void _mesajlariIsle(List<MqttReceivedMessage<MqttMessage>> olaylar) {
    for (final olay in olaylar) {
      final yayinMesaji = olay.payload as MqttPublishMessage;
      final metin = MqttPublishPayload.bytesToStringAsString(
        yayinMesaji.payload.message,
      );
      final konu = olay.topic;

      if (konu.endsWith('/veri')) {
        _veriMesajiniIsle(metin);
      } else if (konu.endsWith('/durum')) {
        _durumMesajiniIsle(konu, metin);
      }
    }
  }

  void _veriMesajiniIsle(String metin) {
    try {
      final json = jsonDecode(metin) as Map<String, dynamic>;
      veriGeldiginde(SensorOkuma.fromJson(json));
    } on FormatException {
      // Bozuk/eksik JSON -- sessizce yoksay, bir sonraki mesaj gelecektir.
    }
  }

  void _durumMesajiniIsle(String konu, String metin) {
    final zon = _konudanZonNumarasiCikar(konu);
    if (zon == null) return;
    zonDurumuDegistiginde(zon, metin.trim() == 'online');
  }

  int? _konudanZonNumarasiCikar(String konu) {
    final eslesme = RegExp(r'zone(\d+)').firstMatch(konu);
    if (eslesme == null) return null;
    return int.tryParse(eslesme.group(1)!);
  }

  void baglantiyiKapat() {
    _istemci?.disconnect();
    _istemci = null;
  }
}
