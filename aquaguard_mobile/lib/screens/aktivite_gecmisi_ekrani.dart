/// AquaGuard - Aktivite Gecmisi Ekrani
/// =======================================
///
/// Amac:
///   Genel Bakis ekranindaki "Son Aktiviteler" ozetinin tam listesi.
///   Tum zonlardaki durum degisikliklerini ve tedavi olaylarini
///   kronolojik olarak (en yeni once) gosterir.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/uygulama_durumu.dart';

class AktiviteGecmisiEkrani extends StatelessWidget {
  const AktiviteGecmisiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final aktiviteler = context.watch<UygulamaDurumu>().aktiviteGecmisi;

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivite Geçmişi')),
      body: aktiviteler.isEmpty
          ? const Center(child: Text('Henüz aktivite kaydı yok.'))
          : ListView.separated(
              itemCount: aktiviteler.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final kayit = aktiviteler[index];
                final renk = kayit.renkGetir(context);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: renk.withValues(alpha: 0.15),
                    child: Icon(kayit.ikon, color: renk, size: 20),
                  ),
                  title: Text(kayit.mesaj),
                  subtitle: Text('Zon ${kayit.zone} — ${DateFormat('dd.MM.yyyy HH:mm:ss').format(kayit.zaman)}'),
                );
              },
            ),
    );
  }
}
