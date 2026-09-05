import 'package:flutter/material.dart';
import '../../theme/lux_tokens.dart';

/// Soha egasi (provider) paneli uchun majburiy yorug' (light) tema.
///
/// Mijoz ilovasi dark rejimda bo'lsa ham, biznes paneli har doim oq fon va
/// qora matnli bo'ladi. Shriftlar hajmi soha egalari uchun maxsus 20-30% ga
/// ixchamlashtirilgan.
class ProviderTheme extends StatelessWidget {
  final Widget child;

  const ProviderTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const ink = Colors.black;
    const primary = Colors.black;
    final base = ThemeData.light(useMaterial3: true);

    TextTheme scaleTextTheme(TextTheme theme, double factor) {
      TextStyle? safeScale(TextStyle? s) {
        if (s == null) return null;
        final fontSize = s.fontSize;
        if (fontSize == null) return s;
        return s.copyWith(fontSize: fontSize * factor);
      }

      return theme.copyWith(
        displayLarge: safeScale(theme.displayLarge),
        displayMedium: safeScale(theme.displayMedium),
        displaySmall: safeScale(theme.displaySmall),
        headlineLarge: safeScale(theme.headlineLarge),
        headlineMedium: safeScale(theme.headlineMedium),
        headlineSmall: safeScale(theme.headlineSmall),
        titleLarge: safeScale(theme.titleLarge),
        titleMedium: safeScale(theme.titleMedium),
        titleSmall: safeScale(theme.titleSmall),
        bodyLarge: safeScale(theme.bodyLarge),
        bodyMedium: safeScale(theme.bodyMedium),
        bodySmall: safeScale(theme.bodySmall),
        labelLarge: safeScale(theme.labelLarge),
        labelMedium: safeScale(theme.labelMedium),
        labelSmall: safeScale(theme.labelSmall),
      ).apply(bodyColor: ink, displayColor: ink);
    }

    final textTheme = scaleTextTheme(base.textTheme, 0.82);

    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: LuxTokens.surface,
        colorScheme: base.colorScheme.copyWith(
          primary: primary,
          surface: Colors.white,
          onSurface: ink,
          outline: const Color(0xFFE5E7EB),
          outlineVariant: LuxTokens.textMuted,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          contentTextStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: LuxTokens.surface,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      child: child,
    );
  }
}
