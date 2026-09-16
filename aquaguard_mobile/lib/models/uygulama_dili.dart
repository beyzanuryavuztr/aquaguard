/// AquaGuard - Uygulama Dili (i18n, kisitli kapsam)
/// =======================================================
///
/// Amac:
///   Operatorun secebilecegi arayuz dili. Su an SADECE Ayarlar'daki
///   "Görünüm" bolumu bu secime gore render edilir (bkz. lib/l10n/
///   app_tr.arb dosya basi notu ve pubspec.yaml'daki i18n kapsam notu) --
///   uygulamanin geri kalani HALA sabit Turkce metin kullanir. Bu enum,
///   dil secimini kaydetmek/tasimak icin genel altyapidir; tam migrasyon
///   tamamlandikca daha fazla ekran bu secime tepki verecektir.
///
/// Tarih:  2026-09-16
library;

import 'package:flutter/material.dart';

enum UygulamaDili { turkce, ingilizce }

extension UygulamaDiliX on UygulamaDili {
  Locale get locale => switch (this) {
    UygulamaDili.turkce => const Locale('tr'),
    UygulamaDili.ingilizce => const Locale('en'),
  };
}
