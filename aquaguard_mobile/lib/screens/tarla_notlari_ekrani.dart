/// AquaGuard - Tarla Notlari Ekrani
/// ====================================
///
/// Amac:
///   Operatorun bir tarlaya dair serbest metin notlarini (bkz.
///   models/tarla_notu.dart) goruntulemesini, eklemesini ve silmesini
///   saglar. AktiviteKaydi'ndan (sistem otomatik uretir) farkli olarak
///   TAMAMEN operatorun kendi yazdigi kayitlardir.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tarih_bicimleri.dart';
import '../models/tarla.dart';
import '../providers/uygulama_durumu.dart';
import '../widgets/duyarli_icerik.dart';

class TarlaNotlariEkrani extends StatefulWidget {
  final Tarla tarla;
  const TarlaNotlariEkrani({super.key, required this.tarla});

  @override
  State<TarlaNotlariEkrani> createState() => _TarlaNotlariEkraniState();
}

class _TarlaNotlariEkraniState extends State<TarlaNotlariEkrani> {
  final _notController = TextEditingController();

  @override
  void dispose() {
    _notController.dispose();
    super.dispose();
  }

  void _notEkle() {
    final durum = context.read<UygulamaDurumu>();
    durum.notEkle(widget.tarla.id, _notController.text);
    _notController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final notlar = context.watch<UygulamaDurumu>().tarlaNotlari(
      widget.tarla.id,
    );

    return Scaffold(
      appBar: AppBar(title: Text('${widget.tarla.ad} - Notlar')),
      body: DuyarliIcerik(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _notController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _notEkle(),
                      decoration: const InputDecoration(
                        hintText: 'Yeni not yazın... örn. "15.09 gübreleme yapıldı"',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: 'Notu Ekle',
                    onPressed: _notEkle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: notlar.isEmpty
                  ? const Center(
                      child: Text('Henüz not eklenmedi.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: notlar.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final not = notlar[index];
                        return ListTile(
                          leading: const Icon(Icons.sticky_note_2_outlined),
                          title: Text(not.metin),
                          subtitle: Text(
                            TarihBicimleri.tamZamanliSaniyesiz.format(not.zaman),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Notu Sil',
                            onPressed: () => context
                                .read<UygulamaDurumu>()
                                .notSil(not.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
