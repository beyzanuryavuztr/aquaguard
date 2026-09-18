/// AquaGuard - Kullanici Profili Karti (Ayarlar bolumu)
/// =========================================================
///
/// Amac:
///   Sadece bu cihazda saklanan yerel kisisellestirme (isim/isletme/telefon)
///   -- PDF raporlarda "Hazirlayan" bilgisi olarak kullanilir, gercek bir
///   hesap/backend YOKTUR (bkz. models/kullanici_profili.dart).
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan AyarlarProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/kullanici_profili.dart';
import '../../providers/ayarlar_provider.dart';
import '../../providers/cihaz_iletisim_provider.dart';

class KullaniciProfiliKarti extends StatefulWidget {
  const KullaniciProfiliKarti({super.key});

  @override
  State<KullaniciProfiliKarti> createState() => _KullaniciProfiliKartiState();
}

class _KullaniciProfiliKartiState extends State<KullaniciProfiliKarti> {
  final _isimController = TextEditingController();
  final _isletmeController = TextEditingController();
  final _telefonController = TextEditingController();
  bool _baslangicDegerleriYuklendi = false;

  @override
  void dispose() {
    _isimController.dispose();
    _isletmeController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ayarlar = context.watch<AyarlarProvider>();
    // Kart, AnaKabuk'ta diger sekmelerle BIRLIKTE aninda insa edilir --
    // yani provider'larin baslat()'i (SharedPreferences'tan asenkron
    // yukleme) daha bitmeden bu widget zaten var olur. "hazir" ilk kez
    // true oldugunda BIR KEZ senkronize ederiz (bkz. eski ayarlar_ekrani.dart
    // dosya basi notu -- CihazIletisimProvider.hazir tum provider'larin
    // baslatilmasindan SONRA true olur, main.dart orkestrasyonu buna gore).
    final hazir = context.watch<CihazIletisimProvider>().hazir;
    if (!_baslangicDegerleriYuklendi && hazir) {
      _isimController.text = ayarlar.kullaniciProfili.isim;
      _isletmeController.text = ayarlar.kullaniciProfili.isletmeAdi;
      _telefonController.text = ayarlar.kullaniciProfili.telefon;
      _baslangicDegerleriYuklendi = true;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sadece bu cihazda saklanır, PDF raporlarda "Hazırlayan" '
              'bilgisi olarak kullanılır.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isimController,
              decoration: const InputDecoration(labelText: 'İsim'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isletmeController,
              decoration: const InputDecoration(
                labelText: 'İşletme / Çiftlik Adı',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () {
                  context.read<AyarlarProvider>().kullaniciProfiliniGuncelle(
                    KullaniciProfili(
                      isim: _isimController.text.trim(),
                      isletmeAdi: _isletmeController.text.trim(),
                      telefon: _telefonController.text.trim(),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil kaydedildi')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Profili Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
