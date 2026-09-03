/// AquaGuard - Akilli Asistan Ekrani
/// =====================================
///
/// Amac:
///   Operatorun serbest metinle sistem durumu hakkinda soru sorabildigi
///   sohbet arayuzu. Yanitlar tamamen yerel/kural tabanlidir (bkz.
///   services/asistan_servisi.dart) -- internet/API bagimliligi yoktur.
///
/// Tarih:  2026-09-03
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uygulama_durumu.dart';
import '../services/asistan_servisi.dart';
import '../widgets/duyarli_icerik.dart';

class _SohbetMesaji {
  final String metin;
  final bool kullanicidanMi;
  const _SohbetMesaji({required this.metin, required this.kullanicidanMi});
}

class AsistanEkrani extends StatefulWidget {
  const AsistanEkrani({super.key});

  @override
  State<AsistanEkrani> createState() => _AsistanEkraniState();
}

class _AsistanEkraniState extends State<AsistanEkrani> {
  final _kontrolcu = TextEditingController();
  final _kaydirmaKontrolcusu = ScrollController();
  final List<_SohbetMesaji> _mesajlar = [
    const _SohbetMesaji(
      metin:
          'Merhaba! Ben AquaGuard Akıllı Asistanı. Size sistemin o anki '
          'canlı durumu hakkında yardımcı olabilirim -- aşağıdaki örnek '
          'sorulardan birini deneyebilir ya da kendi sorunuzu yazabilirsiniz.',
      kullanicidanMi: false,
    ),
  ];

  @override
  void dispose() {
    _kontrolcu.dispose();
    _kaydirmaKontrolcusu.dispose();
    super.dispose();
  }

  void _mesajGonder(String metin) {
    final soru = metin.trim();
    if (soru.isEmpty) return;

    final durum = context.read<UygulamaDurumu>();
    final yanit = AsistanServisi.yanitUret(soru, durum);

    setState(() {
      _mesajlar.add(_SohbetMesaji(metin: soru, kullanicidanMi: true));
      _mesajlar.add(_SohbetMesaji(metin: yanit, kullanicidanMi: false));
    });
    _kontrolcu.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_kaydirmaKontrolcusu.hasClients) return;
      _kaydirmaKontrolcusu.animateTo(
        _kaydirmaKontrolcusu.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined),
            SizedBox(width: 8),
            Text('Akıllı Asistan'),
          ],
        ),
      ),
      body: DuyarliIcerik(
        maksimumGenislik: 760,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _kaydirmaKontrolcusu,
                padding: const EdgeInsets.all(16),
                itemCount: _mesajlar.length,
                itemBuilder: (context, index) =>
                    _MesajBalonu(mesaj: _mesajlar[index]),
              ),
            ),
            if (_mesajlar.length <= 1) _OrnekSorularSeridi(onSecim: _mesajGonder),
            _SoruGirisAlani(kontrolcu: _kontrolcu, onGonder: _mesajGonder),
          ],
        ),
      ),
    );
  }
}

class _MesajBalonu extends StatelessWidget {
  final _SohbetMesaji mesaj;
  const _MesajBalonu({required this.mesaj});

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;
    final kullanicidan = mesaj.kullanicidanMi;

    return Align(
      alignment: kullanicidan ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kullanicidan ? renkSemasi.primary : renkSemasi.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(kullanicidan ? 16 : 4),
            bottomRight: Radius.circular(kullanicidan ? 4 : 16),
          ),
          border: kullanicidan
              ? null
              : Border.all(color: renkSemasi.outlineVariant),
        ),
        child: Text(
          mesaj.metin,
          style: TextStyle(
            color: kullanicidan ? renkSemasi.onPrimary : renkSemasi.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _OrnekSorularSeridi extends StatelessWidget {
  final ValueChanged<String> onSecim;
  const _OrnekSorularSeridi({required this.onSecim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final ornek in AsistanServisi.ornekSorular)
            ActionChip(
              label: Text(ornek),
              onPressed: () => onSecim(ornek),
            ),
        ],
      ),
    );
  }
}

class _SoruGirisAlani extends StatelessWidget {
  final TextEditingController kontrolcu;
  final ValueChanged<String> onGonder;

  const _SoruGirisAlani({required this.kontrolcu, required this.onGonder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: kontrolcu,
              textInputAction: TextInputAction.send,
              onSubmitted: onGonder,
              decoration: const InputDecoration(
                hintText: 'Bir soru yazın... örn. "zon 2 nasıl?"',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send),
            tooltip: 'Gönder',
            onPressed: () => onGonder(kontrolcu.text),
          ),
        ],
      ),
    );
  }
}
