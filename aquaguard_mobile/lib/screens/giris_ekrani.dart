/// AquaGuard - Giriş Ekranı (Ekran 1 -- Marka Açılışı)
/// =========================================================
///
/// Amac:
///   Uygulama SOĞUK BAŞLADIĞINDA (yalnızca bir kez) gösterilen marka +
///   mod seçim ekranı. Damla+kalkan logosu, başlık ve alt başlık KADEMELİ
///   (staggered) bir fade-in + yukarı kayma animasyonuyla sırayla belirir
///   -- "profesyonel bir ürün açılıyor" hissi verir.
///
///   BİLEREK yarışma/takım markalaması YOKTUR (kullanıcının kesin talebi
///   -- piyasaya çıkacak ürün, yarışma kimliğinden ayrı tutulur).
///
///   DÜRÜSTLÜK NOTU: bu GERÇEK bir kimlik doğrulama/backend ekranı
///   DEĞİLDİR -- uygulama tamamen yerel/çevrimdışı-öncelikli çalışır
///   (bkz. PROJE_BRIEF.md), kullanıcı hesabı/şifre kavramı yoktur (PIN
///   kilidi AYRI ve OPSİYONEL bir güvenlik katmanıdır, bkz. Ayarlar).
///   Bu yüzden "giriş" yanıltıcı bir auth akışı olarak KURULMAZ; sadece
///   marka + Demo Modu seçimi + (varsa) kayıtlı çiftliklerin özeti
///   yapılan bir hazırlık ekranıdır. "Devam Et" doğrudan Ana Kabuk'a
///   (Genel Bakış) geçer.
///
///   main.dart'ta SADECE ilk (soğuk) açılışta `home` olarak gösterilir;
///   "Devam Et" `pushReplacement` ile AnaKabuk'a geçtiği için sekmeler
///   arası gezinmede bir daha GÖRÜNMEZ (AnaKabuk kendi içinde
///   IndexedStack kullanır, bu ekrana dönüş yoktur).
///
/// Tarih:  2026-09-01 (marka açılışı yeniden tasarımı: 2026-09-05)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../providers/cihaz_iletisim_provider.dart';
import '../providers/tarla_provider.dart';
import '../widgets/aquaguard_logosu.dart';
import '../widgets/duyarli_icerik.dart';
import 'ana_kabuk.dart';
import 'tarla_secim_ekrani.dart';

/// pubspec.yaml'daki `version:` alanıyla BİREBİR AYNI tutulmalıdır --
/// package_info_plus bağımlılığı eklenmediği için (tek bir sabit sürüm
/// metni için ekstra bir paket gerekmez) elle senkronize edilir.
const String aquaGuardSurumMetni = 'v0.9.0-beta.1';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animasyon;

  @override
  void initState() {
    super.initState();
    _animasyon = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _animasyon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cihaz = context.watch<CihazIletisimProvider>();
    final tarla = context.watch<TarlaProvider>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AquaGuardTema.anaRenk, AquaGuardTema.arkaPlanRenk],
          ),
        ),
        child: SafeArea(
          child: !cihaz.hazir
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Center(
                      child: DuyarliIcerik(
                        maksimumGenislik: 480,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AnimasyonluMarkaBasligi(animasyon: _animasyon),
                              const SizedBox(height: 40),
                              _DemoModuKarti(cihaz: cihaz),
                              if (tarla.tarlalar.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _CiftlikOzetKarti(tarla: tarla),
                              ],
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pushReplacement(
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
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Center(
                        child: Text(
                          aquaGuardSurumMetni,
                          // SABIT acik renk: bu ekranin arka plani her
                          // temada AYNI koyu gradyan (marka acilis ekrani,
                          // tema secimine gore degismez) -- Theme.of(context)
                          // acik temada KOYU metin rengi dondurur, bu da
                          // gradyanin uzerinde gorunmez olurdu.
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0x999AACBC),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Logo + başlık + alt başlık + takım etiketinin KADEMELİ (her biri farklı
/// bir zaman aralığında) belirdiği animasyon bloğu. Tek bir AnimationController
/// paylaşılır (0.0-1.0), her eleman kendi Interval'ıyla o aralıkta fade-in +
/// hafif yukarı kayma yapar -- boylece "hepsi birden" değil "sırayla" hissi
/// oluşur.
class _AnimasyonluMarkaBasligi extends StatelessWidget {
  final AnimationController animasyon;
  const _AnimasyonluMarkaBasligi({required this.animasyon});

  // SABIT acik renkler: bu baslik/alt baslik, ekranin her temada AYNI kalan
  // koyu gradyan arka planinin UZERINDE durur (bkz. GirisEkrani.build) --
  // Theme.of(context) DEGIL, sabit acik renkler kullanilmali (aksi halde
  // acik temada gorunmez olur).
  static const _baslikRengi = Color(0xFFE6ECF1);
  static const _altBaslikRengi = Color(0xFF9AACBC);

  @override
  Widget build(BuildContext context) {
    final logoAnim = CurvedAnimation(
      parent: animasyon,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    final baslikAnim = CurvedAnimation(
      parent: animasyon,
      curve: const Interval(0.30, 0.75, curve: Curves.easeOut),
    );
    final altBaslikAnim = CurvedAnimation(
      parent: animasyon,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animasyon,
      builder: (context, _) {
        return Column(
          children: [
            _kademeli(logoAnim, const AquaGuardLogosu(boyut: 88)),
            const SizedBox(height: 20),
            _kademeli(
              baslikAnim,
              Text(
                'AquaGuard',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: _baslikRengi,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _kademeli(
              altBaslikAnim,
              const Text(
                'SDI Tıkanma Yönetim Merkezi',
                style: TextStyle(color: _altBaslikRengi),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kademeli(Animation<double> anim, Widget child) {
    final deger = anim.value.clamp(0.0, 1.0);
    return Opacity(
      opacity: deger,
      child: Transform.translate(
        offset: Offset(0, (1 - deger) * 16),
        child: child,
      ),
    );
  }
}

class _DemoModuKarti extends StatelessWidget {
  final CihazIletisimProvider cihaz;
  const _DemoModuKarti({required this.cihaz});

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
                  value: cihaz.demoModuAktif,
                  onChanged: (acik) {
                    final cihazOkuyucu = context.read<CihazIletisimProvider>();
                    if (acik) {
                      cihazOkuyucu.demoModunuAc();
                    } else {
                      cihazOkuyucu.demoModunuKapat();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              cihaz.demoModuAktif
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
  final TarlaProvider tarla;
  const _CiftlikOzetKarti({required this.tarla});

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final toplamZon = tarla.tumZonNumaralari.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grass_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tarla.tarlalar.length} çiftlik, $toplamZon zon izleniyor',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tarla.tarlalar.map((t) => t.ad).join(' • '),
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
