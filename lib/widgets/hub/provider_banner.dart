import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_config.dart';

/// Provayder banneri — ro'yxat qatorida va xarita preview kartasida
/// ishlatiladigan YAGONA komponent.
///
/// Xulq-atvor qoidalari:
///  • Tavsiya etilgan rasm nisbati — **1.2 : 1** (eni : bo'yi).
///  • Provayder boshqa nisbatda (masalan tik/vertikal) rasm yuklasa ham
///    ko'rinish buzilmaydi: rasm **markazidan** qirqib olinadi
///    (`BoxFit.cover` + `Alignment.center`), cho'zilmaydi.
///  • Banner O'ZI balandlik talab qilmaydi — u joylashtirilgan maydonni
///    to'ldiradi. Shu sabab tik rasm qatorni cho'zib yubormaydi.
///  • O'ng chekkasi fon rangiga ozgina singiydi, matn bilan orasida
///    qattiq chegara qolmaydi.
class ProviderBanner extends StatelessWidget {
  /// Rasm manzili (null yoki bo'sh bo'lsa ikonka + rang ko'rsatiladi).
  final String? coverUrl;

  /// Rasm bo'lmaganda ko'rsatiladigan xizmat ikonkasi.
  final IconData icon;

  /// Xizmat rangi (fallback fon va ikonka rangi).
  final Color accent;

  /// Karta fon rangi — banner o'ng chekkasi shunga singiydi.
  final Color surface;

  /// Fallback ikonka o'lchami.
  final double iconSize;

  /// Tavsiya etiladigan nisbat: eni / bo'yi.
  static const double recommendedAspectRatio = 1.2;

  const ProviderBanner({
    super.key,
    required this.coverUrl,
    required this.icon,
    required this.accent,
    required this.surface,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    final url = coverUrl?.trim();
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: AppConfig.formatImageUrl(url),
              // Qanday nisbatda yuklangan bo'lsa ham — markazidan qirqiladi.
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorWidget: (_, _, _) => _fallback(),
              placeholder: (_, _) => _fallback(),
            )
          else
            _fallback(),
          // O'ngga qarab fon rangiga singish (ozgina, oxirgi ~45%).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  surface.withValues(alpha: 0),
                  surface.withValues(alpha: 0),
                  surface.withValues(alpha: 0.75),
                  surface,
                ],
                stops: const [0, 0.55, 0.85, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => ColoredBox(
        color: accent.withValues(alpha: 0.16),
        child: Center(child: Icon(icon, color: accent, size: iconSize)),
      );
}
