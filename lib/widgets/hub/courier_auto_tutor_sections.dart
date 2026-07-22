import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/courier_service.dart';
import '../../models/auto_mobile_service.dart';
import '../../models/auto_workshop.dart';
import '../../models/tutor_service.dart';
import '../../screens/courier_dispatch_screen.dart';
import '../../screens/auto_mobile_dispatch_screen.dart';
import '../../screens/auto_workshop_dispatch_screen.dart';
import '../../screens/tutor_profile_screen.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import 'hub_filter_chips.dart';
import 'venue_hub_card.dart';

class CourierHubSection extends StatelessWidget {
  final List<CourierService> couriers;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const CourierHubSection({
    super.key,
    required this.couriers,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (couriers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin kuryerlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${couriers.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 10),
                HubFilterButton(
                  accent: accentColor,
                  showSort: false,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: couriers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = couriers[i];
              final minPrice = c.prices.values.isEmpty
                  ? 25000.0
                  : c.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: c.name,
                subtitle: c.serviceArea ?? c.vehicleType.label,
                rating: c.rating,
                reviewCount: c.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.bike,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, c.latitude, c.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourierDispatchScreen(service: c),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AutoHelpHubSection extends StatelessWidget {
  final List<AutoMobileService> units;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const AutoHelpHubSection({
    super.key,
    required this.units,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mobil avto-yordam',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${units.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 10),
                HubFilterButton(
                  accent: accentColor,
                  showSort: false,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: units.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final u = units[i];
              final minPrice = u.prices.values.isEmpty
                  ? 80000.0
                  : u.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: u.name,
                subtitle: u.serviceArea ?? u.vehicleType.label,
                rating: u.rating,
                reviewCount: u.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: u.vehicleType.icon,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, u.latitude, u.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutoMobileDispatchScreen(service: u),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class AutoWorkshopHubSection extends StatelessWidget {
  final List<AutoWorkshop> workshops;
  final Color accentColor;

  const AutoWorkshopHubSection({
    super.key,
    required this.workshops,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (workshops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin ustaxonalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${workshops.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: workshops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final w = workshops[i];
              final minPrice = w.prices.values.isEmpty
                  ? 80000.0
                  : w.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: w.name,
                subtitle: w.specializations.take(2).join(', '),
                rating: w.rating,
                reviewCount: w.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.home,
                accent: const Color(0xFF334155),
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, w.latitude, w.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutoWorkshopDispatchScreen(workshop: w),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Repetitorlar — onlayn, uyga, markazda.
class TutorHubSection extends StatelessWidget {
  const TutorHubSection({
    super.key,
    required this.tutors,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  final List<TutorService> tutors;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    if (tutors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Repetitorlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              if (categories.isNotEmpty)
                HubFilterButton(
                  accent: accentColor,
                  showSort: false,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                ),
            ],
          ),
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tutors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final t = tutors[i];
              final minPrice = t.prices.values.isEmpty
                  ? 100000.0
                  : t.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: t.name,
                subtitle: t.subjectsLabel,
                rating: t.rating,
                reviewCount: t.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.bookOpen,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, t.latitude, t.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TutorProfileScreen(tutor: t),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
