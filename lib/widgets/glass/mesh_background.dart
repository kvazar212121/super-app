import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';

/// Orqa fonda rangli "orb"lar — glass effekt uchun asos.
class MeshBackground extends StatelessWidget {
  final bool isDark;

  const MeshBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mesh = GlassTokens.meshColorsLight(isDark);
    final orbs = GlassTokens.orbColorsLight(isDark);

    return DecoratedBox(
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
          if (!isDark)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.white.withValues(alpha: 0.02)),
            ),
        ],
      ),
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
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
