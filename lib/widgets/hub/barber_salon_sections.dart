import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/barber_shop.dart';
import '../../models/beauty_salon.dart';
import '../../models/master_worker.dart';
import '../../models/service_hub_kind.dart';
import '../../screens/salon_booking_screen.dart';
import '../../screens/barber_booking_screen.dart';
import '../../screens/provider_profile_screen.dart';
import '../../l10n/locale_controller.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../glass/glass_surface.dart';
import 'hub_filter_chips.dart';
import 'venue_hub_card.dart';

/// Sartarosh hub — filtr + kartalar (2-bosqich).
class BarberHubSection extends StatefulWidget {
  final List<BarberShop> shops;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const BarberHubSection({
    super.key,
    required this.shops,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  State<BarberHubSection> createState() => _BarberHubSectionState();
}

class _BarberHubSectionState extends State<BarberHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<BarberShop> get _filtered {
    var list = List<BarberShop>.from(widget.shops);
    switch (_filter) {
      case HubListFilter.nearest:
        list.sort(
          (a, b) => a
              .distanceKmFrom(kDefaultUserLat, kDefaultUserLng)
              .compareTo(b.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)),
        );
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        list = list.where((s) => s.isOpenNow()).toList();
      case HubListFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin sartaroshxonalar'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${items.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              const SizedBox(width: 10),
              HubFilterButton(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                accent: widget.accentColor,
                categories: widget.categories,
                selectedCategory: widget.selectedCategory,
                onCategorySelected: widget.onCategorySelected,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GlassSurface(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Bu filtr bo\'yicha sartaroshxona topilmadi',
                  style: TextStyle(color: const Color(0xFF64748B)),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 198,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final shop = items[i];
                return VenueHubCard.fromBarberShop(
                  shop,
                  accent: widget.accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarberBookingScreen(shop: shop),
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

/// Yaqin go'zallik salonlari — filtrlar bilan.
class SalonHubSection extends StatefulWidget {
  final List<BeautySalon> salons;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const SalonHubSection({
    super.key,
    required this.salons,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  State<SalonHubSection> createState() => _SalonHubSectionState();
}

class _SalonHubSectionState extends State<SalonHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<BeautySalon> get _filtered {
    var list = List<BeautySalon>.from(widget.salons);
    switch (_filter) {
      case HubListFilter.nearest:
        list.sort(
          (a, b) => a
              .distanceKmFrom(kDefaultUserLat, kDefaultUserLng)
              .compareTo(b.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)),
        );
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        list = list.where((s) => s.isOpenNow()).toList();
      case HubListFilter.all:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin salonlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${items.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              const SizedBox(width: 10),
              HubFilterButton(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                accent: widget.accentColor,
                categories: widget.categories,
                selectedCategory: widget.selectedCategory,
                onCategorySelected: widget.onCategorySelected,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GlassSurface(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Bu filtr bo\'yicha salon topilmadi',
                  style: TextStyle(color: const Color(0xFF64748B)),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 198,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final salon = items[i];
                return VenueHubCard.fromBeautySalon(
                  salon,
                  accent: widget.accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalonBookingScreen(salon: salon),
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

/// Uyga boradigan mobil kosmetologlar.
class MobileSalonHubSection extends StatelessWidget {
  final List<Master> stylists;
  final Color accentColor;

  const MobileSalonHubSection({
    super.key,
    required this.stylists,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (stylists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Uyga boradigan kosmetologlar'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${stylists.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stylists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = stylists[i];
              final minPrice = s.prices.values.isEmpty
                  ? 50000
                  : s.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 150,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: s,
                        category: ServiceHubKind.salon,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
                      border: Border.all(color: GlassTokens.glassBorder(context), width: 1),
                      boxShadow: GlassTokens.glassShadow(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accentColor,
                          child: Icon(
                            LucideIcons.sparkles,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          s.specialty,
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            const Spacer(),
                            if ((s.rawJson?['completed_orders_count'] ?? 0) >
                                0) ...[
                              const Icon(
                                Icons.check_circle,
                                size: 10,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${s.rawJson?['completed_orders_count']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if ((s.rawJson?['cancelled_orders_count'] ?? 0) >
                                0) ...[
                              const Icon(
                                Icons.cancel,
                                size: 10,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${s.rawJson?['cancelled_orders_count']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
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

/// Uyga boradigan mobil sartaroshlar.
class MobileBarberHubSection extends StatelessWidget {
  final List<Master> barbers;
  final Color accentColor;

  const MobileBarberHubSection({
    super.key,
    required this.barbers,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (barbers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Uyga boradigan sartaroshlar'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${barbers.length} ta',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: barbers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final b = barbers[i];
              return _MobileBarberCard(
                master: b,
                accent: accentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: b,
                      category: ServiceHubKind.sartarosh,
                    ),
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

class _MobileBarberCard extends StatelessWidget {
  final Master master;
  final Color accent;
  final VoidCallback onTap;

  const _MobileBarberCard({
    required this.master,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = master.prices.values.isEmpty
        ? 35000
        : master.prices.values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
            border: Border.all(color: GlassTokens.glassBorder(context), width: 1),
            boxShadow: GlassTokens.glassShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent,
                    child: Icon(
                      LucideIcons.scissors,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Uyga',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                master.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '${master.rating}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'dan ${NumberFormat('#,###').format(minPrice)} so\'m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  if ((master.rawJson?['completed_orders_count'] ?? 0) > 0) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 10,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${master.rawJson?['completed_orders_count']}',
                      style: const TextStyle(fontSize: 10, color: Colors.green),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if ((master.rawJson?['cancelled_orders_count'] ?? 0) > 0) ...[
                    const Icon(Icons.cancel, size: 10, color: Colors.red),
                    const SizedBox(width: 2),
                    Text(
                      '${master.rawJson?['cancelled_orders_count']}',
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
