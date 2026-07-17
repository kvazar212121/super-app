import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';
import 'package:super_app/l10n/locale_controller.dart';

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
    // Tanlangan element — tema asosiy KO'KI (binafsha emas), tugmalar bilan bir xil
    const accent = Color(0xFF3B82F6);
    final activeColor = accent.withValues(alpha: 0.12);
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
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
