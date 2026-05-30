import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/service_hub_kind.dart';
import '../screens/all_categories_screen.dart';
import '../screens/service_hub_screen.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

class ServicesGridWidget extends StatelessWidget {
  const ServicesGridWidget({super.key});

  static const _popular = <ServiceHubKind>[
    ServiceHubKind.sartarosh,
    ServiceHubKind.usta,
    ServiceHubKind.tozalash,
    ServiceHubKind.futbol,
    ServiceHubKind.texnikaUstasi,
    ServiceHubKind.kuryerlik,
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
      MaterialPageRoute<void>(builder: (_) => const AllCategoriesScreen()),
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
              'Xizmatlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: GlassTokens.primaryText(context),
              ),
            ),
            TextButton(
              onPressed: () => _openAll(context),
              child: const Text('Barchasi'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: _popular
              .map((k) => _ServiceItem(kind: k, onTap: () => _openHub(context, k)))
              .toList(),
        ),
        const SizedBox(height: 14),
        GlassSurface(
          onTap: () => _openAll(context),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          borderRadius: GlassTokens.radiusLg,
          opacity: 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.layoutGrid, color: GlassTokens.primaryText(context)),
              const SizedBox(width: 10),
              Text(
                'Barcha xizmatlar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
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
    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderRadius: GlassTokens.radiusMd,
      opacity: 0.52,
      tint: accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(kind.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              kind.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: GlassTokens.primaryText(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
