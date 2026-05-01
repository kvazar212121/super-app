import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RecentSearchesWidget extends StatelessWidget {
  final List<String> searches;
  final VoidCallback onClear;
  final Function(String) onRemove;

  const RecentSearchesWidget({
    super.key,
    required this.searches,
    required this.onClear,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("So'nggi qidiruvlar", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(onPressed: onClear, child: const Text("Tozalash")),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches.map((s) => Chip(
            label: Text(s),
            deleteIcon: const Icon(LucideIcons.x, size: 18),
            onDeleted: () => onRemove(s),
          )).toList(),
        ),
      ],
    );
  }
}
