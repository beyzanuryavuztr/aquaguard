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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/kalibrasyon_sabitleri.dart';
import '../config/sensor_imzalari.dart';
import '../models/bakim_gorevi.dart';
import '../models/tema_modu.dart';
import '../providers/uygulama_durumu.dart';
import '../services/mqtt_servisi.dart';
import '../widgets/duyarli_icerik.dart';
import 'hakkinda_ekrani.dart';

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
            _BolumBasligi(baslik: 'Görünüm'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TemaModu>(
                      segments: TemaModu.values
                          .map(
                            (t) => ButtonSegment(
                              value: t,
                              label: Text(t.etiket),
                            ),
                          )
                          .toList(),
                      selected: {durum.temaModu},
                      showSelectedIcon: false,
                      onSelectionChanged: (secim) => context
                          .read<UygulamaDurumu>()
                          .temaModuAyarla(secim.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Tıkanma tespiti'),
                    subtitle: const Text(
                      'Yeni bir tıkanma tespit edildiğinde veya şüphe oluştuğunda',
                    ),
                    value: durum.bildirimTercihleri.tespit,
                    onChanged: (deger) => context
                        .read<UygulamaDurumu>()
                        .bildirimTercihleriniGuncelle(
                          durum.bildirimTercihleri.kopyalaVeGuncelle(
                            tespit: deger,
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tedavi başlangıcı'),
                    subtitle: const Text(
                      'Otonom bir tedavi (asit/klor/yıkama) başladığında',
                    ),
                    value: durum.bildirimTercihleri.tedaviBaslangic,
                    onChanged: (deger) => context
                        .read<UygulamaDurumu>()
                        .bildirimTercihleriniGuncelle(
                          durum.bildirimTercihleri.kopyalaVeGuncelle(
                            tedaviBaslangic: deger,
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tedavi tamamlanma'),
                    subtitle: const Text(
                      'Tedavi/durulama bitip durum normale döndüğünde',
                    ),
                    value: durum.bildirimTercihleri.tedaviTamamlanma,
                    onChanged: (deger) => context
                        .read<UygulamaDurumu>()
                        .bildirimTercihleriniGuncelle(
                          durum.bildirimTercihleri.kopyalaVeGuncelle(
                            tedaviTamamlanma: deger,
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Düşük pil'),
                    subtitle: const Text(
                      'Cihazın (simüle edilen) pil seviyesi düşük olduğunda',
                    ),
                    value: durum.bildirimTercihleri.dusukPil,
                    onChanged: (deger) => context
                        .read<UygulamaDurumu>()
                        .bildirimTercihleriniGuncelle(
                          durum.bildirimTercihleri.kopyalaVeGuncelle(
                            dusukPil: deger,
                          ),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'Zon İsimleri'),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < durum.tumZonNumaralari.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ZonAdiSatiri(zon: durum.tumZonNumaralari[i]),
                  ],
                  if (durum.tumZonNumaralari.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz izlenen zon yok.'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'Sensör Kalibrasyonu'),
            _KalibrasyonKarti(),
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'Eşik Değerleri'),
            _EsikDegerleriKarti(),
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'Bakım Takvimi'),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < durum.bakimGorevleri.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _BakimGoreviSatiri(gorev: durum.bakimGorevleri[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _BolumBasligi(baslik: 'Güvenlik'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('PIN Koruması'),
                    subtitle: Text(
                      durum.pinKorumasiAktif
                          ? 'Uygulama her açılışta 4 haneli PIN ister'
                          : 'Kapalı — uygulama doğrudan açılır',
                    ),
                    value: durum.pinKorumasiAktif,
                    onChanged: (deger) => deger
                        ? _pinBelirleDialoguGoster(context)
                        : context
                              .read<UygulamaDurumu>()
                              .pinKorumasiniKapat(),
                  ),
                  if (durum.pinKorumasiAktif) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('PIN Değiştir'),
                      onTap: () => _pinBelirleDialoguGoster(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HakkindaEkrani()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonAdiSatiri extends StatelessWidget {
  final int zon;
  const _ZonAdiSatiri({required this.zon});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final varsayilanAd = 'Zon $zon';
    final zonAdi = durum.zonAdiGetir(zon);
    final takmaAdVarMi = zonAdi != varsayilanAd;
    return ListTile(
      title: Text(varsayilanAd),
      subtitle: Text(
        takmaAdVarMi ? zonAdi : 'Takma ad verilmedi',
        style: takmaAdVarMi
            ? null
            : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _takmaAdDiyaloguGoster(context, durum, zon),
    );
  }

  Future<void> _takmaAdDiyaloguGoster(
    BuildContext context,
    UygulamaDurumu durum,
    int zon,
  ) async {
    final mevcutAd = durum.zonAdiGetir(zon);
    final baslangicMetni = mevcutAd == 'Zon $zon' ? '' : mevcutAd;
    final controller = TextEditingController(text: baslangicMetni);

    final sonuc = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Zon $zon Takma Adı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'örn. Kuzeydoğu Parseli',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (sonuc != null && context.mounted) {
      await durum.zonTakmaAdiAyarla(zon, sonuc);
    }
  }
}

class _KalibrasyonKarti extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salt okunur -- kalibrasyon Deneyap Kart üzerinde saha tampon '
              'çözeltileriyle (pH 4.01/6.86/9.18, EC 1.413/12.88 mS/cm, '
              'ORP 225/475 mV) yapılır.',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _degerSatiri('pH ofset', KalibrasyonSabitleri.phOfset.toString()),
            _degerSatiri('pH eğim', KalibrasyonSabitleri.phEgim.toString()),
            _degerSatiri(
              'pH nötr voltaj',
              '${KalibrasyonSabitleri.phNotrVoltaj} V',
            ),
            const Divider(height: 20),
            _degerSatiri('EC ofset', KalibrasyonSabitleri.ecOfset.toString()),
            _degerSatiri('EC eğim', KalibrasyonSabitleri.ecEgim.toString()),
            const Divider(height: 20),
            _degerSatiri(
              'ORP ofset voltaj',
              '${KalibrasyonSabitleri.orpOfsetVoltaj} V',
            ),
            _degerSatiri(
              'ORP kazanç',
              '${KalibrasyonSabitleri.orpKazanc} mV/V',
            ),
            const Divider(height: 20),
            _degerSatiri(
              'Türbidite temiz su voltajı',
              '${KalibrasyonSabitleri.turbiditeTemizVoltaj} V',
            ),
            _degerSatiri(
              'Türbidite eğim',
              '${KalibrasyonSabitleri.turbiditeEgim} NTU/V',
              sonSatir: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _degerSatiri(String etiket, String deger, {bool sonSatir = false}) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: sonSatir ? 0 : 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                etiket,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(deger, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EsikDegerleriKarti extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salt okunur -- Katman 1 (kural tabanlı) karar motorunun '
              'kullandığı sabit eşikler.',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _esikSatiri(context, 'Referans debi', '$referansDebi LPM'),
            _esikSatiri(
              context,
              'Debi düşüş eşiği',
              '$debiDususEsigi LPM',
            ),
            _esikSatiri(
              context,
              'Basınç artış eşiği',
              '$basincArtisEsigi bar',
            ),
            _esikSatiri(context, 'Türbidite eşiği', '$turbiditeEsigi NTU'),
            _esikSatiri(
              context,
              'Güven eşiği (belirsiz sınırı)',
              '%$guvenEsigi',
              sonSatir: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _esikSatiri(
    BuildContext context,
    String etiket,
    String deger, {
    bool sonSatir = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: sonSatir ? 0 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              etiket,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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

/// "PIN Koruması"nı ilk kez açarken veya mevcut PIN'i değiştirirken
/// gösterilen dialog -- 4 haneli yeni PIN + tekrar, eşleşmezse/4 hane
/// değilse hata gösterir, doğruysa UygulamaDurumu.pinKorumasiniAc'i çağırır.
Future<void> _pinBelirleDialoguGoster(BuildContext context) async {
  final durum = context.read<UygulamaDurumu>();
  final yeniPinDenetci = TextEditingController();
  final tekrarPinDenetci = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('PIN Belirle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: yeniPinDenetci,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Yeni PIN (4 hane)'),
          ),
          TextField(
            controller: tekrarPinDenetci,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'PIN (Tekrar)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () async {
            final yeni = yeniPinDenetci.text;
            final tekrar = tekrarPinDenetci.text;
            if (yeni.length != 4 || int.tryParse(yeni) == null) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('PIN 4 haneli rakam olmalı')),
              );
              return;
            }
            if (yeni != tekrar) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('PIN\'ler eşleşmiyor')),
              );
              return;
            }
            await durum.pinKorumasiniAc(yeni);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}

class _BakimGoreviSatiri extends StatelessWidget {
  final BakimGorevi gorev;
  const _BakimGoreviSatiri({required this.gorev});

  @override
  Widget build(BuildContext context) {
    final durumu = gorev.durumu();
    final renk = switch (durumu) {
      BakimDurumu.gecikti => Theme.of(context).colorScheme.error,
      BakimDurumu.yaklasiyor => const Color(0xFFFFB300),
      BakimDurumu.normal => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final kalanGun = gorev.kalanGun();
    final durumMetni = switch (durumu) {
      BakimDurumu.gecikti => '${-kalanGun} gün gecikti',
      BakimDurumu.yaklasiyor => '$kalanGun gün kaldı',
      BakimDurumu.normal =>
        'Sıradaki: ${DateFormat('dd.MM.yyyy').format(gorev.sonrakiTarih)}',
    };

    return ListTile(
      leading: Icon(
        durumu == BakimDurumu.gecikti
            ? Icons.error_outline
            : Icons.build_outlined,
        color: renk,
      ),
      title: Text(gorev.baslik),
      subtitle: Text(
        '${gorev.aciklama}\n$durumMetni',
        style: TextStyle(color: renk),
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: () => context
            .read<UygulamaDurumu>()
            .bakimGoreviTamamlandiIsaretle(gorev.id),
        child: const Text('Yapıldı'),
      ),
    );
  }
}
