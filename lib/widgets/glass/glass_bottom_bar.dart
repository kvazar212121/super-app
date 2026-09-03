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
    final fill = GlassTokens.glassFill(context);
    final border = GlassTokens.glassBorder(context);
    final highlight = GlassTokens.glassHighlight(context);

    // Tepada shaffof "havo" chizig'i: markaziy orb shu yerga chiqib turadi va
    // panel tepa chizig'i uning ustidan yumaloq qayrilib o'tadi.
    // Kichikroq strip = chiziq pastroqda, ikonlarga yaqinroq.
    const topStrip = 16.0;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) Shishasimon panel — faqat pastki qism (topStrip'dan pastda).
          Positioned.fill(
            top: topStrip,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassTokens.glassBlur,
                  sigmaY: GlassTokens.glassBlur,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        fill,
                        Color.lerp(fill, Colors.transparent, 0.12) ?? fill,
                      ],
                    ),
                    boxShadow: GlassTokens.glassShadow(context),
                  ),
                ),
              ),
            ),
          ),
          // 2) Panel tepa chizig'i — markaziy orb ustidan yumaloq qayrilib
          //    o'tadi (mashina qanoti g'ildirak ustidan o'tgandek).
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NotchedTopBorderPainter(
                  color: border,
                  highlight: highlight,
                  itemCount: items.length,
                  centerIndex: centerIndex,
                  baseY: topStrip,
                  // Orb radiusi (46/2) + havo. Egri ikki chetga keng tortiladi.
                  notchRadius: 30,
                ),
              ),
            ),
          ),
          // 3) Tugmalar qatori — orbdan tashqarilar panel ichida; markaziy
          //    orb esa yuqoriga chiqib turadi.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 4,
                right: 4,
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

    // 1) Asosiy chiziq (oltin/border rangi).
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 2) Chiziq ostidagi nozik yorug'lik (highlight) — shishasimon his.
    final glowPaint = Paint()
      ..color = highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.save();
    canvas.translate(0, 1.0);
    canvas.drawPath(path, glowPaint);
    canvas.restore();
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
    // Tanlangan element: dark rejimda OLTIN, light rejimda eski ko'k.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? LuxTokens.goldSoft : const Color(0xFF3B82F6);
    // Dark (premium) rejimda tanlanganlik FAQAT rang bilan ko'rsatiladi —
    // orqa fon kapsulasi yo'q. Qora fonda rangli plashka og'ir ko'rinadi va
    // panelning tekis, tinch ko'rinishini buzadi.
    final activeColor = isDark
        ? Colors.transparent
        : accent.withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.only(top: 6, bottom: 0),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected
                    ? accent
                    : const Color(0xFF0A0A0A),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: LuxTokens.display,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? accent
                        : const Color(0xFF0A0A0A),
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
