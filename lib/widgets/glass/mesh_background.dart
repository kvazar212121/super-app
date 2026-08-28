import 'package:flutter/material.dart';
import '../../theme/lux_tokens.dart';

/// Orqa fonda rangli "orb"lar — glass effekt uchun asos (yengil versiya).
class MeshBackground extends StatelessWidget {
  final bool isDark;

  const MeshBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Light rejim — toza OQ fon (rasm yo'q).
    if (!isDark) {
      return const ColoredBox(color: Colors.white);
    }
    // Dark rejim — deyarli tekis qora. Premium ko'rinishda fon "jim"
    // turishi kerak, e'tibor kartalarga va oltin urg'ularga qaratiladi.
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C0C0D),
            LuxTokens.bg,
            Color(0xFF08080A),
          ],
        ),
      ),
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


