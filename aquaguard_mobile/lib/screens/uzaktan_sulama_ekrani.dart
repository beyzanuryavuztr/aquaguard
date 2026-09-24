/// AquaGuard - Uzaktan Sulama Ekrani
/// =====================================
///
/// Amac:
///   Ciftci evinde/ofiste otururken, hangi ciftligin hangi zon(lar)inda
///   ne kadar sure sulama yapilacagini secip tek dokunusla baslatabilmesi.
///   Sistemde -- degistirilmemesi gereken -- sunlar zaten dogru calisiyor,
///   BU EKRAN sadece bunlarin ONUNE bir secim/tetikleme arayuzu koyuyor:
///     - Suresi dolunca vana KARTTA (telefonda degil) kendiliginden kapanir
///       (bkz. firmware/ana_vana.h anaVanaZamanlayiciyiGuncelle) -- uygulama
///       kapansa/baglanti kesilse bile su bosa akmaya devam etmez.
///     - Bu sulama surerken bir tikanma olursa, otonom teshis/tedavi
///       DEGISMEDEN calismaya devam eder (ayri bir entegrasyon gerekmedi).
///
///   Birden fazla zon secilebilir -- her biri icin AYRI bir MQTT komutu
///   gonderilir (aquaguard/zone{N}/komut), cunku sema zaten zon-bazli.
///
/// Tarih:  2026-09-24
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/ayarlar_sabitleri.dart';
import '../providers/cihaz_iletisim_provider.dart';
import '../providers/tarla_provider.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/yardim_butonu.dart';

class UzaktanSulamaEkrani extends StatefulWidget {
  const UzaktanSulamaEkrani({super.key});

  @override
  State<UzaktanSulamaEkrani> createState() => _UzaktanSulamaEkraniState();
}

class _UzaktanSulamaEkraniState extends State<UzaktanSulamaEkrani> {
  String? _seciliTarlaId;
  final Set<int> _seciliZonlar = {};
  final _sureController = TextEditingController(text: '30');
  bool _baslatiliyor = false;

  @override
  void dispose() {
    _sureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tarlaProvider = context.watch<TarlaProvider>();
    final tarlalar = tarlaProvider.tarlalar;

    final seciliTarla = tarlalar.isEmpty
        ? null
        : (tarlalar.where((t) => t.id == _seciliTarlaId).firstOrNull ??
              tarlalar.first);
    if (seciliTarla != null && _seciliTarlaId != seciliTarla.id) {
      // Ilk acilista ya da secili tarla silinmisse -- ilk tarlaya duser.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _seciliTarlaId = seciliTarla.id);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uzaktan Sulama'),
        actions: const [
          YardimButonu(
            ekranAnahtari: 'uzaktan_sulama',
            baslik: 'Uzaktan Sulama',
          ),
        ],
      ),
      body: DuyarliIcerik(
        child: tarlalar.isEmpty
            ? const Center(child: Text('Henüz kayıtlı bir çiftlik yok'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Çiftlik', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tarla in tarlalar)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tarla.ad),
                              selected: seciliTarla?.id == tarla.id,
                              onSelected: (_) => setState(() {
                                _seciliTarlaId = tarla.id;
                                _seciliZonlar.clear();
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (seciliTarla != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sulanacak Zon(lar)',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            if (_seciliZonlar.length ==
                                seciliTarla.zonNumaralari.length) {
                              _seciliZonlar.clear();
                            } else {
                              _seciliZonlar
                                ..clear()
                                ..addAll(seciliTarla.zonNumaralari);
                            }
                          }),
                          child: Text(
                            _seciliZonlar.length ==
                                    seciliTarla.zonNumaralari.length
                                ? 'Hiçbirini seçme'
                                : 'Tümünü seç',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final zon in seciliTarla.zonNumaralari)
                          FilterChip(
                            label: Text(tarlaProvider.zonAdiGetir(zon)),
                            selected: _seciliZonlar.contains(zon),
                            onSelected: (secildi) => setState(() {
                              if (secildi) {
                                _seciliZonlar.add(zon);
                              } else {
                                _seciliZonlar.remove(zon);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Süre', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sureController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Dakika',
                        helperText:
                            'En fazla ${AyarlarSabitleri.sulamaMaksSureDakika} '
                            'dakika -- süre dolunca vana kendiliğinden kapanır.',
                        suffixText: 'dk',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: (_seciliZonlar.isEmpty || _baslatiliyor)
                          ? null
                          : () => _sulamayiBaslat(context, seciliTarla.ad),
                      icon: _baslatiliyor
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_circle_outline),
                      label: Text(
                        _seciliZonlar.isEmpty
                            ? 'Önce zon seçin'
                            : '${_seciliZonlar.length} zonu sula',
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _sulamayiBaslat(BuildContext context, String tarlaAdi) async {
    final dakika = int.tryParse(_sureController.text.trim()) ?? 0;
    if (dakika <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir süre (dakika) girin')),
      );
      return;
    }

    setState(() => _baslatiliyor = true);
    final cihaz = context.read<CihazIletisimProvider>();
    final zonlar = List<int>.from(_seciliZonlar);
    var basariliSayisi = 0;
    for (final zon in zonlar) {
      final basarili = await cihaz.sulamayiSureliBaslat(zon, dakika);
      if (basarili) basariliSayisi++;
    }

    if (!context.mounted) return;
    setState(() => _baslatiliyor = false);

    final mesaj = basariliSayisi == zonlar.length
        ? '$tarlaAdi: $basariliSayisi zonda $dakika dakikalık sulama başlatıldı'
        : '$tarlaAdi: ${zonlar.length} zondan sadece $basariliSayisi tanesine '
              'komut gönderilebildi (bağlantı yok, kuyruğa alındı)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
    setState(_seciliZonlar.clear);
  }
}
