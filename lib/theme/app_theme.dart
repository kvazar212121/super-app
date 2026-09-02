import 'package:flutter/material.dart';
import 'glass_tokens.dart';
import 'lux_tokens.dart';

class AppTheme {
  static ThemeData lightTheme = _build(Brightness.light);
  static ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    // Ikkala rejim ham LOKAL Plus Jakarta Sans (assets/fonts) ishlatadi.
    //
    // NEGA google_fonts EMAS: u shriftni birinchi ishga tushirishda
    // INTERNETDAN yuklaydi. Bu uch muammo bergan:
    //   1. Internetsiz qurilmada shrift tushib qolardi.
    //   2. Widget testlari tarmoqqa chiqa olmagani uchun YIQILARDI.
    //   3. Birinchi ochilishda matn "sakrab" almashardi.
    // Asset shrift bularning uchalasini ham yo'q qiladi.
    // BUTUN ILOVA SHRIFTI: Cormorant Garamond (nafis serif).
    // Foydalanuvchi so'rovi — banner bilan bir xil stil barcha ekranlarda.
    // Serif shrift ingichka ko'ringani uchun asosiy matnni sal qalinroq
    // (w600) qilamiz — o'qilishi yaxshiroq bo'ladi.
    final ink = isDark ? LuxTokens.text : const Color(0xFF000000);
    TextStyle? bolden(TextStyle? s) => s?.copyWith(
          fontFamily: LuxTokens.display,
          fontWeight: FontWeight.w700,
          color: ink,
        );
    final base2 = base.textTheme;
    final textTheme = base2.copyWith(
      displayLarge: bolden(base2.displayLarge),
      displayMedium: bolden(base2.displayMedium),
      displaySmall: bolden(base2.displaySmall),
      headlineLarge: bolden(base2.headlineLarge),
      headlineMedium: bolden(base2.headlineMedium),
      headlineSmall: bolden(base2.headlineSmall),
      titleLarge: bolden(base2.titleLarge),
      titleMedium: bolden(base2.titleMedium),
      titleSmall: bolden(base2.titleSmall),
      bodyLarge: bolden(base2.bodyLarge),
      bodyMedium: bolden(base2.bodyMedium),
      bodySmall: bolden(base2.bodySmall),
      labelLarge: bolden(base2.labelLarge),
      labelMedium: bolden(base2.labelMedium),
      labelSmall: bolden(base2.labelSmall),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? LuxTokens.bg : const Color(0xFFF8F9FA),
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: LuxTokens.gold,
            secondary: isDark ? LuxTokens.goldSoft : const Color(0xFF141416),
            brightness: brightness,
            surface: isDark ? LuxTokens.surface : Colors.white,
          ).copyWith(
            primary: LuxTokens.gold,
            onPrimary: isDark ? const Color(0xFF14100A) : Colors.black,
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
      fontFamily: LuxTokens.display,
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
          backgroundColor: LuxTokens.gold,
          foregroundColor: const Color(0xFF14100A),
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
          foregroundColor: isDark ? LuxTokens.goldSoft : LuxTokens.gold,
          side: BorderSide(
            color: isDark ? LuxTokens.goldDim : LuxTokens.gold,
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
            color: LuxTokens.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          borderSide: BorderSide(
            color: LuxTokens.gold,
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(
          color: isDark ? LuxTokens.textFaint : const Color(0xFF94A3B8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? LuxTokens.border : const Color(0xFFE2E8F0),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
        hourMinuteColor: Color(0xFFF1F5F9),
        hourMinuteTextColor: Color(0xFF0F172A),
        dayPeriodColor: Color(0xFFF1F5F9),
        dayPeriodTextColor: Color(0xFF0F172A),
        dialBackgroundColor: Color(0xFFF8FAFC),
        dialHandColor: Color(0xFFC99427),
        dialTextColor: Color(0xFF0F172A),
        entryModeIconColor: Color(0xFF8A5D0B),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: Color(0xFFC99427),
        headerForegroundColor: Color(0xFF140D02),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        textStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? LuxTokens.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? LuxTokens.gold.withValues(alpha: 0.5) : LuxTokens.gold.withValues(alpha: 0.7),
            width: 1.3,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: LuxTokens.display,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        contentTextStyle: TextStyle(
          fontFamily: LuxTokens.display,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: LuxTokens.gold,
        foregroundColor: const Color(0xFF14100A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
        ),
      ),
    );
  }
}
