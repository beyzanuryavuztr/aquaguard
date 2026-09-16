/// AquaGuard - MQTT Istemcisi (Mobil / Masaustu -- dart:io platformlari)
/// =========================================================================
///
/// Mobil ve masaustu platformlarda dart:io soketleri kullanilabildigi icin
/// dogrudan TCP uzerinden MQTT baglantisi kurulur (WebSocket'e gerek yok).
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient mqttIstemciOlustur({
  required String host,
  required int port,
  required String clientId,
  required bool guvenli,
}) {
  final istemci = MqttServerClient(host, clientId);
  istemci.port = port;
  // guvenli=true ise TLS uzerinden baglanir (mqtt_client'in yerlesik
  // secure bayragi, isletim sisteminin sertifika deposunu kullanir --
  // ek bir paket/sertifika dosyasi gerekmez).
  istemci.secure = guvenli;
  return istemci;
}
