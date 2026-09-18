/// AquaGuard - Guvenlik Karti (PIN Korumasi, Ayarlar bolumu)
/// ================================================================
///
/// Amac:
///   4 haneli PIN korumasini acma/kapatma/degistirme.
///
///   `AyarlarEkrani`'nin A6 (bolunme) fazinda ayri bir dosyaya cikarildi --
///   dogrudan GuvenlikProvider'i izler, facade uzerinden DEGIL.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/guvenlik_provider.dart';

class GuvenlikKarti extends StatelessWidget {
  const GuvenlikKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final guvenlik = context.watch<GuvenlikProvider>();

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('PIN Koruması'),
            subtitle: Text(
              guvenlik.pinKorumasiAktif
                  ? 'Uygulama her açılışta 4 haneli PIN ister'
                  : 'Kapalı — uygulama doğrudan açılır',
            ),
            value: guvenlik.pinKorumasiAktif,
            onChanged: (deger) => deger
                ? _pinBelirleDialoguGoster(context)
                : context.read<GuvenlikProvider>().pinKorumasiniKapat(),
          ),
          if (guvenlik.pinKorumasiAktif) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('PIN Değiştir'),
              onTap: () => _pinBelirleDialoguGoster(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// "PIN Koruması"nı ilk kez açarken veya mevcut PIN'i değiştirirken
/// gösterilen dialog -- 4 haneli yeni PIN + tekrar, eşleşmezse/4 hane
/// değilse hata gösterir, doğruysa GuvenlikProvider.pinKorumasiniAc'i çağırır.
Future<void> _pinBelirleDialoguGoster(BuildContext context) async {
  final guvenlik = context.read<GuvenlikProvider>();
  final yeniPinDenetci = TextEditingController();
  final tekrarPinDenetci = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('PIN Belirle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: yeniPinDenetci,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Yeni PIN (4 hane)'),
          ),
          TextField(
            controller: tekrarPinDenetci,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'PIN (Tekrar)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () async {
            final yeni = yeniPinDenetci.text;
            final tekrar = tekrarPinDenetci.text;
            if (yeni.length != 4 || int.tryParse(yeni) == null) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('PIN 4 haneli rakam olmalı')),
              );
              return;
            }
            if (yeni != tekrar) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('PIN\'ler eşleşmiyor')),
              );
              return;
            }
            await guvenlik.pinKorumasiniAc(yeni);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}
