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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(GlassTokens.radiusMd),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassTokens.glassBlur,
          sigmaY: GlassTokens.glassBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(GlassTokens.radiusMd),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fill,
                Color.lerp(fill, Colors.transparent, 0.12) ?? fill,
              ],
            ),
            border: Border.all(color: border, width: 1.2),
            boxShadow: GlassTokens.glassShadow(context),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: GlassTokens.radiusMd,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(GlassTokens.radiusMd),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [highlight, Colors.transparent],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    final inactive = GlassTokens.secondaryText(context);

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
                final t = _c.value; // 0..1
                return Transform.scale(
                  scale: 1.0 + 0.07 * t,
                  child: Container(
                    width: 42,
                    height: 42,
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
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.item.label,
                style: TextStyle(
                  fontFamily: isDark ? LuxTokens.body : null,
                  fontSize: 10,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.selected ? accent : inactive,
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
    final inactive = GlassTokens.secondaryText(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 22,
                color: selected ? accent : inactive,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: isDark ? LuxTokens.body : null,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? accent : inactive,
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
