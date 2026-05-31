import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';

/// Orqa fonda rangli "orb"lar — glass effekt uchun asos (yengil versiya).
class MeshBackground extends StatelessWidget {
  final bool isDark;

  const MeshBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mesh = GlassTokens.meshColorsLight(isDark);
    final orbs = GlassTokens.orbColorsLight(isDark);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: mesh,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Orb(top: -80, left: -60, size: 260, color: orbs[0]),
            _Orb(top: 120, right: -90, size: 220, color: orbs[1]),
            _Orb(bottom: 180, left: -40, size: 200, color: orbs[2]),
            _Orb(bottom: -50, right: 20, size: 280, color: orbs[3]),
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

class _Orb extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  const _Orb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
