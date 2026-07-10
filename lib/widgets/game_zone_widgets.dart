import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_zone.dart';
import '../theme/glass_tokens.dart';
import 'package:super_app/l10n/locale_controller.dart';

// ===================================================================
//              GAME ZONE VISUAL WIDGET
// ===================================================================
class GameZoneVisualWidget extends StatelessWidget {
  final GameZone zone;
  final Color accent;

  const GameZoneVisualWidget({
    super.key,
    required this.zone,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(
            zone.gallery.isNotEmpty
                ? zone.gallery.first
                : 'https://via.placeholder.com/600x400',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          zone.zoneType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        zone.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//              GAME ZONE INFO CARD
// ===================================================================
class GameZoneInfoCard extends StatelessWidget {
  final GameZone zone;

  const GameZoneInfoCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTokens.glassBorder(context)),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  zone.address,
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.gamepad,
                label: zone.zoneType,
                color: Colors.deepPurpleAccent,
              ),
              _InfoChip(
                icon: Icons.meeting_room,
                label: zone.roomType,
                color: Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color: GlassTokens.secondaryText(context),
              ),
              const SizedBox(width: 6),
              Text(
                '${NumberFormat('#,###').format(zone.basePricePerHour)} soʻm / soat',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ===================================================================
//              GAME ZONE PRICE SUMMARY CARD
// ===================================================================
class GameZonePriceSummaryCard extends StatelessWidget {
  final GameZone zone;
  final List<GameZoneAmenity> amenities;
  final Set<int> selectedAmenities;
  final double totalPrice;
  final Color accent;

  const GameZonePriceSummaryCard({
    super.key,
    required this.zone,
    required this.amenities,
    required this.selectedAmenities,
    required this.totalPrice,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GlassTokens.glassShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Buyurtma xulosasi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PriceLine(
            label: 'Asosiy narxi (${zone.zoneType})',
            value:
                '${NumberFormat('#,###').format(zone.basePricePerHour)} soʻm',
          ),
          if (selectedAmenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1, color: Colors.white30),
            const SizedBox(height: 6),
            ...selectedAmenities.map((i) {
              final a = amenities[i];
              return _PriceLine(
                label: a.name,
                value: a.additionalPrice != null
                    ? '+${NumberFormat('#,###').format(a.additionalPrice)} soʻm'
                    : 'Tekin',
                isGreen: a.additionalPrice == null,
              );
            }),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white30),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jami (tahminiy):',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(totalPrice)} soʻm',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const _PriceLine({
    required this.label,
    required this.value,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
