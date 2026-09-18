/// AquaGuard - MQTT Baglanti Karti (Ayarlar bolumu)
/// =====================================================
///
/// Amac:
///   Broker adresi/port/TLS formu + baglanti durum rozeti. Demo Modu
///   acikken form devre disi (IgnorePointer) gosterilir -- gercek
///   donanima baglanmak icin once Demo Modu kapatilmalidir.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan CihazIletisimProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/ayarlar_sabitleri.dart';
import '../../providers/cihaz_iletisim_provider.dart';
import '../../services/mqtt_servisi.dart';
import 'bolum_basligi.dart';

class MqttBaglantiKarti extends StatefulWidget {
  const MqttBaglantiKarti({super.key});

  @override
  State<MqttBaglantiKarti> createState() => _MqttBaglantiKartiState();
}

class _MqttBaglantiKartiState extends State<MqttBaglantiKarti> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _formAnahtari = GlobalKey<FormState>();
  bool _mqttGuvenli = false;
  bool _baslangicDegerleriYuklendi = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cihaz = context.watch<CihazIletisimProvider>();

    if (!_baslangicDegerleriYuklendi && cihaz.hazir) {
      _hostController.text = cihaz.mqttHost;
      _portController.text = cihaz.mqttPort.toString();
      _mqttGuvenli = cihaz.mqttGuvenli;
      _baslangicDegerleriYuklendi = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BolumBasligi(baslik: 'MQTT Bağlantısı'),
        if (cihaz.demoModuAktif)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Demo modu açıkken bu ayarlar devre dışıdır. Gerçek donanıma '
              'bağlanmak için önce Demo Modu\'nu kapatın.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BaglantiDurumSatiri(durum: cihaz.baglantiDurumu),
          ),
        IgnorePointer(
          ignoring: cihaz.demoModuAktif,
          child: Opacity(
            opacity: cihaz.demoModuAktif ? 0.5 : 1.0,
            child: Form(
              key: _formAnahtari,
              child: Column(
                children: [
                  TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Broker Adresi',
                      hintText: 'örn. test.mosquitto.org',
                    ),
                    validator: (deger) =>
                        (deger == null || deger.trim().isEmpty)
                        ? 'Broker adresi gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: 'örn. 1883',
                    ),
                    validator: (deger) {
                      final sayi = int.tryParse(deger ?? '');
                      if (sayi == null || sayi <= 0 || sayi > 65535) {
                        return 'Geçerli bir port girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Güvenli Bağlantı (TLS)'),
                    subtitle: const Text(
                      'Açıksa port otomatik 8883/8081\'e döner, '
                      'broker\'ınız TLS desteklemelidir.',
                    ),
                    value: _mqttGuvenli,
                    onChanged: (yeni) {
                      setState(() {
                        // Kullanicinin ELLE girdigi bir port varsa
                        // (varsayilanlardan biri degilse) dokunmayiz --
                        // sadece hala varsayilan degerdeyse karsi
                        // varsayilana geciriz.
                        final mevcutPort = int.tryParse(
                          _portController.text.trim(),
                        );
                        final eskiVarsayilan =
                            AyarlarSabitleri.varsayilanPortGetir(
                              guvenli: _mqttGuvenli,
                            );
                        if (mevcutPort == null ||
                            mevcutPort == eskiVarsayilan) {
                          _portController.text =
                              AyarlarSabitleri.varsayilanPortGetir(
                                guvenli: yeni,
                              ).toString();
                        }
                        _mqttGuvenli = yeni;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!(_formAnahtari.currentState?.validate() ??
                            false)) {
                          return;
                        }
                        context
                            .read<CihazIletisimProvider>()
                            .mqttAyarlariniGuncelle(
                              host: _hostController.text.trim(),
                              port: int.parse(_portController.text.trim()),
                              guvenli: _mqttGuvenli,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ayarlar kaydedildi, yeniden bağlanılıyor...',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Kaydet ve Yeniden Bağlan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BaglantiDurumSatiri extends StatelessWidget {
  final MqttBaglantiDurumu durum;
  const _BaglantiDurumSatiri({required this.durum});

  @override
  Widget build(BuildContext context) {
    final (renk, metin) = switch (durum) {
      MqttBaglantiDurumu.bagli => (Colors.green, 'Bağlı'),
      MqttBaglantiDurumu.baglaniyor => (Colors.amber, 'Bağlanıyor...'),
      MqttBaglantiDurumu.baglantiKesildi => (Colors.orange, 'Bağlantı kesildi'),
      MqttBaglantiDurumu.hata => (Colors.red, 'Bağlantı hatası'),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: renk, size: 12),
          const SizedBox(width: 8),
          Text(
            metin,
            style: TextStyle(color: renk, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
