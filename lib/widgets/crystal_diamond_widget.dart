import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hyper-realistic 3D Sparkling Colorful Crystal Diamond Gemstone
class CrystalDiamondWidget extends StatelessWidget {
  final double size;

  const CrystalDiamondWidget({super.key, this.size = 46.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Glowing Iridescent Atmosphere Flare
          Container(
            width: size * 1.1,
            height: size * 1.1,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xB300F0FF), // Electric Cyan Glow
                  Color(0x807000FF), // Deep Violet Glow
                  Color(0x40FF007A), // Iridescent Pink Glow
                  Colors.transparent,
                ],
                stops: [0.0, 0.45, 0.75, 1.0],
              ),
            ),
          ),

          // 2. Multi-faceted 3D Crystal Diamond Facet Painter
          CustomPaint(
            size: Size(size, size),
            painter: _CrystalDiamondPainter(),
          ),

          // 3. Sparkle Glint Flares (Star sparkles on top & bottom corners)
          Positioned(
            top: size * 0.05,
            right: size * 0.12,
            child: _SparkleStar(size: size * 0.38),
          ),
          Positioned(
            bottom: size * 0.10,
            left: size * 0.10,
            child: _SparkleStar(size: size * 0.28),
          ),
        ],
      ),
    );
  }
}

class _SparkleStar extends StatelessWidget {
  final double size;
  const _SparkleStar({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarSparklePainter(),
      ),
    );
  }
}

class _StarSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final innerR = r * 0.18;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final x1 = cx + math.cos(angle) * r;
      final y1 = cy + math.sin(angle) * r;
      final angle2 = angle + math.pi / 4;
      final x2 = cx + math.cos(angle2) * innerR;
      final y2 = cy + math.sin(angle2) * innerR;

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Bright White Core
    canvas.drawCircle(Offset(cx, cy), innerR * 0.9, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrystalDiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Key points of brilliant cut diamond geometry:
    final pTopLeft = Offset(0.28 * w, 0.18 * h);
    final pTopRight = Offset(0.72 * w, 0.18 * h);
    final pGirdleLeft = Offset(0.06 * w, 0.40 * h);
    final pGirdleRight = Offset(0.94 * w, 0.40 * h);
    final pCulet = Offset(0.50 * w, 0.92 * h);

    final pCrownMidLeft = Offset(0.26 * w, 0.40 * h);
    final pCrownMidRight = Offset(0.74 * w, 0.40 * h);
    final pTableMidLeft = Offset(0.38 * w, 0.18 * h);
    final pTableMidRight = Offset(0.62 * w, 0.18 * h);
    final pCenter = Offset(0.50 * w, 0.40 * h);

    void drawFacet(List<Offset> points, Gradient gradient) {
      final path = Path()..addPolygon(points, true);
      final paint = Paint()
        ..shader = gradient.createShader(path.getBounds())
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);

      // Specular Highlight Edge Lines
      final edgePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85;
      canvas.drawPath(path, edgePaint);
    }

    // --- CROWN TABLE (TOP FLAT FACET) ---
    drawFacet([
      pTopLeft,
      pTopRight,
      pTableMidRight,
      pTableMidLeft
    ], const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFF80EEFF), Color(0xFF00BFFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ));

    // --- CROWN KITE FACET (TOP CENTER) ---
    drawFacet([
      pTopLeft,
      pTopRight,
      pCenter
    ], const LinearGradient(
      colors: [Color(0xFFE0FFFF), Color(0xFFB0E0E6), Color(0xFF4682B4)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ));

    // --- CROWN UPPER LEFT FACET ---
    drawFacet([
      pTopLeft,
      pGirdleLeft,
      pCrownMidLeft,
      pCenter
    ], const LinearGradient(
      colors: [Color(0xFFF0E6FF), Color(0xFFBA55D3), Color(0xFF8A2BE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ));

    // --- CROWN UPPER RIGHT FACET ---
    drawFacet([
      pTopRight,
      pGirdleRight,
      pCrownMidRight,
      pCenter
    ], const LinearGradient(
      colors: [Color(0xFFE0FFFF), Color(0xFF00CED1), Color(0xFF1E90FF)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ));

    // --- CROWN FAR LEFT WING ---
    drawFacet([
      pTopLeft,
      pGirdleLeft,
      pCrownMidLeft
    ], const LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFDA70D6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ));

    // --- CROWN FAR RIGHT WING ---
    drawFacet([
      pTopRight,
      pGirdleRight,
      pCrownMidRight
    ], const LinearGradient(
      colors: [Color(0xFFE0FFFF), Color(0xFF00BFFF), Color(0xFF9400D3)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ));

    // --- PAVILION MAIN CENTER TRIANGLE (BOTTOM CENTER) ---
    drawFacet([
      pGirdleLeft,
      pGirdleRight,
      pCulet
    ], const LinearGradient(
      colors: [
        Color(0xFF00F0FF), // Vibrant Electric Cyan
        Color(0xFF7B2CBF), // Deep Royal Purple
        Color(0xFF3A0CA3), // Deep Indigo
        Color(0xFF03045E), // Sapphire Base
      ],
      stops: [0.0, 0.35, 0.70, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ));

    // --- PAVILION LEFT FACET SLICE ---
    drawFacet([
      pGirdleLeft,
      Offset(0.35 * w, 0.40 * h),
      pCulet
    ], const LinearGradient(
      colors: [Color(0xFFFF007A), Color(0xFF7B2CBF), Color(0xFF1E90FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ));

    // --- PAVILION RIGHT FACET SLICE ---
    drawFacet([
      pGirdleRight,
      Offset(0.65 * w, 0.40 * h),
      pCulet
    ], const LinearGradient(
      colors: [Color(0xFF00FFFF), Color(0xFF3B82F6), Color(0xFF6366F1)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ));

    // --- PAVILION CENTER RIB (SHARP SPECTRUM REFLECTION) ---
    drawFacet([
      pCenter,
      Offset(0.50 * w, 0.65 * h),
      pCulet
    ], const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFA5F3FC), Color(0xFF0284C7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
