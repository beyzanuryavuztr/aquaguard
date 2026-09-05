/// AquaGuard - Tema Modu Tercihi
/// =====================================
///
/// Amac:
///   Operatorun Ayarlar'dan sectigi görünüm tercihini (Koyu/Açık/Sistem)
///   temsil eder ve bunu Flutter'in kendi `ThemeMode`'una cevirir --
///   `main.dart` sadece `flutterModu` degerini kullanir, `ThemeMode`
///   mantigi bu tek dosyada kalir.
///
/// Tarih:  2026-09-05
library;

import 'package:flutter/material.dart';

enum TemaModu { koyu, acik, sistem }

extension TemaModuX on TemaModu {
  String get etiket => switch (this) {
    TemaModu.koyu => 'Koyu',
    TemaModu.acik => 'Açık',
    TemaModu.sistem => 'Sistem',
  };

  ThemeMode get flutterModu => switch (this) {
    TemaModu.koyu => ThemeMode.dark,
    TemaModu.acik => ThemeMode.light,
    TemaModu.sistem => ThemeMode.system,
  };

  static TemaModu isimdenAyristir(String? isim) => TemaModu.values.firstWhere(
    (t) => t.name == isim,
    orElse: () => TemaModu.koyu,
  );
}
