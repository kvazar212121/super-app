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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_solo.isNotEmpty)
          _section(context, 'Yakka tozalovchilar', _solo, LucideIcons.user,
              withFilter: true),
        if (_teams.isNotEmpty)
          _section(context, 'Tozalash jamoalari', _teams, LucideIcons.users,
              withFilter: _solo.isEmpty),
        if (_solo.isEmpty && _teams.isEmpty)
          _section(
            context,
            'Tozalash xizmatlari',
            cleaners,
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
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _CleaningCard(
              master: items[i],
              accent: accentColor,
              badgeIcon: badgeIcon,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderProfileScreen(
                    master: items[i],
                    category: ServiceHubKind.tozalash,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CleaningCard extends StatelessWidget {
  final Master master;
  final Color accent;
  final IconData badgeIcon;
  final VoidCallback onTap;

  const _CleaningCard({
    required this.master,
    required this.accent,
    required this.badgeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = master.prices.values.isEmpty
        ? 200000
        : master.prices.values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 158,
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
                      LucideIcons.sprayCan,
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
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(badgeIcon, size: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                master.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                master.isCleaningTeam && master.teamSize != null
                    ? 'Jamoa · ${master.teamSize} kishi'
                    : master.isMasterBrigade && master.teamSize != null
                    ? 'Brigada · ${master.teamSize} kishi'
                    : master.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '${master.rating}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(minPrice / 1000).round()}k+',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _MasterDispatchCard(
                master: items[i],
                accent: widget.accentColor,
                badgeIcon: items[i].isMasterBrigade
                    ? LucideIcons.users
                    : LucideIcons.user,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderProfileScreen(
                      master: items[i],
                      category: ServiceHubKind.usta,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MasterDispatchCard extends StatelessWidget {
  final Master master;
  final Color accent;
  final IconData badgeIcon;
  final VoidCallback onTap;

  const _MasterDispatchCard({
    required this.master,
    required this.accent,
    required this.badgeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = master.prices.values.isEmpty
        ? 100000
        : master.prices.values.reduce((a, b) => a < b ? a : b);

    return SizedBox(
      width: 158,
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
                      LucideIcons.hammer,
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
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(badgeIcon, size: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                master.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                master.isMasterBrigade && master.teamSize != null
                    ? 'Brigada · ${master.teamSize} kishi'
                    : master.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '${master.rating}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(minPrice / 1000).round()}k+',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: electricians.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final e = electricians[i];
              final minPrice = e.prices.values.isEmpty
                  ? 100000
                  : e.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: e,
                        category: ServiceHubKind.elektrik,
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
                            LucideIcons.zap,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          e.serviceArea ?? 'Uyga xizmat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${e.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
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
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: plumbers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final p = plumbers[i];
              final minPrice = p.prices.values.isEmpty
                  ? 100000
                  : p.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: p,
                        category: ServiceHubKind.santexnik,
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
                            LucideIcons.droplet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          p.serviceArea ?? 'Uyga xizmat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${p.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
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
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: technicians.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final t = technicians[i];
              final minPrice = t.prices.values.isEmpty
                  ? 180000
                  : t.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 158,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        master: t,
                        category: ServiceHubKind.konditsioner,
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
                            LucideIcons.wind,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          t.serviceArea ?? 'Uyga xizmat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${t.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
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
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: nannies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final n = nannies[i];
              final minPrice = n.prices.values.isEmpty
                  ? 80000
                  : n.prices.values.reduce((a, b) => a < b ? a : b);
              return SizedBox(
                width: 168,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NannyProfileScreen(nanny: n),
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: accentColor,
                              child: Icon(
                                LucideIcons.baby,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (n.isVerified) ...[
                              const Spacer(),
                              Icon(
                                LucideIcons.badgeCheck,
                                size: 16,
                                color: accentColor,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          n.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${n.experienceYears} yil • ${n.ageGroupsLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${n.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(minPrice / 1000).round()}k+',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
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
        const SizedBox(height: 16),
      ],
    );
  }
}
