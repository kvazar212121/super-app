import 'package:flutter/material.dart';
import '../../theme/lux_tokens.dart';

/// Orqa fonda rangli "orb"lar — glass effekt uchun asos (yengil versiya).
class MeshBackground extends StatelessWidget {
  final bool isDark;

  const MeshBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Yuqa zangori-ko'k fon — barcha ekranlarda bir xil nafis fon
    return ColoredBox(
      color: isDark ? LuxTokens.bg : const Color(0xFFEFF4FA),
    );
  }
}

/// Istalgan ekran tanasini mesh fon ustiga joylaydi.
/// Booking/ichki ekranlarda Scaffold'ni shaffof qilib, shu bilan o'rang.
class GlassBackdrop extends StatelessWidget {
  final Widget child;

  const GlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        MeshBackground(isDark: isDark),
        child,
      ],
    );
  }
}


