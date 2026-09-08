/// AquaGuard - Bildirim Gecmisi Ekrani
/// =======================================
///
/// Amac:
///   `screens/aktivite_gecmisi_ekrani.dart` TUM sistem olaylarini (durum/
///   tedavi GECISLERI) gosterirken, bu ekran SADECE gercekten bir yerel
///   bildirime DONUSMUS (operatorun 4 kategorili tercihini -- bkz.
///   models/bildirim_tercihleri.dart -- GECMIS) kayitlarin kalici listesini
///   gosterir. Genel Bakis app bar'indaki zil ikonundaki rozet (badge) bu
///   listenin okunmamis sayisini gosterir.
///
///   Ekran acildiginda TUM mevcut kayitlar okundu isaretlenir (rozet
///   sifirlanir) -- ama HANGI kayitlarin YENI (bu acilistan once okunmamis)
///   oldugunu operatore gostermek icin, bu "once" anlik goruntusu ilk
///   build'den ONCE yakalanip ekranin omru boyunca sabit tutulur (canli
///   provider state'ine gore degil).
///
/// Tarih:  2026-09-08
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tarih_bicimleri.dart';
import '../models/aktivite_kaydi.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/durum_renkleri.dart';
import '../widgets/duyarli_icerik.dart';

class BildirimGecmisiEkrani extends StatefulWidget {
  const BildirimGecmisiEkrani({super.key});

  @override
  State<BildirimGecmisiEkrani> createState() => _BildirimGecmisiEkraniState();
}

class _BildirimGecmisiEkraniState extends State<BildirimGecmisiEkrani> {
  late final Set<int> _acilistaOkunmamisIdler;

  @override
  void initState() {
    super.initState();
    final durum = context.read<UygulamaDurumu>();
    _acilistaOkunmamisIdler = durum.bildirimGecmisi
        .where((k) => !durum.bildirimOkunmusMu(k))
        .map(bildirimIdGetir)
        .toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UygulamaDurumu>().bildirimleriOkunduIsaretle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bildirimler = context.watch<UygulamaDurumu>().bildirimGecmisi;

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Geçmişi')),
      body: bildirimler.isEmpty
          ? const Center(child: Text('Henüz bildirim yok.'))
          : DuyarliIcerik(
              child: ListView.separated(
                itemCount: bildirimler.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final kayit = bildirimler[index];
                  final renk = kayit.renkGetir(context);
                  final okunmamisMi = _acilistaOkunmamisIdler.contains(
                    bildirimIdGetir(kayit),
                  );
                  return ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor: renk.rozetTonu,
                          child: Icon(kayit.ikon, color: renk, size: 20),
                        ),
                        if (okunmamisMi)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      kayit.mesaj,
                      style: TextStyle(
                        fontWeight: okunmamisMi
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'Zon ${kayit.zone} — ${TarihBicimleri.tamZamanli.format(kayit.zaman)}',
                    ),
                  );
                },
              ),
            ),
    );
  }
}
