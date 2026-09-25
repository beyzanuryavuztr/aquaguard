/// AquaGuard - Hesap Kartı (Ayarlar bölümü)
/// =============================================
///
/// Amaç:
///   Oturum açık e-postayı gösterir + "Çıkış Yap". Firebase henüz
///   yapılandırılmadıysa (bkz. config/firebase_secenekleri.dart) bu kart
///   TAMAMEN GİZLİDİR -- AyarlarEkrani'nden çağıran taraf
///   [firebaseYapilandirildiMi] kontrolünü yapar.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/kimlik_dogrulama_provider.dart';

class HesapKarti extends StatelessWidget {
  const HesapKarti({super.key});

  @override
  Widget build(BuildContext context) {
    final kimlik = context.watch<KimlikDogrulamaProvider>();
    final kullanici = kimlik.kullanici;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_circle_outlined),
        title: Text(kullanici?.eposta ?? 'Misafir olarak kullanılıyor'),
        subtitle: Text(
          kullanici != null
              ? 'Oturum açık'
              : 'Çıkış yaparsanız tekrar giriş ekranı gösterilir',
        ),
        trailing: TextButton(
          onPressed: () => context.read<KimlikDogrulamaProvider>().cikisYap(),
          child: const Text('Çıkış Yap'),
        ),
      ),
    );
  }
}
