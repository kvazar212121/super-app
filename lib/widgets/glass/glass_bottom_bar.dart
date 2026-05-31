import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';

class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final fill = GlassTokens.glassFill(context);
    final border = GlassTokens.glassBorder(context);
    final highlight = GlassTokens.glassHighlight(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.glassBlur,
            sigmaY: GlassTokens.glassBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
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
                  height: GlassTokens.radiusXl,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(GlassTokens.radiusXl),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [highlight, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (i) {
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
              ],
            ),
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
    const activeColor = Color(0xFF6366F1);
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
            color: selected
                ? activeColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 22,
                color: selected ? activeColor : inactive,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
