/// AquaGuard - Ayarlar Ekrani
/// ==============================
///
/// Amac:
///   Demo modu, MQTT broker baglanti bilgilerini (adres/port) ve bildirim
///   tercihini yonetir. Degisiklikler kaydedilince UygulamaDurumu otomatik
///   olarak ilgili baglantiyi (simulasyon veya gercek MQTT) yeniden kurar.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uygulama_durumu.dart';
import '../services/mqtt_servisi.dart';
import '../widgets/duyarli_icerik.dart';

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _formAnahtari = GlobalKey<FormState>();
  bool _baslangicDegerleriYuklendi = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();

    // AyarlarEkrani, AnaKabuk'ta IndexedStack ile diger sekmelerle BIRLIKTE
    // aninda insa edilir -- yani UygulamaDurumu.baslat() (SharedPreferences'tan
    // asenkron yukleme) daha bitmeden bu widget zaten var olur. initState()'te
    // controller'lari o anki (henuz bos) degerlerle doldurmak, gercek
    // degerler yuklendikten SONRA bile formu bos gostermeye devam ederdi.
    // Bunun yerine, "hazir" ilk kez true oldugunda BIR KEZ senkronize ederiz.
    if (!_baslangicDegerleriYuklendi && durum.hazir) {
      _hostController.text = durum.mqttHost;
      _portController.text = durum.mqttPort.toString();
      _baslangicDegerleriYuklendi = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: DuyarliIcerik(
        maksimumGenislik: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BolumBasligi(baslik: 'Veri Kaynağı'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Demo Modu',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Switch(
                          value: durum.demoModuAktif,
                          onChanged: (acik) {
                            final durumOkuyucu = context.read<UygulamaDurumu>();
                            if (acik) {
                              durumOkuyucu.demoModunuAc();
                            } else {
                              durumOkuyucu.demoModunuKapat();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durum.demoModuAktif
                          ? 'Uygulama, gerçekçi simüle edilmiş sensör verisiyle çalışıyor. '
                                'Herhangi bir ağ/donanım bağlantısı gerekmez.'
                          : 'Uygulama, aşağıdaki MQTT brokerına bağlanarak gerçek '
                                'Deneyap Kart verisini dinliyor.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'MQTT Bağlantısı'),
            if (durum.demoModuAktif)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Demo modu açıkken bu ayarlar devre dışıdır. Gerçek donanıma '
                  'bağlanmak için önce Demo Modu\'nu kapatın.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BaglantiDurumSatiri(durum: durum.baglantiDurumu),
              ),
            IgnorePointer(
              ignoring: durum.demoModuAktif,
              child: Opacity(
                opacity: durum.demoModuAktif ? 0.5 : 1.0,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (!(_formAnahtari.currentState?.validate() ??
                                false)) {
                              return;
                            }
                            context
                                .read<UygulamaDurumu>()
                                .mqttAyarlariniGuncelle(
                                  host: _hostController.text.trim(),
                                  port: int.parse(_portController.text.trim()),
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
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'Bildirimler'),
            Card(
              child: SwitchListTile(
                title: const Text('Tıkanma ve tedavi bildirimleri'),
                subtitle: const Text(
                  'Durum değiştiğinde uygulama içi bildirim göster',
                ),
                value: durum.bildirimlerAcik,
                onChanged: (deger) =>
                    context.read<UygulamaDurumu>().bildirimleriDegistir(deger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  const _BolumBasligi({required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        baslik,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
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
