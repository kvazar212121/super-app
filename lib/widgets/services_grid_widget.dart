import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    ServiceHubKind.stomatologiya,
    ServiceHubKind.hamshira,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Xizmatlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ),
            GlassSurface(
              onTap: () => _openAll(context),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              borderRadius: GlassTokens.radiusMd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.layoutGrid,
                    size: 16,
                    color: GlassTokens.primaryText(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Barcha xizmatlar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            mainAxisExtent: 68,
          ),
          itemCount: _popular.length,
          itemBuilder: (context, index) {
            final k = _popular[index];
            return _ServiceItem(kind: k, onTap: () => _openHub(context, k));
          },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: GlassTokens.radiusMd,
      tint: accent.withValues(alpha: 0.08),
      showShadow: false,
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
