import 'package:flutter/material.dart';

class OrdersFilterWidget extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const OrdersFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildFilterChip(context, "Barchasi", "all"),
        const SizedBox(width: 8),
        _buildFilterChip(context, "Faol", "active"),
        const SizedBox(width: 8),
        _buildFilterChip(context, "Yakunlangan", "completed"),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: currentFilter == value,
      onSelected: (_) => onFilterChanged(value),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}
