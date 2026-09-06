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
/// Tarih:  2026-09-02
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
        child: Row(
          children: [
            SizedBox(
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
                      builder: (context, deger, _) => CircularProgressIndicator(
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistem Sağlığı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durumMetni,
                    style: TextStyle(color: renk, fontWeight: FontWeight.w600),
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
      ),
    );
  }
}
