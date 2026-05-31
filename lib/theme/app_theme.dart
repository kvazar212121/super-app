import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_tokens.dart';

class AppTheme {
  static ThemeData lightTheme = _build(Brightness.light);
  static ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      displayColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0B0B1A) : const Color(0xFFEEF2FF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        secondary: const Color(0xFF06B6D4),
        brightness: brightness,
        surface: isDark
            ? const Color(0xFF1E1E2E).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.6),
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
      fontFamily: GoogleFonts.inter().fontFamily,
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
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
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
          foregroundColor: isDark ? Colors.white : const Color(0xFF6366F1),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFF6366F1).withValues(alpha: 0.35),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.45)
              : const Color(0xFF94A3B8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
        ),
      ),
    );
  }
}
