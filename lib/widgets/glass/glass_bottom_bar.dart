import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/glass_tokens.dart';
import '../../theme/lux_tokens.dart';

class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  /// Maxsus MARKAZIY orb (AiHub) indeksi — harakatlanuvchi, ko'zga tashlanadigan
  /// dumaloq tugma. -1 bo'lsa hech qaysi element maxsus emas.
  final int centerIndex;

  /// Orbni BOSIB TURGANDA (long-press) — ovoz rejimi (AiHub'ni startVoice bilan
  /// ochish). Bir marta bosish esa oddiy onTap (chat).
  final VoidCallback? onCenterLongPress;

  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerIndex = -1,
    this.onCenterLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const topStrip = 16.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A227).withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1) Oq shishasimon panel — markaziy orb egri qayrilishi bilan birga to'liq bo'yaladi.
              Positioned.fill(
                child: ClipPath(
                  clipper: _NotchedBarClipper(
                    itemCount: items.length,
                    centerIndex: centerIndex,
                    baseY: topStrip,
                    notchRadius: 30,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // 2) Panel tepa chizig'i — markaziy orb ustidan yumaloq qayrilib o'tadi.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _NotchedTopBorderPainter(
                      color: const Color(0xFFC9A227),
                      highlight: const Color(0xFFFFF7C2),
                      itemCount: items.length,
                      centerIndex: centerIndex,
                      baseY: topStrip,
                      notchRadius: 30,
                    ),
                  ),
                ),
              ),
              // 3) Tugmalar qatori
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: topStrip,
                    bottom: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final selected = i == currentIndex;
                      if (i == centerIndex) {
                        return Expanded(
                          child: _AiOrb(
                            item: item,
                            selected: selected,
                            onTap: () => onTap(i),
                            onLongPress: onCenterLongPress,
                          ),
                        );
                      }
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastki menyu tepa chizig'ini chizadi va markaziy orb ustidan YUMALOQ
/// qayradi (g'ildirak ustidan o'tgan qanotdek). Chiziq chapdan o'ngga
/// boradi, orb yaqinida yuqoriga arc bilan ko'tarilib, ustidan aylanib
/// o'tadi va davom etadi.
class _NotchedTopBorderPainter extends CustomPainter {
  final Color color;
  final Color highlight;
  final int itemCount;
  final int centerIndex;
  final double baseY;
  final double notchRadius;

  const _NotchedTopBorderPainter({
    required this.color,
    required this.highlight,
    required this.itemCount,
    required this.centerIndex,
    required this.baseY,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Markaziy orbning gorizontal markazi (teng bo'lingan kataklar).
    final slot = size.width / itemCount;
    final cx = slot * (centerIndex + 0.5);
    final topY = baseY; // panelning tekis tepa chizig'i
    final lift = baseY; // orb ustida shu qadar yuqoriga (0 gacha) ko'tariladi

    // Qayrilish yarim kengligi: orb radiusidan ANCHA keng — ikki chet
    // yon tomonlarga cho'zilib, egri juda silliq (yumshoq) bo'ladi.
    final half = notchRadius + 30;
    final startX = cx - half;
    final endX = cx + half;

    // Chiziq chapdan o'ngga; markazda YUQORIGA (kichik Y) gumbaz bo'lib
    // orb ustidan aylanib o'tadi (mashina qanoti g'ildirak ustidan).
    final path = Path()..moveTo(0, topY);
    path.lineTo(startX, topY);
    // Chap yon: pastdan tepaga uzun, silliq ko'tarilish (chetga tortilgan).
    path.cubicTo(
      cx - half * 0.62, topY,
      cx - notchRadius * 0.72, topY - lift,
      cx, topY - lift,
    );
    // O'ng yon: tepadan pastga uzun, silliq tushish (simmetrik).
    path.cubicTo(
      cx + notchRadius * 0.72, topY - lift,
      cx + half * 0.62, topY,
      endX, topY,
    );
    path.lineTo(size.width, topY);

    // Haqiqiy 24K Oltin Metallik Gradiyenti (tovlanuvchi va yarqiraydigan oltin nuri)
    final goldShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFBF953F), // metallik oltin
        Color(0xFFFCF6BA), // yarqiragan oq-oltin nuri
        Color(0xFFB38728), // to'q sof oltin
        Color(0xFFFBF5B7), // porloq nurlar
        Color(0xFFAA771C), // 24K oltin soya
        Color(0xFFE5C158), // yarqiroq oltin
      ],
      stops: [0.0, 0.25, 0.5, 0.72, 0.88, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 1) Oltin yog'du porlashi (Golden Aura Glow Effect)
    final glowPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, glowPaint);

