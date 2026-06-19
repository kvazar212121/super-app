import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/barber_shop.dart';
import '../../models/beauty_salon.dart';
import '../../models/football_field.dart';
import '../../screens/barber_booking_screen.dart';
import '../../screens/football_field_booking_screen.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../glass/glass_surface.dart';

/// Jismoniy joylar kartasi — sartarosh, salon, futbol maydoni va h.k.
class VenueHubCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String distanceLabel;
  final String priceLabel;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const VenueHubCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.distanceLabel,
    required this.priceLabel,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.icon,
    required this.accent,
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
      isOpen: shop.isOpenNow(),
      icon: LucideIcons.scissors,
      accent: accent,
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
      isOpen: salon.isOpenNow(),
      icon: LucideIcons.sparkles,
      accent: accent,
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
      isOpen: field.isOpenNow(),
      icon: LucideIcons.trophy,
      accent: accent,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black26),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, accent],
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOpen ? 'Ochiq' : 'Yopiq',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const Spacer(),
                        Icon(LucideIcons.mapPin, size: 11, color: accent),
                        const SizedBox(width: 2),
                        Text(
                          distanceLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
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
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LucideIcons.scissors,
                  color: Colors.white,
                  size: 28,
                ),
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
            label,
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
