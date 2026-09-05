/// AquaGuard - Giriş Ekranı (Ekran 1)
/// =======================================
///
/// Amac:
///   Uygulama SOĞUK BAŞLADIĞINDA (yalnızca bir kez) gösterilen marka +
///   mod seçim ekranı.
///
///   DÜRÜSTLÜK NOTU: bu GERÇEK bir kimlik doğrulama/backend ekranı
///   DEĞİLDİR -- uygulama tamamen yerel/çevrimdışı-öncelikli çalışır
///   (bkz. PROJE_BRIEF.md), kullanıcı hesabı/şifre kavramı yoktur. Bu
///   yüzden "giriş" yanıltıcı bir auth akışı olarak KURULMAZ; sadece
///   marka + Demo Modu seçimi + (varsa) kayıtlı çiftliklerin özeti
///   yapılan bir hazırlık ekranıdır. "Devam Et" doğrudan Ana Kabuk'a
///   (Genel Bakış) geçer.
///
///   main.dart'ta SADECE ilk (soğuk) açılışta `home` olarak gösterilir;
///   "Devam Et" `pushReplacement` ile AnaKabuk'a geçtiği için sekmeler
///   arası gezinmede bir daha GÖRÜNMEZ (AnaKabuk kendi içinde
///   IndexedStack kullanır, bu ekrana dönüş yoktur).
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uygulama_durumu.dart';
import '../widgets/duyarli_icerik.dart';
import 'ana_kabuk.dart';
import 'tarla_secim_ekrani.dart';

class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();

    return Scaffold(
      body: SafeArea(
        child: !durum.hazir
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: DuyarliIcerik(
                  maksimumGenislik: 480,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AquaGuard',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SDI Tıkanma Yönetim Merkezi',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _DemoModuKarti(durum: durum),
                        if (durum.tarlalar.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _CiftlikOzetKarti(durum: durum),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AnaKabuk(),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Devam Et'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DemoModuKarti extends StatelessWidget {
  final UygulamaDurumu durum;
  const _DemoModuKarti({required this.durum});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
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
                  ? 'Gerçekçi simüle edilmiş sensör verisiyle çalışılıyor. Ağ/donanım gerekmez.'
                  : 'Gerçek Deneyap Kart donanımına MQTT üzerinden bağlanılacak.',
              style: TextStyle(color: onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CiftlikOzetKarti extends StatelessWidget {
  final UygulamaDurumu durum;
  const _CiftlikOzetKarti({required this.durum});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final toplamZon = durum.tumZonNumaralari.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${durum.tarlalar.length} çiftlik, $toplamZon zon izleniyor',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              durum.tarlalar.map((t) => t.ad).join(' • '),
              style: TextStyle(color: onSurfaceVariant, fontSize: 12),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TarlaSecimEkrani()),
                ),
                child: const Text('Çiftlikleri Yönet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
