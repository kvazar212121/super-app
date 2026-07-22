import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/massage_hijoma.dart';
import '../../models/master_worker.dart';
import '../../models/service_hub_kind.dart';
import '../../screens/provider_profile_screen.dart';
import '../../l10n/locale_controller.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import '../glass/glass_surface.dart';
import 'hub_filter_chips.dart';
import 'venue_hub_card.dart';

class MassageCenterHubSection extends StatefulWidget {
  final List<MassageHijoma> centers;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const MassageCenterHubSection({
    super.key,
    required this.centers,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  State<MassageCenterHubSection> createState() =>
      _MassageCenterHubSectionState();
}

class _MassageCenterHubSectionState extends State<MassageCenterHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<MassageHijoma> get _filtered {
    var list = List<MassageHijoma>.from(widget.centers);
    switch (_filter) {
      case HubListFilter.nearest:
        list.sort(
          (a, b) =>
              distanceKm(
                kDefaultUserLat,
                kDefaultUserLng,
                a.latitude,
                a.longitude,
              ).compareTo(
                distanceKm(
                  kDefaultUserLat,
                  kDefaultUserLng,
                  b.latitude,
                  b.longitude,
                ),
              ),
        );
      case HubListFilter.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case HubListFilter.openNow:
        // Mocking open status for now
        break;
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
                  'Yaqin markazlar',
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
                  'Bu filtr bo\'yicha markaz topilmadi',
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
                final center = items[i];
                return VenueHubCard.fromMassageCenter(
                  center,
                  accent: widget.accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: _convertToMaster(center),
                        category: ServiceHubKind.massajHijoma,
                      ),
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

class MobileMassageHubSection extends StatelessWidget {
  final List<MassageHijoma> specialists;
  final Color accentColor;

  const MobileMassageHubSection({
    super.key,
    required this.specialists,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (specialists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Uyga boradigan mutaxassislar'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${specialists.length} ta',
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
            itemCount: specialists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = specialists[i];
              final minPrice = s.prices.values.isEmpty
                  ? 50000.0
                  : s.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: s.name,
                subtitle: s.serviceTypes.isNotEmpty
                    ? s.serviceTypes.first.label
                    : 'Mutaxassis',
                rating: s.rating,
                reviewCount: s.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.heartPulse,
                accent: accentColor,
                rawJson: s.rawJson,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, s.latitude, s.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: _convertToMaster(s),
                      category: ServiceHubKind.massajHijoma,
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

// Yordamchi metod ProviderProfileScreen g'am Master modeli kutgani uchun MassageHijoma dan o'girishga
Master _convertToMaster(MassageHijoma mh) {
  return Master(
    id: mh.id,
    providerId: mh.providerId,
    name: mh.name,
    specialty: mh.serviceTypes.isNotEmpty
        ? mh.serviceTypes.first.label
        : 'Mutaxassis',
    rating: mh.rating,
    reviewCount: mh.reviewCount,
    phoneNumber: mh.phoneNumber,
    services: mh.serviceTypes.map((t) => t.label).toList(),
    prices: mh.prices.map((k, v) => MapEntry(k, v)),
    latitude: mh.latitude,
    longitude: mh.longitude,
    serviceArea: mh.serviceArea,
    teamSize: mh.massageRole == 'salon' ? 3 : null,
    rawJson: mh.rawJson,
  );
}
