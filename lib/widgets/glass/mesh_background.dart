import 'package:flutter/material.dart';

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
    // Dark rejim — qorong'i gradient (rasm ishlatilmaydi).
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0B1A),
            Color(0xFF151530),
            Color(0xFF0D2847),
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


