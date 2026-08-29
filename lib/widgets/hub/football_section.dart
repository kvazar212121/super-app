import 'package:flutter/material.dart';

import '../../models/football_field.dart';
import '../../theme/glass_tokens.dart';
import '../../utils/geo_utils.dart';
import 'hub_filter_chips.dart';
import 'venue_hub_card.dart';

/// Futbol hub — filtr + kartalar.
class FootballHubSection extends StatefulWidget {
  final List<FootballField> fields;
  final Color accentColor;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;

  const FootballHubSection({
    super.key,
    required this.fields,
    required this.accentColor,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  State<FootballHubSection> createState() => _FootballHubSectionState();
}

class _FootballHubSectionState extends State<FootballHubSection> {
  HubListFilter _filter = HubListFilter.all;

  List<FootballField> get _filtered {
    var list = List<FootballField>.from(widget.fields);
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
        list = list.where((f) => f.isOpenNow()).toList();
      case HubListFilter.promotions:
        list = list.where((f) => f.hasPromo).toList();
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
                  'Yaqin futbol maydonlari',
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
            child: Center(
              child: Text(
                'Maydon topilmadi',
                style: TextStyle(color: GlassTokens.secondaryText(context)),
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final f = items[i];
                return SizedBox(
                  width: 280,
                  child: VenueHubCard.fromFootballField(
                    f,
                    accent: widget.accentColor,
                    onTap: () => showFieldPreviewSheet(
                      context,
                      field: f,
                      accent: widget.accentColor,
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