    // 2) Asosiy 24K Qalin Oltin metallik chiziq (2.5px qalinlik)
    final linePaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 3) Markaziy nozik nurlanish yadrosi (Specular highlight core)
    final corePaint = Paint()
      ..color = const Color(0xFFFFFDF0).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(_NotchedTopBorderPainter old) =>
      old.color != color ||
      old.highlight != highlight ||
      old.itemCount != itemCount ||
      old.centerIndex != centerIndex ||
      old.baseY != baseY ||
      old.notchRadius != notchRadius;
}

class _NotchedBarClipper extends CustomClipper<Path> {
  final int itemCount;
  final int centerIndex;
  final double baseY;
  final double notchRadius;

  const _NotchedBarClipper({
    required this.itemCount,
    required this.centerIndex,
    required this.baseY,
    required this.notchRadius,
  });

  @override
  Path getClip(Size size) {
    final slot = size.width / itemCount;
    final cx = slot * (centerIndex + 0.5);
    final topY = baseY;
    final lift = baseY;
    final half = notchRadius + 30;
    final startX = cx - half;
    final endX = cx + half;

    final path = Path();
    path.moveTo(0, topY);
    path.lineTo(startX, topY);
    path.cubicTo(
      cx - half * 0.62, topY,
      cx - notchRadius * 0.72, topY - lift,
      cx, topY - lift,
    );
    path.cubicTo(
      cx + notchRadius * 0.72, topY - lift,
      cx + half * 0.62, topY,
      endX, topY,
    );
    path.lineTo(size.width, topY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_NotchedBarClipper oldClipper) {
    return oldClipper.itemCount != itemCount ||
        oldClipper.centerIndex != centerIndex ||
        oldClipper.baseY != baseY ||
        oldClipper.notchRadius != notchRadius;
  }
}

class GlassNavItem {
  final IconData icon;
  final String label;

  const GlassNavItem({required this.icon, required this.label});
}

/// AiHub markaziy orbi — jonli (breathing) gradient dumaloq tugma.
/// 1-bosqich: bir marta bosilganda AiHub chat ochiladi (onTap).
/// Keyingi bosqichda bosib-turib ovoz rejimi qo'shiladi.
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
    // Uzluksiz "nafas olish" animatsiyasi (scale + porlash).
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
    const c1 = Color(0xFFC9A227); // oltin
    const c2 = Color(0xFFE3C766); // ochiq oltin — porlash
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? LuxTokens.goldSoft : const Color(0xFF3B82F6);

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
            // Orbni biroz yuqoriga suramiz — u panel tepa chizig'idan chiqib,
            // chiziq uning ustidan qayrilib o'tadi (g'ildirak ustidagi qanot).
            Transform.translate(
              offset: const Offset(0, -6),
              child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value; // 0..1
                return Transform.scale(
                  scale: 1.0 + 0.07 * t,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Orbning o'z ranglariga mos ikki qatlamli porlash
                      // (indigo + cyan) — jonli "nafas" bilan pulslaydi.
                      boxShadow: [
                        BoxShadow(
                          color: c1.withValues(alpha: 0.32 + 0.30 * t),
                          blurRadius: 10 + 10 * t,
                          spreadRadius: 0.5 + 1.5 * t,
                        ),
                        BoxShadow(
                          color: c2.withValues(alpha: 0.16 + 0.22 * t),
                          blurRadius: 14 + 12 * t,
                          spreadRadius: 0.0 + 1.0 * t,
                        ),
                      ],
                    ),
                    // Iridescent sphere video (animatsiyali WebP, to'liq loop —
                    // barcha kadrlar) — doira shaklida kesilgan.
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/ai_orb.webp',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                );
              },
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.item.label,
                style: TextStyle(
                  fontFamily: LuxTokens.display,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.selected
                      ? accent
                      : const Color(0xFF0A0A0A),
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
    const inactiveColor = Color(0xFF94A3B8);

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
                item.icon,
                size: 22,
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
