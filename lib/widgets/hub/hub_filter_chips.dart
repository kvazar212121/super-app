import 'package:flutter/material.dart';

/// Hub ekranlari uchun filtr turi — boshqa sohalarga ham qo'llash mumkin.
enum HubListFilter { all, nearest, topRated, openNow }

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
    HubListFilter.openNow: 'Ochiq',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HubListFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = HubListFilter.values[i];
          final isSelected = f == selected;
          return FilterChip(
            label: Text(_labels[f]!),
            selected: isSelected,
            onSelected: (_) => onChanged(f),
            selectedColor: accent,
            backgroundColor: Colors.white,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? accent : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}
