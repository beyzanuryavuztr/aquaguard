/// AquaGuard - Uygulama Tema Tanimi
/// ====================================
///
/// Amac:
///   Tum uygulamada tutarli, profesyonel bir gorunum icin tek bir tema
///   kaynagi. Renk, tipografi, kart/buton/form bilesenlerinin gorunumu
///   burada tanimlanir; ekranlar sadece Theme.of(context) uzerinden
///   bu degerleri kullanir, kendi renk/boyut sabitlerini uydurmaz.
///
///   TASARIM KARARI (2026-09-03 -- "SDI Tıkanma Yonetim Merkezi" yenilemesi):
///   Onceki turun acik/beyaz-kart temasi terk edilip SADECE koyu tema
///   sunulmustu (hem "tarla gunesinde ekran okunabilirligi" hem de teknik/
///   profesyonel bir "kontrol merkezi" hissi icin). PIYASA-HAZIRLIK TURU
///   ONCELIK 14 (2026-09-05): operatorun kendi tercihine gore Koyu/Açık/
///   Sistem secebilmesi icin `acikTema()` eklendi (bkz. main.dart +
///   Ayarlar'daki tema secici) -- koyu tema hala VARSAYILAN, acik tema
///   opsiyonel bir alternatif. Marka rengi (turkuvaz vurgu) VE app bar/
///   navigasyon rayinin koyu lacivert (`anaRenk`) arka plani HER IKI temada
///   da AYNI kalir (bilincli karar: marka kimligi tema secimine gore
///   degismemeli, sadece govde/kart yuzeyleri acilir/koyulasir).
///
///   Renk paleti kullanicinin verdigi kesin hex degerleriyle birebir
///   uygulanmistir:
///     - Ana (marka): #0D2137 (koyu lacivert/petrol) -- ETKILESIMLI (buton/
///       secili durum) renk DEGIL, derin marka/yuzey rengi olarak kullanilir
///       (nav rail, app bar arka planlari, gradyanlar).
///     - Vurgu: #00BFA6 (turkuvaz) -- ColorScheme.primary'dir; koyu arka
///       planda YETERLI KONTRAST veren, tiklanabilir/etkilesimli her seyin
///       (buton, secili sekme, linkler) rengi budur.
///     - Basari: #43A047, Uyari: #FFB300, Tehlike: #E53935.
///   Bu 3 durum rengi, DurumRenkleri sinifindaki "tedavide" (ayrı bir mavi,
///   #2E90FA) haric TUM zon/tedavi durum gostergelerinin de temelidir --
///   marka rengiyle (turkuvaz) durum rengi KASITLI olarak AYRISIR (aksi
///   halde "bu turkuvaz marka mı yoksa bir durum mu?" belirsizligi olusur).
///
/// Tarih:  2026-09-01 (koyu tema yenilemesi: 2026-09-03)
/// Yazar:  Beyzanur (AquaGuard - Arge-T HydroLab, TEKNOFEST 2026)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AquaGuardTema {
  AquaGuardTema._();

  // --- Kullanicinin verdigi kesin palet ---
  static const Color anaRenk = Color(0xFF0D2137); // koyu lacivert/petrol
  static const Color vurguRenk = Color(0xFF00BFA6); // turkuvaz/aqua
  static const Color uyariRenk = Color(0xFFFFB300); // amber
  static const Color tehlikeRenk = Color(0xFFE53935); // kirmizi
  static const Color basariRenk = Color(0xFF43A047); // yesil
  static const Color arkaPlanRenk = Color(0xFF121820); // cok koyu gri
  static const Color kartRenk = Color(0xFF1A2332); // yari saydam koyu

  static const double kartRadius = 16;
  static const double kucukRadius = 12;

  static TextTheme _tipografi(TextTheme taban, Color renk) {
    return GoogleFonts.interTextTheme(
      taban,
    ).apply(bodyColor: renk, displayColor: renk);
  }

  static ThemeData koyuTema() {
    const renkSemasi = ColorScheme(
      brightness: Brightness.dark,
      primary: vurguRenk,
      onPrimary: Color(0xFF00251F),
      primaryContainer: Color(0xFF00473C),
      onPrimaryContainer: Color(0xFF7BFFE9),
      secondary: basariRenk,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF1E4D24),
      onSecondaryContainer: Color(0xFFC8F5CC),
      tertiary: uyariRenk,
      onTertiary: Color(0xFF3D2900),
      tertiaryContainer: Color(0xFF5C3F00),
      onTertiaryContainer: Color(0xFFFFE4A8),
      error: tehlikeRenk,
      onError: Colors.white,
      errorContainer: Color(0xFF601410),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: arkaPlanRenk,
      onSurface: Color(0xFFE6ECF1),
      surfaceContainerLowest: Color(0xFF0A0F15),
      surfaceContainerLow: Color(0xFF141C25),
      surfaceContainer: kartRenk,
      surfaceContainerHigh: Color(0xFF212C3A),
      surfaceContainerHighest: Color(0xFF2A3747),
      onSurfaceVariant: Color(0xFF9AACBC),
      outline: Color(0xFF3A4A5C),
      outlineVariant: Color(0xFF283645),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE6ECF1),
      onInverseSurface: anaRenk,
      inversePrimary: Color(0xFF00695C),
    );

    return _bilesenTemasiOlustur(renkSemasi, Brightness.dark);
  }

  static ThemeData acikTema() {
    const renkSemasi = ColorScheme(
      brightness: Brightness.light,
      primary: vurguRenk,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFB2F5EA),
      onPrimaryContainer: Color(0xFF00443B),
      secondary: basariRenk,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFC8F5CC),
      onSecondaryContainer: Color(0xFF1E4D24),
      tertiary: uyariRenk,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFE4A8),
      onTertiaryContainer: Color(0xFF3D2900),
      error: tehlikeRenk,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF601410),
      surface: Color(0xFFF6F8FA),
      onSurface: Color(0xFF1A2332),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF0F3F6),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Color(0xFFE8ECF1),
      surfaceContainerHighest: Color(0xFFDEE4EA),
      onSurfaceVariant: Color(0xFF5C6B7A),
      outline: Color(0xFFC5CDD6),
      outlineVariant: Color(0xFFDDE3E9),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: anaRenk,
      onInverseSurface: Color(0xFFE6ECF1),
      inversePrimary: Color(0xFF7BFFE9),
    );

    return _bilesenTemasiOlustur(renkSemasi, Brightness.light);
  }

  /// Koyu ve acik tema TAMAMEN AYNI bilesen (AppBar/Card/buton/...) stilini
  /// paylasir -- SADECE ColorScheme farklidir. Bu, iki temanin zamanla
  /// birbirinden SESSIZCE sapmasini onler (bkz. proje geneli "tek kaynak"
  /// ilkesi).
  static ThemeData _bilesenTemasiOlustur(
    ColorScheme renkSemasi,
    Brightness parlaklik,
  ) {
    final tabanTema = ThemeData(brightness: parlaklik);
    final metinTemasi = _tipografi(tabanTema.textTheme, renkSemasi.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: renkSemasi,
      scaffoldBackgroundColor: renkSemasi.surface,
      textTheme: metinTemasi,

      appBarTheme: AppBarTheme(
        backgroundColor: anaRenk,
        foregroundColor: const Color(0xFFE6ECF1),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE6ECF1),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
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
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
        hintStyle: TextStyle(color: renkSemasi.onSurfaceVariant),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        backgroundColor: renkSemasi.surfaceContainerHigh,
        selectedColor: renkSemasi.primaryContainer,
        labelStyle: GoogleFonts.inter(color: renkSemasi.onSurface),
      ),

      dividerTheme: DividerThemeData(
        color: renkSemasi.outlineVariant,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: renkSemasi.onSurfaceVariant,
        textColor: renkSemasi.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: renkSemasi.surfaceContainerHighest,
        contentTextStyle: GoogleFonts.inter(color: renkSemasi.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kucukRadius),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: anaRenk,
        selectedIconTheme: IconThemeData(color: renkSemasi.primary),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF9AACBC)),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: renkSemasi.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: const Color(0xFF9AACBC),
        ),
        indicatorColor: renkSemasi.primaryContainer,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: anaRenk,
        indicatorColor: renkSemasi.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final secili = states.contains(WidgetState.selected);
          return IconThemeData(
            color: secili ? renkSemasi.primary : const Color(0xFF9AACBC),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final secili = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: secili ? renkSemasi.primary : const Color(0xFF9AACBC),
            fontWeight: secili ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          );
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? renkSemasi.primary
              : renkSemasi.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? renkSemasi.primaryContainer
              : renkSemasi.surfaceContainerHighest,
        ),
      ),
    );
  }
}
