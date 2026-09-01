/// AquaGuard - MQTT Istemcisi (Web/Tarayici Platformu)
/// ========================================================
///
/// Tarayicida ham TCP soketi acilamaz (guvenlik kisitlamasi); bu yuzden
/// MQTT baglantisi WebSocket (ws://) uzerinden kurulur. Kullanilan broker'in
/// WebSocket dinleyicisi acik olmalidir (ornegin test.mosquitto.org 8080
/// portunda WS destekler).
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient mqttIstemciOlustur({
  required String host,
  required int port,
  required String clientId,
}) {
  final istemci = MqttBrowserClient('ws://$host/mqtt', clientId);
  istemci.port = port;
  return istemci;
}
