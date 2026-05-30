import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/glass_tokens.dart';

/// iOS Control Center uslubidagi shaffof/yozilgan panel.
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

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = GlassTokens.radiusMd,
    this.blur = GlassTokens.blurLight,
    this.opacity = 0.55,
    this.tint,
    this.onTap,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final fill = tint ?? GlassTokens.glassFill(context, opacity: opacity);
    final border = GlassTokens.glassBorder(context);
    final highlight = GlassTokens.glassHighlight(context);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fill,
                Color.lerp(fill, Colors.transparent, 0.15) ?? fill,
              ],
            ),
            border: showBorder
                ? Border.all(color: border, width: 1.2)
                : null,
            boxShadow: showShadow ? GlassTokens.glassShadow(context) : null,
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
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [highlight, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ],
          ),
        ),
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
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
