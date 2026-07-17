import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// iOS Control Center uslubidagi shaffof/yozilgan panel.
/// [enableBlur] — standart holatda O'CHIQ (tezlik uchun). Faqat asosiy
/// ekran chrome'ida (masalan pastki panel) blur ishlatiladi.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? tint;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showShadow;
  final bool enableBlur;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = GlassTokens.radiusMd,
    this.blur = GlassTokens.glassBlur,
    this.opacity = GlassTokens.glassOpacity,
    this.tint,
    this.onTap,
    this.showBorder = true,
    this.showShadow = true,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = tint ?? GlassTokens.glassFill(context, opacity: opacity);
    final border = GlassTokens.glassBorder(context);
    final highlight = GlassTokens.glassHighlight(context);

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: fill,
        border: showBorder ? Border.all(color: border, width: 1.2) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: borderRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                color: highlight,
              ),
            ),
          ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );

    // Soya ClipRRect'DAN TASHQARIDA — aks holda kesilib ko'rinmay qoladi.
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow ? GlassTokens.glassShadow(context) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: panel,
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white,
          highlightColor: Colors.white,
          child: content,
        ),
      );
    }

    return content;
  }
}
