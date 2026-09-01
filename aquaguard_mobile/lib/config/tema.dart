/// AquaGuard - Uygulama Tema Tanimi
/// ====================================
///
/// Amac:
///   Tum uygulamada tutarli, profesyonel bir gorunum icin tek bir tema
///   kaynagi. Renk, tipografi, kart/buton/form bilesenlerinin gorunumu
///   burada tanimlanir; ekranlar sadece Theme.of(context) uzerinden
///   bu degerleri kullanir, kendi renk/boyut sabitlerini uydurmaz.
///
/// Tarih:  2026-09-01
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';

class AquaGuardTema {
  AquaGuardTema._();

  static const Color _tohumRengi = Color(0xFF2E7D32); // AquaGuard yesili

  static const double kartRadius = 16;
  static const double kucukRadius = 10;

  static ThemeData acikTema() {
    final renkSemasi = ColorScheme.fromSeed(
      seedColor: _tohumRengi,
      brightness: Brightness.light,
    );

    return _temaOlustur(renkSemasi);
  }

  static ThemeData koyuTema() {
    final renkSemasi = ColorScheme.fromSeed(
      seedColor: _tohumRengi,
      brightness: Brightness.dark,
    );

    return _temaOlustur(renkSemasi);
  }

  static ThemeData _temaOlustur(ColorScheme renkSemasi) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: renkSemasi,
      scaffoldBackgroundColor: renkSemasi.surfaceContainerLowest,

      appBarTheme: AppBarTheme(
        backgroundColor: renkSemasi.surface,
        foregroundColor: renkSemasi.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: renkSemasi.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: renkSemasi.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kartRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kucukRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kucukRadius),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: renkSemasi.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),

      dividerTheme: DividerThemeData(
        color: renkSemasi.outlineVariant,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: renkSemasi.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
        ),
      ),
    );
  }
}
