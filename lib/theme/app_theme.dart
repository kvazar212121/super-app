import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_tokens.dart';
import 'lux_tokens.dart';

class AppTheme {
  static ThemeData lightTheme = _build(Brightness.light);
  static ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    // Dark (premium) rejim — lokal Plus Jakarta Sans (asset).
    // Light rejim — eski Inter (google_fonts), o'zgarishsiz.
    final textTheme =
        (isDark
                ? base.textTheme.apply(fontFamily: LuxTokens.body)
                : GoogleFonts.interTextTheme(base.textTheme))
            .apply(
              bodyColor: isDark ? LuxTokens.text : const Color(0xFF000000),
              displayColor: isDark ? LuxTokens.text : const Color(0xFF000000),
            );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? LuxTokens.bg : const Color(0xFFEEF2FF),
      colorScheme:
          ColorScheme.fromSeed(
            // Dark rejimda urg'u OLTIN, light rejimda eski ko'k saqlanadi.
            seedColor: isDark ? LuxTokens.gold : const Color(0xFF3B82F6),
            secondary: isDark ? LuxTokens.goldSoft : const Color(0xFF06B6D4),
            brightness: brightness,
            surface: isDark ? LuxTokens.surface : Colors.white,
          ).copyWith(
            primary: isDark ? LuxTokens.gold : null,
            onPrimary: isDark ? const Color(0xFF14100A) : null,
          ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      fontFamily: isDark ? LuxTokens.body : GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? LuxTokens.gold : const Color(0xFF3B82F6),
          foregroundColor: isDark ? const Color(0xFF14100A) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? LuxTokens.goldSoft : const Color(0xFF6366F1),
          side: BorderSide(
            color: isDark ? LuxTokens.goldDim : const Color(0xFF3B82F6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? LuxTokens.surfaceHigh : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : Colors.white,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? LuxTokens.gold : const Color(0xFF3B82F6),
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(
          color: isDark ? LuxTokens.textFaint : const Color(0xFF94A3B8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? LuxTokens.border : Colors.black,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? LuxTokens.gold : const Color(0xFF3B82F6),
        foregroundColor: isDark ? const Color(0xFF14100A) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
        ),
      ),
    );
  }
}
