import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../theme/glass_tokens.dart';
import '../../theme/lux_tokens.dart';

/// Hub ekranlari uchun filtr turi — boshqa sohalarga ham qo'llash mumkin.
enum HubListFilter { all, nearest, topRated, openNow, promotions }

const Map<HubListFilter, String> kHubFilterLabels = {
  HubListFilter.all: 'Barchasi',
  HubListFilter.nearest: 'Eng yaqin',
  HubListFilter.topRated: 'Reyting',
  HubListFilter.openNow: 'Hozir ochiq',
  HubListFilter.promotions: 'Aksiyalar',
};

const Map<HubListFilter, IconData> _kHubFilterIcons = {
  HubListFilter.all: LucideIcons.layoutGrid,
  HubListFilter.nearest: LucideIcons.mapPin,
  HubListFilter.topRated: LucideIcons.star,
  HubListFilter.openNow: LucideIcons.clock,
  HubListFilter.promotions: LucideIcons.badgePercent,
};

/// Filtr modalini ochadi — "Xizmat turi" (subkategoriya) + "Saralash".
///
/// Ham [HubFilterButton] (ro'yxat sarlavhasidagi ixcham tugma), ham xarita
/// ekranidagi pastki "Filtrlar" tugmasi SHU funksiyani chaqiradi, shuning
/// uchun ikkala ekranda filtr ko'rinishi va mantiqi bir xil bo'ladi.
Future<void> showHubFilterSheet(
  BuildContext context, {
  required Color accent,
  List<String> categories = const [],
  String? selectedCategory,
  ValueChanged<String?>? onCategorySelected,
  HubListFilter selected = HubListFilter.all,
  ValueChanged<HubListFilter>? onChanged,
  bool showSort = true,
}) {
  final isActive =
      (showSort && selected != HubListFilter.all) || selectedCategory != null;

  Widget sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: .04,
          color: GlassTokens.secondaryText(context),
        ),
      );

  Widget catChip(
    BuildContext sheetCtx,
    String label,
    bool isSel,
    String? value,
  ) {
    return InkWell(
      onTap: () {
        onCategorySelected?.call(value);
        Navigator.pop(sheetCtx);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSel ? accent : GlassTokens.glassFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? accent : GlassTokens.glassBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : GlassTokens.primaryText(context),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filtr'.tr,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: GlassTokens.primaryText(context),
                            ),
                          ),
                          const Spacer(),
                          if (isActive)
                            TextButton.icon(
                              onPressed: () {
                                if (showSort) onChanged?.call(HubListFilter.all);
                                onCategorySelected?.call(null);
                                Navigator.pop(ctx);
                              },
                              icon: const Icon(LucideIcons.rotateCcw,
                                  size: 15, color: Color(0xFFEF4444)),
                              label: Text('Tozalash'.tr,
                                  style: const TextStyle(
                                      color: Color(0xFFEF4444), fontSize: 13)),
                            ),
                        ],
                      ),
                      // ── Xizmat turi (subkategoriya) ──
                      if (categories.isNotEmpty &&
                          onCategorySelected != null) ...[
                        const SizedBox(height: 10),
                        sectionLabel('Xizmat turi'.tr),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            catChip(ctx, 'Barchasi'.tr, selectedCategory == null,
                                null),
                            ...categories.map((c) => catChip(
                                ctx, c.tr, selectedCategory == c, c)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // ── Saralash ──
                      if (showSort) ...[
                        sectionLabel('Saralash'.tr),
                        const SizedBox(height: 4),
                        ...HubListFilter.values.map((f) {
                          final isSel = f == selected;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            dense: true,
                            leading: Icon(_kHubFilterIcons[f],
                                size: 20,
                                color: isSel
                                    ? accent
                                    : GlassTokens.secondaryText(context)),
                            title: Text(
                              kHubFilterLabels[f]!.tr,
                              style: TextStyle(
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w500,
                                color: isSel
                                    ? accent
                                    : GlassTokens.primaryText(context),
                              ),
                            ),
                            trailing: isSel
                                ? Icon(LucideIcons.check, color: accent, size: 20)
                                : null,
                            onTap: () {
                              onChanged?.call(f);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Ixcham "Filtr" tugmasi — bosilganда modal oynada filtrlar + "Tozalash".
/// Bo'lim sarlavhasining o'ng tarafida ishlatiladi (chiplar o'rniga).
class HubFilterButton extends StatelessWidget {
  final HubListFilter selected;
  final ValueChanged<HubListFilter>? onChanged;
  final Color accent;

  /// Ixtiyoriy — "Xizmat turi" (subkategoriya) tanlash. Bo'sh bo'lsa
  /// modalда faqat saralash ko'rinadi.
  final List<String> categories;
  final String? selectedCategory; // null = Barchasi
  final ValueChanged<String?>? onCategorySelected;

  /// false bo'lsa — modalда faqat "Xizmat turi" ko'rinadi (saralashsiz).
  final bool showSort;

  const HubFilterButton({
    super.key,
    this.selected = HubListFilter.all,
    this.onChanged,
    required this.accent,
    this.categories = const [],
    this.selectedCategory,
    this.onCategorySelected,
    this.showSort = true,
  });

  bool get _isActive =>
      (showSort && selected != HubListFilter.all) || selectedCategory != null;

  void _openSheet(BuildContext context) {
    // Modal endi umumiy funksiyada — xarita ekrani bilan bir xil ko'rinish.
    showHubFilterSheet(
      context,
      accent: accent,
      categories: categories,
      selectedCategory: selectedCategory,
      onCategorySelected: onCategorySelected,
      selected: selected,
      onChanged: onChanged,
      showSort: showSort,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _isActive ? accent.withValues(alpha: 0.14) : GlassTokens.glassFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isActive ? accent : GlassTokens.glassBorder(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.slidersHorizontal, size: 15,
                color: _isActive ? accent : GlassTokens.secondaryText(context)),
            const SizedBox(width: 6),
            Text(
              selectedCategory != null
                  ? selectedCategory!.tr
                  : (showSort && selected != HubListFilter.all
                      ? kHubFilterLabels[selected]!.tr
                      : 'Filtr'.tr),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _isActive ? accent : GlassTokens.primaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gorizontal filtr chiplari (sartarosh, salon, futbol…).
class HubFilterChips extends StatelessWidget {
  final HubListFilter selected;
  final ValueChanged<HubListFilter> onChanged;
  final Color accent;

  const HubFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.accent,
  });

  static const _labels = {
    HubListFilter.all: 'Barchasi',
    HubListFilter.nearest: 'Eng yaqin',
    HubListFilter.topRated: 'Reyting',
    HubListFilter.openNow: 'Hozir ochiq',
    HubListFilter.promotions: 'Aksiyalar',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HubListFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = HubListFilter.values[i];
          final isSelected = f == selected;
          return FilterChip(
            label: Text(_labels[f]!.tr),
            selected: isSelected,
            onSelected: (_) => onChanged(f),
            selectedColor: accent,
            backgroundColor: LuxTokens.surface,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF0A0A0B),
              fontSize: 13,
            ),
            side: BorderSide(color: isSelected ? accent : Colors.transparent),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}
