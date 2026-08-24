/// Chatdagi va qidiruvdagi BITTA e'lon kartasi.
///
/// Foydalanuvchi so'ragan ko'rinish: rasm, nom, narx, holat, masofa.
/// Narx DOIM so'mda (backend `price_uzs` beradi) — chalg'imasin.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';
import '../../models/marketplace/listing.dart';
import '../../theme/glass_tokens.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: GlassTokens.glassFill(context),
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
            border: Border.all(color: GlassTokens.glassBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(GlassTokens.radiusSm),
                  ),
                  child: _photo(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.priceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _pastki,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Ideal · 2.0 km" — masofa bo'lmasa faqat holat ko'rinadi.
  String get _pastki {
    final masofa = listing.distanceText;
    if (masofa.isEmpty) return listing.conditionText;
    return '${listing.conditionText} · $masofa';
  }

  Widget _photo(BuildContext context) {
    final url = listing.mainPhoto;
    if (url == null || url.isEmpty) return _fallback(context);
    // Tezlik uchun: RAM keshiga karta o'lchamida yuklaymiz (600px kifoya
    // grid karta uchun). Original 2000+px rasmlar tejaladi.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return CachedNetworkImage(
      imageUrl: AppConfig.formatImageUrl(url),
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: (600 * dpr).round(),
      maxWidthDiskCache: 800,
      fadeInDuration: const Duration(milliseconds: 120),
      errorWidget: (_, _, _) => _fallback(context),
      placeholder: (_, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) => ColoredBox(
    color: Colors.blue.withValues(alpha: 0.12),
    child: const Center(
      child: Icon(LucideIcons.image, color: Colors.blue, size: 26),
    ),
  );
}
