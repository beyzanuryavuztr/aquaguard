/// AquaGuard - Sistem Sagligi Gostergesi (Gauge)
/// ===================================================
///
/// Amac:
///   Genel Bakış ekraninin "hero" (dikkat cekici, ilk goz atilan) gorseli.
///   Tum sistemdeki zonlarin ne kadarinin saglikli oldugunu tek bir buyuk
///   dairesel gostergeyle ozetler -- kullanicinin tek tek tarlalara
///   girmeden "genel olarak her sey yolunda mi?" sorusuna aninda cevap
///   bulmasini saglar.
///
///   Saglik yuzdesi = (normal + tedavide) / toplam * 100. Tedavide olan
///   bir zon "saglikli" sayilir cunku sistem SORUNU KENDI COZUYOR (bu tam
///   olarak AquaGuard'in otonom degerini gosteren durumdur) -- sadece
///   belirsiz/tespit edildi (henuz tedavi baslamamis) ve cevrimdisi
///   zonlar puani dusurur.
///
///   ACIMASIZ DENETIM (2026-09-25): durum kirilimi (Normal/Belirsiz/Tespit/
///   Çevrimdışı sayilari) onceden Genel Bakış'ta AYRI, kendi basina bir
///   satir olarak gosteriliyordu -- bu kart zaten ayni ozeti anlatiyor,
///   iki ayri blok "hangi zonlar sorunlu" sorusunu iki kez cevapliyordu.
///   Kirilim artik BU kartin icinde, aciklama metninin hemen altinda --
///   tek bir "sistem sagligi hikayesi" kart, iki degil.
///
/// Tarih:  2026-09-02 (durum kirilimi birlestirmesi: 2026-09-25)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

import '../providers/uygulama_durumu.dart';
import 'durum_renkleri.dart';

class SistemSagligiGostergesi extends StatelessWidget {
  final ZonDurumOzeti ozet;

  const SistemSagligiGostergesi({super.key, required this.ozet});

  @override
  Widget build(BuildContext context) {
    final toplam =
        ozet.normal +
        ozet.belirsiz +
        ozet.tespitEdildi +
        ozet.tedavide +
        ozet.cevrimdisi;
    final saglikliSayisi = ozet.normal + ozet.tedavide;
    final yuzde = toplam == 0 ? 100.0 : (saglikliSayisi / toplam) * 100;

    final Color renk;
    final String durumMetni;
    if (toplam == 0) {
      renk = Colors.grey;
      durumMetni = 'Henüz izlenen zon yok';
    } else if (yuzde >= 90) {
      renk = const Color(0xFF2E7D32);
      durumMetni = 'Sistem sorunsuz çalışıyor';
    } else if (yuzde >= 60) {
      renk = const Color(0xFFF9A825);
      durumMetni = 'Bazı zonlar dikkat gerektiriyor';
    } else {
      renk = const Color(0xFFC62828);
      durumMetni = 'Acil müdahale gerekebilir';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Semantics(
                  label: 'Sistem sağlığı göstergesi',
                  value: '%${yuzde.toStringAsFixed(0)} sağlıklı, $durumMetni',
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 108,
                          height: 108,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: (yuzde / 100).clamp(0.0, 1.0),
                            ),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOut,
                            builder: (context, deger, _) =>
                                CircularProgressIndicator(
                                  value: deger,
                                  strokeWidth: 10,
                                  backgroundColor: renk.izTonu,
                                  color: renk,
                                  strokeCap: StrokeCap.round,
                                ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '%${yuzde.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: renk,
                              ),
                            ),
                            Text(
                              'sağlıklı',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistem Sağlığı',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        durumMetni,
                        style: TextStyle(
                          color: renk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$toplam zondan $saglikliSayisi tanesi normal veya '
                        'aktif olarak tedavi ediliyor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (toplam > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  _DurumOzetRozeti(
                    sayi: ozet.normal,
                    etiket: 'Normal',
                    renk: DurumRenkleri.normal,
                  ),
                  const SizedBox(width: 8),
                  _DurumOzetRozeti(
                    sayi: ozet.belirsiz,
                    etiket: 'Belirsiz',
                    renk: DurumRenkleri.belirsiz,
                  ),
                  const SizedBox(width: 8),
                  _DurumOzetRozeti(
                    sayi: ozet.tespitEdildi,
                    etiket: 'Tespit',
                    renk: DurumRenkleri.tespitEdildi,
                  ),
                  if (ozet.cevrimdisi > 0) ...[
                    const SizedBox(width: 8),
                    _DurumOzetRozeti(
                      sayi: ozet.cevrimdisi,
                      etiket: 'Çevrimdışı',
                      renk: DurumRenkleri.cevrimdisi,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DurumOzetRozeti extends StatelessWidget {
  final int sayi;
  final String etiket;
  final Color renk;

  const _DurumOzetRozeti({
    required this.sayi,
    required this.etiket,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$sayi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            Text(etiket, style: TextStyle(fontSize: 11, color: renk)),
          ],
        ),
      ),
    );
  }
}
