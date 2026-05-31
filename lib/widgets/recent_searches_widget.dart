import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

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
            Text(
              "So'nggi qidiruvlar",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text("Tozalash")),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches.map((s) {
            return GlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 20,
              showShadow: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s,
                    style: TextStyle(
                      color: GlassTokens.primaryText(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => onRemove(s),
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
