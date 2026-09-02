/// AquaGuard - Tarla Secim Ekrani
/// ==================================
///
/// Amac:
///   Uygulama acilinca gosterilen ilk ekran. Kullanicinin kayitli
///   tarlalarini listeler, yeni tarla eklemeyi/silmeyi saglar ve bir
///   tarlaya dokununca o tarlanin zon dashboard'una gecer.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tarla.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/demo_modu_banner.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';
import '../widgets/tarla_haritasi.dart';
import 'ayarlar_ekrani.dart';
import 'tikanma_detay_ekrani.dart';
import 'zon_dashboard_ekrani.dart';

class TarlaSecimEkrani extends StatefulWidget {
  const TarlaSecimEkrani({super.key});

  @override
  State<TarlaSecimEkrani> createState() => _TarlaSecimEkraniState();
}

class _TarlaSecimEkraniState extends State<TarlaSecimEkrani> {
  bool _haritaModuAktif = false;

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarlalarım'),
        actions: [
          if (durum.tarlalar.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                icon: Icon(
                  _haritaModuAktif ? Icons.view_list_outlined : Icons.map_outlined,
                ),
                tooltip: _haritaModuAktif
                    ? 'Liste Görünümüne Geç'
                    : 'Harita Görünümüne Geç',
                onPressed: () =>
                    setState(() => _haritaModuAktif = !_haritaModuAktif),
              ),
            ),
        ],
      ),
      body: !durum.hazir
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (durum.demoModuAktif)
                  DemoModuBanner(
                    onAyarlaraGit: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AyarlarEkrani()),
                    ),
                  ),
                Expanded(
                  child: durum.tarlalar.isEmpty
                      ? _BosTarlaGorunumu(
                          onEkle: () => _tarlaEkleDuzenleFormunuGoster(context),
                        )
                      : DuyarliIcerik(
                          child: _haritaModuAktif
                              ? TarlaHaritasi(
                                  tarlalar: durum.tarlalar,
                                  durum: durum,
                                  onZonSecildi: (zon) => Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TikanmaDetayEkrani(zonNumarasi: zon),
                                    ),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    96,
                                  ),
                                  children: [
                                    Text(
                                      '${durum.tarlalar.length} tarla, '
                                      '${durum.tumZonNumaralari.length} izlenen zon',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...durum.tarlalar.map(
                                      (tarla) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _TarlaKarti(
                                          tarla: tarla,
                                          onDuzenle: () =>
                                              _tarlaEkleDuzenleFormunuGoster(
                                                context,
                                                duzenlenecekTarla: tarla,
                                              ),
                                          onSil: () => _tarlaSilmeyiOnayla(
                                            context,
                                            tarla,
                                          ),
                                          onAc: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ZonDashboardEkrani(
                                                    tarla: tarla,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tarlaEkleDuzenleFormunuGoster(context),
        icon: const Icon(Icons.add),
        label: const Text('Tarla Ekle'),
      ),
    );
  }

  void _tarlaSilmeyiOnayla(BuildContext context, Tarla tarla) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tarlayı Sil'),
        content: Text(
          '"${tarla.ad}" tarlasını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton.tonal(
            onPressed: () {
              context.read<UygulamaDurumu>().tarlaSil(tarla.id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _tarlaEkleDuzenleFormunuGoster(
    BuildContext context, {
    Tarla? duzenlenecekTarla,
  }) {
    final adController = TextEditingController(
      text: duzenlenecekTarla?.ad ?? '',
    );
    final zonController = TextEditingController(
      text: duzenlenecekTarla?.zonNumaralari.join(', ') ?? '',
    );
    final formAnahtari = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          duzenlenecekTarla == null ? 'Yeni Tarla Ekle' : 'Tarlayı Düzenle',
        ),
        content: Form(
          key: formAnahtari,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: adController,
                decoration: const InputDecoration(labelText: 'Tarla Adı'),
                validator: (deger) => (deger == null || deger.trim().isEmpty)
                    ? 'Tarla adı gerekli'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: zonController,
                decoration: const InputDecoration(
                  labelText: 'Zon Numaraları',
                  hintText: 'Örnek: 1, 2, 3',
                ),
                validator: (deger) {
                  if (deger == null || deger.trim().isEmpty) {
                    return 'En az bir zon numarası girin';
                  }
                  final parcalar = deger.split(',').map((p) => p.trim());
                  final hepsiGecerliSayi = parcalar.every(
                    (p) => int.tryParse(p) != null,
                  );
                  if (!hepsiGecerliSayi) {
                    return 'Zon numaraları virgülle ayrılmış tam sayı olmalı';
                  }

                  final girilenZonlar = parcalar.map(int.parse).toSet();

                  // Baska bir tarlada ZATEN KULLANILAN zon numarasi var mi?
                  // (duzenlenen tarlanin kendisi haric -- kendi zonlarini
                  // degistirmeden tekrar kaydetmek hataya dusmemeli)
                  final durum = context.read<UygulamaDurumu>();
                  for (final digerTarla in durum.tarlalar) {
                    if (duzenlenecekTarla != null &&
                        digerTarla.id == duzenlenecekTarla.id) {
                      continue;
                    }
                    final cakisanlar = girilenZonlar.intersection(
                      digerTarla.zonNumaralari.toSet(),
                    );
                    if (cakisanlar.isNotEmpty) {
                      return 'Zon ${cakisanlar.join(", ")} zaten "${digerTarla.ad}" tarlasında kullanılıyor';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formAnahtari.currentState?.validate() ?? false)) return;

              final zonNumaralari =
                  zonController.text
                      .split(',')
                      .map((parca) => int.parse(parca.trim()))
                      .toSet()
                      .toList()
                    ..sort();

              final durum = context.read<UygulamaDurumu>();

              if (duzenlenecekTarla == null) {
                durum.tarlaEkle(
                  Tarla(
                    id: 'tarla-${DateTime.now().millisecondsSinceEpoch}',
                    ad: adController.text.trim(),
                    zonNumaralari: zonNumaralari,
                  ),
                );
              } else {
                durum.tarlaGuncelle(
                  duzenlenecekTarla.kopyalaVeGuncelle(
                    ad: adController.text.trim(),
                    zonNumaralari: zonNumaralari,
                  ),
                );
              }

              Navigator.of(dialogContext).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _BosTarlaGorunumu extends StatelessWidget {
  final VoidCallback onEkle;
  const _BosTarlaGorunumu({required this.onEkle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grass,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz tarla eklenmedi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'İzlemek istediğiniz ilk tarlanızı ve zon numaralarını ekleyerek başlayın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onEkle,
              icon: const Icon(Icons.add),
              label: const Text('Tarla Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarlaKarti extends StatelessWidget {
  final Tarla tarla;
  final VoidCallback onDuzenle;
  final VoidCallback onSil;
  final VoidCallback onAc;

  const _TarlaKarti({
    required this.tarla,
    required this.onDuzenle,
    required this.onSil,
    required this.onAc,
  });

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<UygulamaDurumu>();
    final renk = _enOnceliklirenk(durum, tarla.zonNumaralari);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAc,
        child: Row(
          children: [
            Container(width: 6, height: 88, color: renk),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tarla.ad,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tarla.zonNumaralari.length} zon — '
                            '${tarla.zonNumaralari.map((z) => "Zon $z").join(", ")}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (secim) {
                        if (secim == 'sil') {
                          onSil();
                        } else if (secim == 'duzenle') {
                          onDuzenle();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
                        PopupMenuItem(value: 'sil', child: Text('Sil')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarladaki zonlar arasinda EN ONCELIKLI (en dikkat gerektiren) durumun
  /// rengini doner. Siniflandirma DurumRenkleri.onceligiBelirle()'den gelir
  /// (tek kaynak -- bu fonksiyonun eskiden kendi elle yazilmis, ozet
  /// hesaplamasindan FARKLI sirali bir kopyasi vardi, bkz. o fonksiyonun
  /// dokumantasyonu).
  Color _enOnceliklirenk(UygulamaDurumu durum, List<int> zonlar) {
    var enYuksekOncelik = ZonOnceligi.cevrimdisi;
    var secilenRenk = DurumRenkleri.cevrimdisi;
    var ilkZon = true;

    for (final zon in zonlar) {
      final okuma = durum.sonOkuma(zon);
      final cevrimici = durum.zonCevrimiciMi(zon);
      final oncelik = DurumRenkleri.onceligiBelirle(
        okuma: okuma,
        cevrimici: cevrimici,
      );
      if (ilkZon || oncelik.index > enYuksekOncelik.index) {
        enYuksekOncelik = oncelik;
        secilenRenk = DurumRenkleri.renkGetir(
          okuma: okuma,
          cevrimici: cevrimici,
        );
        ilkZon = false;
      }
    }
    return secilenRenk;
  }
}
