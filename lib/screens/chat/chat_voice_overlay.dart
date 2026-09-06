import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';

/// Ovoz yozish paytида ko'rinadigan modal overlay — jonli mic + ekvalayzer.
/// Foydalanuvchi gapirib bo'lgach (avto-tugash) o'zi yopiladi; tashqariga yoki
/// yashil tugmaga bosib ham yakunlash mumkin.
class VoiceListeningOverlay extends StatefulWidget {
  final ValueNotifier<double> soundLevel;
  final VoidCallback onStop;

  const VoiceListeningOverlay({
    required this.soundLevel,
    required this.onStop,
  });

  @override
  State<VoiceListeningOverlay> createState() => VoiceListeningOverlayState();
}

class VoiceListeningOverlayState extends State<VoiceListeningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onStop, // tashqariga bosish ham yakunlaydi
        child: Material(
          color: Colors.black.withValues(alpha: 0.62),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // kartaga bosish holatni o'zgartirmasin
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: LuxTokens.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF102A43).withValues(alpha: 0.18),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMic(),
                    const SizedBox(height: 26),
                    _buildBars(),
                    const SizedBox(height: 24),
                    Text(
                      'Tinglayapman...'.tr,
                      style: const TextStyle(
                        color: LuxTokens.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "So'zlang — tugagach o'zi yoziladi".tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LuxTokens.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    GestureDetector(
                      onTap: widget.onStop,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: Color(0xFF102A43),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33102A43),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMic() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.soundLevel,
      builder: (context, level, _) {
        final norm = (level.clamp(0.0, 10.0)) / 10.0;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Kengayuvchi halqalar
                  ...List.generate(2, (r) {
                    final p = (_c.value + r * 0.5) % 1.0;
                    return Container(
                      width: 80 + p * 62,
                      height: 80 + p * 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF102A43).withValues(alpha: (1 - p) * 0.35),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                  // Ovoz balandligiga qarab kattalashuvchi mic doirasi
                  Container(
                    width: 74 + norm * 16,
                    height: 74 + norm * 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF102A43),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33102A43),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.mic,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBars() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.soundLevel,
      builder: (context, level, _) {
        final norm = (level.clamp(0.0, 10.0)) / 10.0;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(21, (i) {
                final dist = (i - 10).abs() / 10.0; // 0 markaz .. 1 chet
                final center = 1 - dist; // markaz balandroq
                final phase = i * 0.55;
                final wave = 0.5 + 0.5 * math.sin(t * 2 * math.pi + phase);
                final h = 5.0 + (10 + norm * 42) * wave * (0.35 + 0.65 * center);
                return Container(
                  width: 4,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
