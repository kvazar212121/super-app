import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/master_worker.dart';
import '../../models/nanny_service.dart';
import '../../models/service_hub_kind.dart';
import '../../screens/provider_profile_screen.dart';
import '../../screens/nanny_profile_screen.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import 'package:super_app/l10n/locale_controller.dart';
import 'hub_filter_chips.dart';
import 'venue_hub_card.dart';

/// Tozalash — yakka tozalovchi va jamoalar.
class CleaningHubSection extends StatelessWidget {
  final List<Master> cleaners;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const CleaningHubSection({
    super.key,
    required this.cleaners,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  List<Master> get _solo => cleaners.where((m) => m.isCleaningSolo).toList();
  List<Master> get _teams => cleaners.where((m) => m.isCleaningTeam).toList();

  @override
  Widget build(BuildContext context) {
    if (cleaners.isEmpty) return const SizedBox.shrink();

    // Yakka va jamoa tozalovchilar BITTA aralash ro'yxatда, eng yaqin bo'yicha
    // saralanadi. Karta ichидаги subtitle "Yakka tozalovchi" yoki "Jamoa · N
    // kishi" deb turini ko'rsatadi (ajratuvchi belgi).
    final all = [..._solo, ..._teams]
      ..sort((a, b) => distanceKm(kDefaultUserLat, kDefaultUserLng, a.latitude, a.longitude)
          .compareTo(distanceKm(kDefaultUserLat, kDefaultUserLng, b.latitude, b.longitude)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          context,
          'Tozalash xizmatlari',
          all.isEmpty ? cleaners : all,
          LucideIcons.sprayCan,
          withFilter: true,
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Master> items,
    IconData badgeIcon, {
    bool withFilter = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
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
              if (withFilter && categories.isNotEmpty) ...[
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
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final m = items[i];
              final minPrice = m.prices.values.isEmpty
                  ? 200000.0
                  : m.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: m.name,
                subtitle: m.isCleaningTeam && m.teamSize != null
                    ? 'Jamoa · ${m.teamSize} kishi'
                    : m.isMasterBrigade && m.teamSize != null
                    ? 'Brigada · ${m.teamSize} kishi'
                    : m.isCleaningSolo
                    ? 'Yakka tozalovchi'
                    : m.specialty,
                rating: m.rating,
                reviewCount: m.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.sprayCan,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, m.latitude, m.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: m,
                      category: ServiceHubKind.tozalash,
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

/// Usta chaqirish — yakka usta va brigadalar BITTA ro'yxatда (eng yaqin bo'yicha).
/// Filtrда "Brigada / Yakka usta" tanlovi bor.
class MasterDispatchHubSection extends StatefulWidget {
  final List<Master> masters;
  final Color accentColor;

  const MasterDispatchHubSection({
    super.key,
    required this.masters,
    required this.accentColor,
  });

  @override
  State<MasterDispatchHubSection> createState() =>
      _MasterDispatchHubSectionState();
}

class _MasterDispatchHubSectionState extends State<MasterDispatchHubSection> {
  static const _kBrigade = 'Brigada';
  static const _kSolo = 'Yakka usta';

  String? _type; // null = barchasi

  List<Master> get _filtered {
    var list = List<Master>.from(widget.masters);
    if (_type == _kBrigade) {
      list = list.where((m) => m.isMasterBrigade).toList();
    } else if (_type == _kSolo) {
      list = list.where((m) => m.isMasterSolo).toList();
    }
    // Har doim eng yaqin bo'yicha — yakka usta va brigada aralash.
    list.sort(
      (a, b) => a
          .distanceKmFrom(kDefaultUserLat, kDefaultUserLng)
          .compareTo(b.distanceKmFrom(kDefaultUserLat, kDefaultUserLng)),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.masters.isEmpty) return const SizedBox.shrink();
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin ustalar'.tr,
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
                accent: widget.accentColor,
                showSort: false,
                categories: const [_kBrigade, _kSolo],
                selectedCategory: _type,
                onCategorySelected: (v) => setState(() => _type = v),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: Text(
                'Usta topilmadi'.tr,
                style: TextStyle(color: GlassTokens.secondaryText(context)),
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
                final m = items[i];
                final minPrice = m.prices.values.isEmpty
                    ? 100000.0
                    : m.prices.values.reduce((a, b) => a < b ? a : b);
                return VenueHubCard.generic(
                  name: m.name,
                  subtitle: m.isMasterBrigade && m.teamSize != null
                      ? 'Brigada · ${m.teamSize} kishi'
                      : m.specialty,
                  rating: m.rating,
                  reviewCount: m.reviewCount,
                  priceLabel: '${(minPrice / 1000).round()}k+',
                  icon: m.isMasterBrigade
                      ? LucideIcons.users
                      : LucideIcons.user,
                  accent: widget.accentColor,
                  distanceKmValue: distanceKm(
                    kDefaultUserLat, kDefaultUserLng, m.latitude, m.longitude,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: m,
                        category: ServiceHubKind.usta,
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

/// Elektrik — yakka ustalar, uyga chaqiruv.
class ElectricianHubSection extends StatelessWidget {
  final List<Master> electricians;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const ElectricianHubSection({
    super.key,
    required this.electricians,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (electricians.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin elektriklar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${electricians.length} ta',
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
            itemCount: electricians.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final e = electricians[i];
              final minPrice = e.prices.values.isEmpty
                  ? 100000.0
                  : e.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: e.name,
                subtitle: e.serviceArea ?? 'Uyga xizmat',
                rating: e.rating,
                reviewCount: e.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.zap,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, e.latitude, e.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: e,
                      category: ServiceHubKind.elektrik,
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

class PlumberHubSection extends StatelessWidget {
  final List<Master> plumbers;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const PlumberHubSection({
    super.key,
    required this.plumbers,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (plumbers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin santexniklar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${plumbers.length} ta',
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
            itemCount: plumbers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final p = plumbers[i];
              final minPrice = p.prices.values.isEmpty
                  ? 100000.0
                  : p.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: p.name,
                subtitle: p.serviceArea ?? 'Uyga xizmat',
                rating: p.rating,
                reviewCount: p.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.droplet,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, p.latitude, p.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: p,
                      category: ServiceHubKind.santexnik,
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

class AcHubSection extends StatelessWidget {
  final List<Master> technicians;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const AcHubSection({
    super.key,
    required this.technicians,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yaqin konditsioner ustalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${technicians.length} ta',
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
            itemCount: technicians.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final t = technicians[i];
              final minPrice = t.prices.values.isEmpty
                  ? 180000.0
                  : t.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: t.name,
                subtitle: t.serviceArea ?? 'Uyga xizmat',
                rating: t.rating,
                reviewCount: t.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.wind,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, t.latitude, t.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: t,
                      category: ServiceHubKind.konditsioner,
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

class NannyHubSection extends StatelessWidget {
  final List<NannyService> nannies;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const NannyHubSection({
    super.key,
    required this.nannies,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (nannies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tasdiqlangan enagalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Text(
                '${nannies.length} ta',
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
            itemCount: nannies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final n = nannies[i];
              final minPrice = n.prices.values.isEmpty
                  ? 80000.0
                  : n.prices.values.reduce((a, b) => a < b ? a : b);
              return VenueHubCard.generic(
                name: n.name,
                subtitle: '${n.experienceYears} yil • ${n.ageGroupsLabel}',
                rating: n.rating,
                reviewCount: n.reviewCount,
                priceLabel: '${(minPrice / 1000).round()}k+',
                icon: LucideIcons.baby,
                accent: accentColor,
                distanceKmValue: distanceKm(
                  kDefaultUserLat, kDefaultUserLng, n.latitude, n.longitude,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NannyProfileScreen(nanny: n),
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
