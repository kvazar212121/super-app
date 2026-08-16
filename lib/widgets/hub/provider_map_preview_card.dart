import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../screens/service_hub/service_catalog_screen.dart';
import '../../theme/glass_tokens.dart';
import 'provider_banner.dart';
import '../../utils/geo_utils.dart';

/// Xarita ekranida marker bosilganda TEPADA chiqadigan preview karta.
///
/// Ro'yxat qatori bilan BIR XIL ma'lumotni ko'rsatadi (banner, nom, reyting,
/// teglar, holat) va o'ng pastda "buyurtma berish >" tugmasi bo'ladi.
class ProviderMapPreviewCard extends StatelessWidget {
  final CatalogEntry entry;
  final Color accent;

  /// Marshrut masofasi (yoki to'g'ri chiziq masofasi), km.
  final double? distanceKmValue;

  /// Marshrut davomiyligi, daqiqa. null bo'lsa ko'rsatilmaydi.
  final int? durationMin;

  /// Marshrut hisoblanmoqda.
  final bool routing;

  final VoidCallback onClose;
  final VoidCallback onOrder;

  /// Banner kengligi — ro'yxat qatoridagiga yaqin.
  static const double _bannerWidth = 118;

  const ProviderMapPreviewCard({
    super.key,
    required this.entry,
    required this.accent,
    required this.onClose,
    required this.onOrder,
    this.distanceKmValue,
    this.durationMin,
    this.routing = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = GlassTokens.glassFill(context);
    final primary = GlassTokens.primaryText(context);
    final secondary = GlassTokens.secondaryText(context);
    final cover = entry.resolvedCoverUrl;

    return Material(
      color: surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Yuqori qism — banner (chapda) + ma'lumot (o'ngda), ro'yxatdagidek.
          // Balandlikni faqat MATN belgilaydi: provayder tik (vertikal) rasm
          // yuklasa ham karta cho'zilib ketmaydi.
          Container(
            constraints: const BoxConstraints(minHeight: 96),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _bannerWidth,
                  child: ProviderBanner(
                    coverUrl: cover,
                    icon: entry.icon,
                    accent: accent,
                    surface: surface,
                    iconSize: 28,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_bannerWidth + 4, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: primary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onClose,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child:
                                  Icon(LucideIcons.x, size: 16, color: secondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: secondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            entry.rating > 0
                                ? entry.rating.toStringAsFixed(1)
                                : '—',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          if (entry.reviewCount > 0)
                            Text(
                              ' (${entry.reviewCount})',
                              style: TextStyle(fontSize: 11, color: secondary),
                            ),
                          if (entry.priceLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                entry.priceLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 19,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            itemCount: entry.tags.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 5),
                            itemBuilder: (_, i) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.tags[i],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pastki qator — masofa/vaqt chiplari + "buyurtma berish >" tugmasi.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // Chiplar siqiluvchan: uzoq masofada (masalan "7989.2 km" +
                // "93 soat") ham "Buyurtma berish" tugmasini siqib chiqarmaydi.
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (routing)
                        Flexible(
                          child: _chip(
                            context,
                            icon: LucideIcons.route,
                            label: '…',
                          ),
                        )
                      else if (distanceKmValue != null)
                        Flexible(
                          child: _chip(
                            context,
                            icon: LucideIcons.route,
                            label: formatDistanceKm(distanceKmValue!),
                          ),
                        ),
                      if (durationMin != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _chip(
                            context,
                            icon: LucideIcons.clock,
                            label: formatDuration(durationMin!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: accent,
                  borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
                  child: InkWell(
                    onTap: onOrder,
                    borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buyurtma berish'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(LucideIcons.chevronRight,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
