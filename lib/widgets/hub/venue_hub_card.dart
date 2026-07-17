import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../screens/barber_booking_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
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
                            errorWidget: (_, __, ___) =>
                                Center(child: Icon(icon, color: Colors.white, size: 32)),
                            placeholder: (_, __) => Center(
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

/// Joy haqida qisqa preview — bron qilishdan oldin.
Future<void> showVenuePreviewSheet(
  BuildContext context, {
  required BarberShop shop,
  required Color accent,
}) {
  final currency = NumberFormat.currency(
    locale: 'uz_UZ',
    symbol: 'so\'m',
    decimalDigits: 0,
  );
  final dist = formatDistanceKm(
    shop.distanceKmFrom(kDefaultUserLat, kDefaultUserLng),
  );

  final coverUrl = shop.rawJson?['metadata']?['cover_url'];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GlassSurface(
      margin: const EdgeInsets.all(16),
      borderRadius: GlassTokens.radiusXl,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(ctx).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GlassTokens.secondaryText(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: coverUrl != null ? null : accent,
                  image: coverUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            AppConfig.formatImageUrl(coverUrl),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: coverUrl != null
                    ? null
                    : Icon(LucideIcons.scissors, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.address,
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<SavedPlacesProvider>(
                builder: (context, savedPlaces, _) {
                  final isSaved = savedPlaces.isSaved(shop.id);
                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved
                          ? Colors.red
                          : GlassTokens.primaryText(context),
                    ),
                    onPressed: () {
                      final savedItem = SavedPlace(
                        id: shop.id,
                        categoryKey: 'sartarosh',
                        name: shop.name,
                        address: shop.address,
                        rating: shop.rating,
                        type: 'barber_shop',
                        rawJson:
                            shop.rawJson ??
                            {
                              'id': shop.id,
                              'name': shop.name,
                              'phone': shop.phoneNumber,
                              'rating': shop.rating,
                              'review_count': shop.reviewCount,
                              'lat': shop.latitude,
                              'lng': shop.longitude,
                              'address': shop.address,
                              'metadata': {
                                'barber_role':
                                    (shop
                                        .rawJson?['metadata']?['barber_role']) ??
                                    'shop',
                                'services': shop.services,
                                'prices': shop.prices,
                                'barbers': shop.barbers
                                    .map(
                                      (b) => {
                                        'name': b.name,
                                        'rating': b.rating,
                                      },
                                    )
                                    .toList(),
                                'owner_user_id': shop.ownerUserId,
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(
                icon: Icons.star_rounded,
                label: '${shop.rating} (${shop.reviewCount})',
                color: const Color(0xFFF59E0B),
              ),
              _PreviewChip(
                icon: LucideIcons.mapPin,
                label: dist,
                color: accent,
              ),
              _PreviewChip(
                icon: LucideIcons.clock,
                label: shop.isOpenNow() ? 'Hozir ochiq' : 'Yopiq',
                color: shop.isOpenNow()
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Xizmatlar va narxlar',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          ...shop.services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(color: GlassTokens.primaryText(context)),
                    ),
                  ),
                  Text(
                    currency.format(
                      shop.prices[s] ?? BarberShop.defaultPriceForService(s),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (shop.barbers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Ustalar: ${shop.barbers.map((b) => b.name).join(', ')}',
              style: TextStyle(
                fontSize: 13,
                color: GlassTokens.secondaryText(context),
              ),
            ),
          ],
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
                    builder: (_) => BarberBookingScreen(shop: shop),
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
