import 'package:flutter/material.dart';
import 'lux_tokens.dart';

/// iOS-style frosted glass dizayn tokenlari.
abstract final class GlassTokens {
  static const radiusSm = 14.0;
  static const radiusMd = 20.0;
  static const radiusLg = 28.0;
  static const radiusXl = 32.0;

  static const blurLight = 18.0;
  static const blurHeavy = 28.0;

  /// Barcha shaffof panellar uchun bir xil qiymatlar (xiralashgan glass).
  static const glassOpacity = 1.0;
  static const glassBlur = blurLight;

  static List<Color> meshColorsLight(bool isDark) => isDark
      ? const [
          LuxTokens.bg,
          Color(0xFF101012),
          Color(0xFF161614),
          Color(0xFF0D0D0E),
        ]
      : const [
          Color(0xFFEEF2FF),
          Color(0xFFF5F3FF),
          Color(0xFFECFEFF),
          Color(0xFFFDF4FF),
        ];

  static List<Color> orbColorsLight(bool isDark) => isDark
      ? [
          LuxTokens.gold,
          LuxTokens.goldSoft,
          LuxTokens.goldDim,
          const Color(0xFF8A6E1A),
        ]
      : [
          const Color(0xFF6366F1),
          const Color(0xFFA855F7),
          const Color(0xFF06B6D4),
          const Color(0xFFEC4899),
        ];

  static Color glassFill(
    BuildContext context, {
    double opacity = glassOpacity,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Solid fill for panels instead of glass
    return isDark ? LuxTokens.surface : const Color(0xFFFFFFFF);
  }

  static Color glassBorder(BuildContext context) {
    return LuxTokens.border;
  }

  static Color glassHighlight(BuildContext context) {
    return Colors.transparent;
  }

  static Color primaryText(BuildContext context) {
    return const Color(0xFF17202A);
  }

  static Color secondaryText(BuildContext context) {
    return const Color(0xFF6B7280);
  }

  static List<BoxShadow> glassShadow(BuildContext context) => [
    BoxShadow(
      color: const Color(0xFF102A43).withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
