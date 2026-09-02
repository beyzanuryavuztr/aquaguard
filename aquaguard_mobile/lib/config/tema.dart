/// AquaGuard - Uygulama Tema Tanimi
/// ====================================
///
/// Amac:
///   Tum uygulamada tutarli, profesyonel bir gorunum icin tek bir tema
///   kaynagi. Renk, tipografi, kart/buton/form bilesenlerinin gorunumu
///   burada tanimlanir; ekranlar sadece Theme.of(context) uzerinden
///   bu degerleri kullanir, kendi renk/boyut sabitlerini uydurmaz.
///
///   TASARIM KARARI (2026-09-02 yenileme): `ColorScheme.fromSeed()`'in
///   otomatik uretttigi tonal palet (tek bir renkten turetilen soluk,
///   yesile-cekik yuzeyler) "ucuz/jenerik" izlenimi veriyordu -- Stripe/
///   Linear/Notion gibi profesyonel dashboard'larin hicbiri boyle
///   calismaz. Bunun yerine ELLE seçilmiş bir palet kullanilir:
///     - Marka rengi: koyu, doygun bir deniz mavisi-yesili (teal) --
///       "su + teknoloji" cagrisimini yesilden daha net verir ve durum
///       renklerinden (yesil=normal, sari=belirsiz, kirmizi=tespit)
///       AYRISIR (marka rengiyle durum rengi karismasin diye kasitli).
///     - Yuzeyler: DUZ BEYAZ kartlar + yumusak golge (soluk yesil-gri
///       "tonal container" degil) -- bu, "flat renkli kutu" degil
///       "gercek kart" hissi verir.
///     - Tipografi: Google Fonts "Plus Jakarta Sans" -- varsayilan
///       Roboto yerine, modern SaaS dashboard'larinda yaygin kullanilan,
///       daha ozgun bir yazi tipi.
///
/// Tarih:  2026-09-01 (buyuk yenileme: 2026-09-02)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AquaGuardTema {
  AquaGuardTema._();

  // --- Marka paleti (elle secilmis, ColorScheme.fromSeed KULLANILMIYOR) ---
  static const Color marka = Color(
    0xFF0F766E,
  ); // derin deniz mavisi-yesili (teal-700)
  static const Color markaAcik = Color(
    0xFF14B8A6,
  ); // vurgular icin daha canli ton
  static const Color markaKoyuMetin = Color(0xFF042F2C);
  static const Color ikincilYesil = Color(
    0xFF2E7D32,
  ); // durum "normal" ile bilincli hizali

  static const double kartRadius = 18;
  static const double kucukRadius = 12;

  static TextTheme _tipografi(TextTheme taban, Color renk) {
    return GoogleFonts.plusJakartaSansTextTheme(
      taban,
    ).apply(bodyColor: renk, displayColor: renk);
  }

  static ThemeData acikTema() {
    const renkSemasi = ColorScheme(
      brightness: Brightness.light,
      primary: marka,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCCFBF1),
      onPrimaryContainer: markaKoyuMetin,
      secondary: ikincilYesil,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDCFCE7),
      onSecondaryContainer: Color(0xFF0B3B14),
      tertiary: Color(0xFFB45309),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFEF3C7),
      onTertiaryContainer: Color(0xFF4A2E03),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: Colors.white,
      onSurface: Color(0xFF1B2430),
      surfaceContainerLowest: Color(0xFFF4F6F8),
      surfaceContainerLow: Color(0xFFF7F9FA),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Color(0xFFF1F4F6),
      surfaceContainerHighest: Color(0xFFEAEFF2),
      onSurfaceVariant: Color(0xFF5B6B79),
      outline: Color(0xFFD6DEE3),
      outlineVariant: Color(0xFFE7ECEF),
      shadow: Color(0xFF0B1B2B),
      scrim: Colors.black,
      inverseSurface: Color(0xFF1B2430),
      onInverseSurface: Colors.white,
      inversePrimary: markaAcik,
    );

    return _temaOlustur(renkSemasi);
  }

  static ThemeData koyuTema() {
    const renkSemasi = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF5EEAD4),
      onPrimary: Color(0xFF003731),
      primaryContainer: Color(0xFF0B5B53),
      onPrimaryContainer: Color(0xFFCCFBF1),
      secondary: Color(0xFF86E0A0),
      onSecondary: Color(0xFF0B3B14),
      secondaryContainer: Color(0xFF1E5128),
      onSecondaryContainer: Color(0xFFDCFCE7),
      tertiary: Color(0xFFFBBF6B),
      onTertiary: Color(0xFF4A2E03),
      tertiaryContainer: Color(0xFF7A4B0B),
      onTertiaryContainer: Color(0xFFFEF3C7),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      surface: Color(0xFF121A22),
      onSurface: Color(0xFFE3E8EC),
      surfaceContainerLowest: Color(0xFF0B1117),
      surfaceContainerLow: Color(0xFF161F27),
      surfaceContainer: Color(0xFF1A232C),
      surfaceContainerHigh: Color(0xFF212B34),
      surfaceContainerHighest: Color(0xFF2B3640),
      onSurfaceVariant: Color(0xFFAAB6C0),
      outline: Color(0xFF3A4750),
      outlineVariant: Color(0xFF2A343C),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE3E8EC),
      onInverseSurface: Color(0xFF121A22),
      inversePrimary: marka,
    );

    return _temaOlustur(renkSemasi);
  }

  static ThemeData _temaOlustur(ColorScheme renkSemasi) {
    final tabanTema = ThemeData(brightness: renkSemasi.brightness);
    final metinTemasi = _tipografi(tabanTema.textTheme, renkSemasi.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: renkSemasi,
      scaffoldBackgroundColor: renkSemasi.surfaceContainerLowest,
      textTheme: metinTemasi,

      appBarTheme: AppBarTheme(
        backgroundColor: renkSemasi.surfaceContainerLowest,
        foregroundColor: renkSemasi.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: renkSemasi.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 1.5,
        shadowColor: renkSemasi.shadow.withValues(alpha: 0.08),
        color: renkSemasi.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kartRadius),
          side: BorderSide(color: renkSemasi.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: renkSemasi.primary,
          foregroundColor: renkSemasi.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kucukRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: renkSemasi.primary,
          side: BorderSide(color: renkSemasi.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kucukRadius),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: renkSemasi.primary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: renkSemasi.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
          borderSide: BorderSide(color: renkSemasi.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        backgroundColor: renkSemasi.surfaceContainerHigh,
        selectedColor: renkSemasi.primaryContainer,
        labelStyle: GoogleFonts.plusJakartaSans(color: renkSemasi.onSurface),
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
        backgroundColor: renkSemasi.inverseSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: renkSemasi.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: renkSemasi.surfaceContainerLowest,
        selectedIconTheme: IconThemeData(color: renkSemasi.primary),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: renkSemasi.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: renkSemasi.onSurfaceVariant,
        ),
        indicatorColor: renkSemasi.primaryContainer,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: renkSemasi.surfaceContainerLowest,
        indicatorColor: renkSemasi.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final secili = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            color: secili ? renkSemasi.primary : renkSemasi.onSurfaceVariant,
            fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          );
        }),
      ),
    );
  }
}
