import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/service_hub_kind.dart';
import '../screens/all_categories_screen.dart';
import '../screens/service_hub_screen.dart';

/// Asosiy ekrandagi soddalashtirilgan xizmatlar bloki.
/// 4 ta eng ommabop kategoriya + "Barcha xizmatlar" keng tugmasi.
class ServicesGridWidget extends StatelessWidget {
  const ServicesGridWidget({super.key});

  static const _popular = <ServiceHubKind>[
    ServiceHubKind.sartarosh,
    ServiceHubKind.usta,
    ServiceHubKind.tozalash,
    ServiceHubKind.futbol,
  ];

  void _openHub(BuildContext context, ServiceHubKind kind) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ServiceHubScreen(kind: kind, accentColor: kind.accent),
      ),
    );
  }

  void _openAll(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AllCategoriesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Xizmatlar",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => _openAll(context),
              child: const Text("Barchasi"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: _popular
              .map((k) => _ServiceItem(kind: k, onTap: () => _openHub(context, k)))
              .toList(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _openAll(context),
            icon: const Icon(LucideIcons.layoutGrid),
            label: const Text(
              'Barcha xizmatlar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final ServiceHubKind kind;
  final VoidCallback onTap;

  const _ServiceItem({required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = kind.accent;
    return Material(
      color: accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(kind.icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kind.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
