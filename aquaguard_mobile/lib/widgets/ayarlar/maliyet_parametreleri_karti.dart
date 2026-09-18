/// AquaGuard - Maliyet Parametreleri Karti (Ayarlar bolumu)
/// ==============================================================
///
/// Amac:
///   Tedavi Gecmisi'ndeki tahmini maliyet hesaplamasinin kullandigi birim
///   fiyatlari (su/asit/klor) -- gercek piyasa fiyatina gore guncellenebilir.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan AyarlarProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ayarlar_provider.dart';
import '../../providers/cihaz_iletisim_provider.dart';

class MaliyetParametreleriKarti extends StatefulWidget {
  const MaliyetParametreleriKarti({super.key});

  @override
  State<MaliyetParametreleriKarti> createState() =>
      _MaliyetParametreleriKartiState();
}

class _MaliyetParametreleriKartiState extends State<MaliyetParametreleriKarti> {
  final _suFiyatController = TextEditingController();
  final _asitFiyatController = TextEditingController();
  final _klorFiyatController = TextEditingController();
  final _formAnahtari = GlobalKey<FormState>();
  bool _baslangicDegerleriYuklendi = false;

  String? _pozitifSayiDogrulayici(String? deger) {
    final sayi = double.tryParse((deger ?? '').trim());
    if (sayi == null || sayi < 0) return 'Geçerli bir sayı girin';
    return null;
  }

  @override
  void dispose() {
    _suFiyatController.dispose();
    _asitFiyatController.dispose();
    _klorFiyatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ayarlar = context.watch<AyarlarProvider>();
    final hazir = context.watch<CihazIletisimProvider>().hazir;

    if (!_baslangicDegerleriYuklendi && hazir) {
      _suFiyatController.text = ayarlar.maliyetParametreleri.suBirimFiyatiTLm3
          .toStringAsFixed(2);
      _asitFiyatController.text = ayarlar
          .maliyetParametreleri
          .asitBirimFiyatiTLLitre
          .toStringAsFixed(2);
      _klorFiyatController.text = ayarlar
          .maliyetParametreleri
          .klorBirimFiyatiTLLitre
          .toStringAsFixed(2);
      _baslangicDegerleriYuklendi = true;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formAnahtari,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tedavi Geçmişi\'ndeki tahmini maliyet hesaplaması '
                'bu birim fiyatları kullanır -- gerçek piyasa '
                'fiyatınıza göre güncelleyin.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _suFiyatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Su Birim Fiyatı (₺/m³)',
                ),
                validator: _pozitifSayiDogrulayici,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _asitFiyatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Asit Birim Fiyatı (₺/litre)',
                ),
                validator: _pozitifSayiDogrulayici,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _klorFiyatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Klor Birim Fiyatı (₺/litre)',
                ),
                validator: _pozitifSayiDogrulayici,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    if (!(_formAnahtari.currentState?.validate() ?? false)) {
                      return;
                    }
                    context
                        .read<AyarlarProvider>()
                        .maliyetParametreleriniGuncelle(
                          ayarlar.maliyetParametreleri.kopyalaVeGuncelle(
                            suBirimFiyatiTLm3: double.parse(
                              _suFiyatController.text.trim(),
                            ),
                            asitBirimFiyatiTLLitre: double.parse(
                              _asitFiyatController.text.trim(),
                            ),
                            klorBirimFiyatiTLLitre: double.parse(
                              _klorFiyatController.text.trim(),
                            ),
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maliyet parametreleri kaydedildi'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Fiyatları Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
