import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';
import '../theme/lux_tokens.dart';

/// HubServis brend logotipi va nomi — splash, login va boshqa joylarda.
class HubServisBrand extends StatelessWidget {
  final double logoSize;
  final double titleSize;
  final bool showTagline;
  final bool compact;

  const HubServisBrand({
    super.key,
    this.logoSize = 100,
    this.titleSize = 34,
    this.showTagline = true,
    this.compact = false,
  });

  static const _primary = Color(0xFFC9A227);
  static const _accent = Color(0xFFE3C766);
  static const _violet = Color(0xFFE3C766);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = logoSize * 0.32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primary.withValues(alpha: isDark ? 0.35 : 0.18),
                    _violet.withValues(alpha: isDark ? 0.25 : 0.12),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: isDark ? 0.35 : 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_primary, _accent, _violet],
                  ).createShader(bounds),
                  child: Text(
                    '◆',
                    style: TextStyle(
                      fontSize: logoSize * 0.42,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 14 : 24),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [Colors.white, _accent, _violet]
                : [const Color(0xFF1E1B4B), _primary, _violet],
          ).createShader(bounds),
          child: Text(
            'HubServis',
            style: TextStyle(
              fontFamily: LuxTokens.body,
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: Colors.white,
              height: 1.05,
            ),
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: compact ? 4 : 8),
          Text(
            'Barcha xizmatlar bir joyda',
            style: TextStyle(
              fontFamily: LuxTokens.body,
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: GlassTokens.secondaryText(context),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );
  }
}
