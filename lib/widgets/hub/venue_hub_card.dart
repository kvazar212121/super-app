import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_config.dart';

import '../../models/barber_shop.dart';
import '../../models/beauty_salon.dart';
import '../../models/football_field.dart';
import '../../models/massage_hijoma.dart';
import '../../models/saved_place_model.dart';
import '../../providers/saved_places_provider.dart';
import '../../screens/football_field_booking_screen.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../glass/glass_surface.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Jismoniy joylar kartasi — sartarosh, salon, futbol maydoni va h.k.
class VenueHubCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String distanceLabel;
  final String priceLabel;
  final double rating;
  final int reviewCount;
  final int completedCount;
  final int cancelledCount;
  final bool isOpen;
  final IconData icon;
  final Color accent;
  final String? coverUrl;
  final VoidCallback onTap;

  /// Karta kengligi. Gorizontal ro'yxatда 168 (default). Grid katalogда
  /// null berilsa — grid katakчаsi kengligini oladi (double.infinity).
  final double? width;

  const VenueHubCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.distanceLabel,
    required this.priceLabel,
    required this.rating,
    required this.reviewCount,
    this.completedCount = 0,
    this.cancelledCount = 0,
    required this.isOpen,
    required this.icon,
    required this.accent,
    this.coverUrl,
    required this.onTap,
    this.width = 168,
  });

  factory VenueHubCard.fromBarberShop(
    BarberShop shop, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    return VenueHubCard(
      name: shop.name,
      subtitle: shop.address,
      distanceLabel: formatDistanceKm(shop.distanceKmFrom(userLat, userLng)),
      priceLabel: shop.priceRangeLabel(),
      rating: shop.rating,
      reviewCount: shop.reviewCount,
      completedCount: shop.rawJson?['completed_orders_count'] ?? 0,
      cancelledCount: shop.rawJson?['cancelled_orders_count'] ?? 0,
      isOpen: shop.isOpenNow(),
      icon: LucideIcons.scissors,
      accent: accent,
      coverUrl: AppConfig.resolveCoverImage(shop.rawJson),
      onTap: onTap,
    );
  }

  factory VenueHubCard.fromBeautySalon(
    BeautySalon salon, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    return VenueHubCard(
      name: salon.name,
      subtitle: salon.address,
      distanceLabel: formatDistanceKm(salon.distanceKmFrom(userLat, userLng)),
      priceLabel: salon.priceRangeLabel(),
      rating: salon.rating,
      reviewCount: salon.reviewCount,
      completedCount: salon.rawJson?['completed_orders_count'] ?? 0,
      cancelledCount: salon.rawJson?['cancelled_orders_count'] ?? 0,
      isOpen: salon.isOpenNow(),
      icon: LucideIcons.sparkles,
      accent: accent,
      coverUrl: AppConfig.resolveCoverImage(salon.rawJson),
      onTap: onTap,
    );
  }

  factory VenueHubCard.fromFootballField(
    FootballField field, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    return VenueHubCard(
      name: field.name,
      subtitle: '${field.sizeSurfaceLabel} · ${field.address}',
      distanceLabel: formatDistanceKm(field.distanceKmFrom(userLat, userLng)),
      priceLabel: field.priceLabel,
      rating: field.rating,
      reviewCount: field.reviewCount,
      completedCount: field.rawJson?['completed_orders_count'] ?? 0,
      cancelledCount: field.rawJson?['cancelled_orders_count'] ?? 0,
      isOpen: field.isOpenNow(),
      icon: LucideIcons.trophy,
      accent: accent,
      coverUrl: AppConfig.resolveCoverImage(field.rawJson),
      onTap: onTap,
    );
  }

  factory VenueHubCard.fromMassageCenter(
    MassageHijoma center, {
    required Color accent,
    required VoidCallback onTap,
    double userLat = kDefaultUserLat,
    double userLng = kDefaultUserLng,
  }) {
    final minPrice = center.prices.values.isEmpty
        ? 50000
        : center.prices.values.reduce((a, b) => a < b ? a : b);
    return VenueHubCard(
      name: center.name,
      subtitle: center.address,
      distanceLabel: formatDistanceKm(
        distanceKm(userLat, userLng, center.latitude, center.longitude),
      ),
      priceLabel: '${(minPrice / 1000).round()}k+',
      rating: center.rating,
      reviewCount: center.reviewCount,
      completedCount: center.rawJson?['completed_orders_count'] ?? 0,
      cancelledCount: center.rawJson?['cancelled_orders_count'] ?? 0,
      isOpen: true, // Mocking as open for now
      icon: LucideIcons.heartPulse,
      accent: accent,
      coverUrl: AppConfig.resolveCoverImage(center.rawJson),
      onTap: onTap,
    );
  }

  /// Umumiy (generik) karta — istalgan xizmat provayderi uchun. Barcha hub
  /// bo'limlari BIR XIL o'lcham/ko'rinishдаги karta ishlatishi uchun (usta,
  /// kuryer, repetitor, hamshira va h.k.). Cover rasm bo'lsa ko'rsatiladi,
  /// bo'lmasa ikonka+rang fon.
  factory VenueHubCard.generic({
    required String name,
    required String subtitle,
    required double rating,
    required int reviewCount,
    required String priceLabel,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    double? distanceKmValue,
    String? coverUrl,
    Map<String, dynamic>? rawJson,
    bool isOpen = true,
    double? width = 168,
  }) {
    return VenueHubCard(
      name: name,
      subtitle: subtitle,
      distanceLabel: distanceKmValue != null
          ? formatDistanceKm(distanceKmValue)
          : '',
      priceLabel: priceLabel,
      rating: rating,
      reviewCount: reviewCount,
      completedCount: rawJson?['completed_orders_count'] ?? 0,
      cancelledCount: rawJson?['cancelled_orders_count'] ?? 0,
      isOpen: isOpen,
      icon: icon,
      accent: accent,
      coverUrl: coverUrl ?? AppConfig.resolveCoverImage(rawJson),
      onTap: onTap,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: GlassTokens.glassBorder(context), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 88,
                    width: double.infinity,
                    color: accent,
                    child: (coverUrl != null && coverUrl!.isNotEmpty)
                        // Rasm bo'lsa ko'rsatamiz; xato (404) yoki yuklanayotganда
                        // rang + icon ko'rinadi (bo'sh ko'k qolmaydi).
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.formatImageUrl(coverUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 88,
                            errorWidget: (_, _, _) =>
                                Center(child: Icon(icon, color: Colors.white, size: 32)),
                            placeholder: (_, _) => Center(
                                child: Icon(icon, color: Colors.white54, size: 32)),
                          )
                        : Center(child: Icon(icon, color: Colors.white, size: 32)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        distanceLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$rating',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              ' ($reviewCount)',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        if (completedCount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 10,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$completedCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        if (cancelledCount > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cancel,
                                size: 10,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$cancelledCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            priceLabel,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}
/// Futbol maydoni preview — bron oldidan.
Future<void> showFieldPreviewSheet(
  BuildContext context, {
  required FootballField field,
  required Color accent,
}) {
  final coverUrl = field.rawJson?['metadata']?['cover_url'];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GlassSurface(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      borderRadius: GlassTokens.radiusXl,
      opacity: 0.95,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (coverUrl != null) ...[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GlassTokens.primaryText(ctx),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      field.address,
                      style: TextStyle(color: GlassTokens.secondaryText(ctx)),
                    ),
                  ],
                ),
              ),
              Consumer<SavedPlacesProvider>(
                builder: (context, savedPlaces, _) {
                  final isSaved = savedPlaces.isSaved(field.id);
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved
                          ? Colors.red
                          : GlassTokens.primaryText(context),
                    ),
                    onPressed: () {
                      final savedItem = SavedPlace(
                        id: field.id,
                        categoryKey: 'futbol',
                        name: field.name,
                        address: field.address,
                        rating: field.rating,
                        type: 'football_field',
                        rawJson:
                            field.rawJson ??
                            {
                              'id': field.id,
                              'name': field.name,
                              'phone': field.phoneNumber,
                              'rating': field.rating,
                              'review_count': field.reviewCount,
                              'lat': field.latitude,
                              'lng': field.longitude,
                              'address': field.address,
                              'metadata': {
                                'size': field.size.name,
                                'surface': field.surface.name,
                                'base_price_per_hour': field.basePricePerHour,
                                'has_lighting': field.hasLighting,
                                'has_parking': field.hasParking,
                                'has_showers': field.hasShowers,
                                'has_cafe': field.hasCafe,
                              },
                            },
                      );
                      savedPlaces.toggleSave(savedItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSaved
                                ? 'Sevimli ro\'yxatidan o\'chirildi'
                                : 'Sevimli ro\'yxatiga qo\'shildi',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(
                icon: field.surface.icon,
                label: field.surface.label,
                color: field.surface.color,
              ),
              _PreviewChip(
                icon: LucideIcons.users,
                label: field.size.shortLabel,
                color: accent,
              ),
              _PreviewChip(
                icon: LucideIcons.banknote,
                label: field.priceLabel,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FootballFieldBookingScreen(field: field),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Bron qilish',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label.tr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
