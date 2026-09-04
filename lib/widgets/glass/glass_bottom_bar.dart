import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/lux_tokens.dart';

class GlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;
  final int centerIndex;
  final VoidCallback? onCenterLongPress;

  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerIndex = 2,
    this.onCenterLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const double barTopY = 16.0;
    const double dipDepth = 20.0;
    const double notchRadius = 26.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) Ambient Gold Glow behind the capsule
          Positioned(
            top: barTopY,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE89A3C).withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

          // 2) White Background with Concave Notch Clip
          Positioned.fill(
            child: ClipPath(
              clipper: _ConcaveNotchedBarClipper(
                itemCount: items.length,
                centerIndex: centerIndex,
                topY: barTopY,
                dipDepth: dipDepth,
                notchRadius: notchRadius,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ),

          // 3) Golden Border Line passing UNDER the orb
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConcaveTopBorderPainter(
                  itemCount: items.length,
                  centerIndex: centerIndex,
                  topY: barTopY,
                  dipDepth: dipDepth,
                  notchRadius: notchRadius,
                ),
              ),
            ),
          ),

          // 4) Left & Right Navigation Buttons
          Positioned(
            top: barTopY,
            left: 8,
            right: 8,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(items.length, (i) {
                if (i == centerIndex) {
                  return const Spacer();
                }
                final item = items[i];
                final selected = i == currentIndex;
                return Expanded(
                  child: _NavButton(
                    item: item,
                    selected: selected,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),

          // 5) Center Floating Orb (Sitting in concave notch, top half floating outside)
          Positioned(
            top: -2,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 64,
                child: _AiOrb(
                  item: items[centerIndex],
                  selected: currentIndex == centerIndex,
                  onTap: () => onTap(centerIndex),
                  onLongPress: onCenterLongPress,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Concave Clipper: bar top edge dips DOWNWARDS under the orb
class _ConcaveNotchedBarClipper extends CustomClipper<Path> {
  final int itemCount;
  final int centerIndex;
  final double topY;
  final double dipDepth;
  final double notchRadius;

  const _ConcaveNotchedBarClipper({
    required this.itemCount,
    required this.centerIndex,
    required this.topY,
    required this.dipDepth,
    required this.notchRadius,
  });

  @override
  Path getClip(Size size) {
    final slot = size.width / itemCount;
    final cx = slot * (centerIndex + 0.5);
    final half = notchRadius + 14;
    final startX = cx - half;
    final endX = cx + half;

    final path = Path();
    path.moveTo(0, topY + 12);
    // Top-left rounded corner
    path.quadraticBezierTo(0, topY, 16, topY);
    path.lineTo(startX, topY);

    // Smooth Concave dip going DOWNWARDS under the orb
    path.cubicTo(
      cx - half * 0.5, topY,
      cx - notchRadius * 0.6, topY + dipDepth,
      cx, topY + dipDepth,
    );
    path.cubicTo(
      cx + notchRadius * 0.6, topY + dipDepth,
      cx + half * 0.5, topY,
      endX, topY,
    );

    path.lineTo(size.width - 16, topY);
    // Top-right rounded corner
    path.quadraticBezierTo(size.width, topY, size.width, topY + 12);

    path.lineTo(size.width, size.height - 16);
    path.quadraticBezierTo(size.width, size.height, size.width - 16, size.height);
    path.lineTo(16, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 16);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ConcaveNotchedBarClipper oldClipper) {
    return oldClipper.itemCount != itemCount ||
        oldClipper.centerIndex != centerIndex ||
        oldClipper.topY != topY ||
        oldClipper.dipDepth != dipDepth ||
        oldClipper.notchRadius != notchRadius;
  }
}

/// Concave Golden Line Painter: draws line dipping DOWN under the orb
class _ConcaveTopBorderPainter extends CustomPainter {
  final int itemCount;
  final int centerIndex;
  final double topY;
  final double dipDepth;
  final double notchRadius;

  const _ConcaveTopBorderPainter({
    required this.itemCount,
    required this.centerIndex,
    required this.topY,
    required this.dipDepth,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / itemCount;
    final cx = slot * (centerIndex + 0.5);
    final half = notchRadius + 14;
    final startX = cx - half;
    final endX = cx + half;

    final path = Path();
    path.moveTo(16, topY);
    path.lineTo(startX, topY);

    path.cubicTo(
      cx - half * 0.5, topY,
      cx - notchRadius * 0.6, topY + dipDepth,
      cx, topY + dipDepth,
    );
    path.cubicTo(
      cx + notchRadius * 0.6, topY + dipDepth,
      cx + half * 0.5, topY,
      endX, topY,
    );
    path.lineTo(size.width - 16, topY);

    final goldShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFE5C158),
        Color(0xFFFCF6BA),
        Color(0xFFB38728),
        Color(0xFFFBF5B7),
        Color(0xFFE5C158),
      ],
      stops: [0.0, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Soft Golden Aura Glow
    final glowPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(path, glowPaint);

    // Golden stroke line
    final linePaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_ConcaveTopBorderPainter old) =>
      old.itemCount != itemCount ||
      old.centerIndex != centerIndex ||
      old.topY != topY ||
      old.dipDepth != dipDepth ||
      old.notchRadius != notchRadius;
}

/// AiHub Floating Orb Widget
class _AiOrb extends StatefulWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _AiOrb({
    required this.item,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<_AiOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const c1 = Color(0xFFC9A227);
    const c2 = Color(0xFFE3C766);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                return Transform.scale(
                  scale: 1.0 + 0.05 * t,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c1.withValues(alpha: 0.35 + 0.25 * t),
                          blurRadius: 10 + 8 * t,
                          spreadRadius: 1.0 + 1.0 * t,
                        ),
                        BoxShadow(
                          color: c2.withValues(alpha: 0.20 + 0.20 * t),
                          blurRadius: 16 + 10 * t,
                          spreadRadius: 0.5 + 1.0 * t,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/ai_orb.webp',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.item.label,
                style: const TextStyle(
                  fontFamily: LuxTokens.display,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC9A227);
    const inactiveColor = Color(0xFF9E988F);

    final displayIcon = selected
        ? (item.activeIcon ?? item.icon)
        : item.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                displayIcon,
                size: 24,
                color: selected ? goldColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              if (selected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: goldColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

