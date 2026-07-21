import 'package:flutter/material.dart';
import '../theme/glass_tokens.dart';
import 'package:super_app/l10n/locale_controller.dart';

class HubCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final Color accentColor;

  const HubCategoryChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedCategory == null;
            return ChoiceChip(
              label: Text('Barchasi'.tr),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onCategorySelected(null);
              },
              selectedColor: accentColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? accentColor
                    : GlassTokens.primaryText(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: GlassTokens.glassFill(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? accentColor
                      : GlassTokens.glassBorder(context),
                ),
              ),
            );
          }

          final cat = categories[index - 1];
          final isSelected = selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat.tr),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(cat);
              } else {
                onCategorySelected(null);
              }
            },
            selectedColor: accentColor.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected
                  ? accentColor
                  : GlassTokens.primaryText(context),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: GlassTokens.glassFill(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? accentColor
                    : GlassTokens.glassBorder(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
