/// AquaGuard - Tarla Profil Karti
/// ==================================
///
/// Amac:
///   Bir tarlanin "profil" bilgilerini (fotograf, konum, aciklama) gosterir
///   ve operatorun fotograf eklemesini/degistirmesini saglar. Bu bilgiler
///   sensor/teshis verisinden TAMAMEN BAGIMSIZDIR -- sadece operatorun
///   kendi girdigi tanimlayici bilgilerdir (bkz. models/tarla.dart).
///
///   FOTOGRAF DEPOLAMA NOTU: secilen fotograf kucultulup (maxWidth 1024,
///   kalite %70) base64 olarak SharedPreferences'a yazilir. Bu, cok sayida
///   yuksek cozunurluklu fotograf icin ideal bir cozum DEGILDIR (gercek bir
///   urunde bir dosya/obje deposu -- ornegin bir sunucu ya da cihazin kendi
///   dosya sistemi -- kullanilirdi); ama bu uygulamanin GENEL mimarisi zaten
///   tamamen yerel/cevrimdisi (SharedPreferences tabanli) oldugu icin, tek
///   bir profil fotografi (tarla basina) bu sinirlar icinde makul bir
///   cozumdur.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/tarla.dart';
import '../providers/uygulama_durumu.dart';

class TarlaProfilKarti extends StatelessWidget {
  final Tarla tarla;
  const TarlaProfilKarti({super.key, required this.tarla});

  Future<void> _fotografSec(BuildContext context) async {
    try {
      final secilen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (secilen == null || !context.mounted) return;

      final baytlar = await secilen.readAsBytes();
      final base64Metin = base64Encode(baytlar);

      if (!context.mounted) return;
      await context.read<UygulamaDurumu>().tarlaGuncelle(
        tarla.kopyalaVeGuncelle(fotografBase64: base64Metin),
      );
    } catch (hata) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilemedi: $hata')),
      );
    }
  }

  Future<void> _fotografiKaldir(BuildContext context) async {
    await context.read<UygulamaDurumu>().tarlaGuncelle(
      tarla.kopyalaVeGuncelle(fotografiKaldir: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final konumVarMi = tarla.konum?.isNotEmpty ?? false;
    final aciklamaVarMi = tarla.aciklama?.isNotEmpty ?? false;
    final fotografVarMi = tarla.fotografBase64?.isNotEmpty ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _fotografSec(context),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: fotografVarMi
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          base64Decode(tarla.fotografBase64!),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: _FotografAksiyonButonu(
                            ikon: Icons.close,
                            tooltip: 'Fotoğrafı Kaldır',
                            onTap: () => _fotografiKaldir(context),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _FotografAksiyonButonu(
                            ikon: Icons.edit,
                            tooltip: 'Fotoğrafı Değiştir',
                            onTap: () => _fotografSec(context),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tarla Fotoğrafı Ekle',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (konumVarMi || aciklamaVarMi)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (konumVarMi)
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tarla.konum!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  if (konumVarMi && aciklamaVarMi) const SizedBox(height: 8),
                  if (aciklamaVarMi)
                    Text(
                      tarla.aciklama!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FotografAksiyonButonu extends StatelessWidget {
  final IconData ikon;
  final String tooltip;
  final VoidCallback onTap;

  const _FotografAksiyonButonu({
    required this.ikon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(ikon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
