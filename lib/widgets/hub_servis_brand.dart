import 'package:flutter/material.dart';
import '../theme/lux_tokens.dart';

/// HubServis brend logotipi ("HS" 3D Oltin Monogram) va nomi — kirishda va login ekranida.
class HubServisBrand extends StatefulWidget {
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

  @override
  State<HubServisBrand> createState() => _HubServisBrandState();
}

class _HubServisBrandState extends State<HubServisBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.logoSize * 0.32;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. "HS" REAL 3D OLTIN LOGO NISHONI (JONLI YALTIRASH BILAN)
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final t = _shimmerController.value;
            return Container(
              width: widget.logoSize,
              height: widget.logoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment(-1.5 + (t * 3.0), -1.0),
                  end: Alignment(-0.5 + (t * 3.0), 1.0),
                  colors: const [
                    Color(0xFFFFFBEB),
                    Color(0xFFFDE68A),
                    Color(0xFFB8921F),
                    Color(0xFFFFFBEB),
                  ],
                  stops: const [0.0, 0.45, 0.55, 1.0],
                ),
                border: Border.all(
                  color: LuxTokens.gold,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LuxTokens.gold.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: widget.logoSize * 0.76,
                  height: widget.logoSize * 0.76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF140D02),
                    borderRadius: BorderRadius.circular(radius * 0.75),
                    border: Border.all(
                      color: LuxTokens.gold.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          Color(0xFFFFFBEB),
                          Color(0xFFFDE68A),
                          Color(0xFFD9B036),
                          Color(0xFF8A5D0B),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'HS',
                        style: TextStyle(
                          fontFamily: LuxTokens.display,
                          fontSize: widget.logoSize * 0.42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: widget.compact ? 14 : 22),

        // 2. "HubServis" SARLAVHASI (PROFFESIONAL TO'Q NAVY)
        Text(
          'HubServis',
          style: TextStyle(
            fontFamily: LuxTokens.display,
            fontSize: widget.titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: const Color(0xFF102A43),
            height: 1.05,
          ),
        ),
        if (widget.showTagline) ...[
          SizedBox(height: widget.compact ? 4 : 8),
          Text(
            'Barcha xizmatlar bir joyda',
            style: TextStyle(
              fontFamily: LuxTokens.display,
              fontSize: widget.compact ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
