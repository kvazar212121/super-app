import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../screens/barber_map_screen.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

class _ServiceEntry {
  final String name;
  final IconData icon;
  final Color color;
  const _ServiceEntry({required this.name, required this.icon, required this.color});
}

class SearchResultsWidget extends StatelessWidget {
  final String query;
  const SearchResultsWidget({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    const services = <_ServiceEntry>[
      _ServiceEntry(name: "Sartarosh", icon: LucideIcons.scissors, color: Colors.blue),
      _ServiceEntry(name: "Salon", icon: LucideIcons.sparkles, color: Colors.pink),
      _ServiceEntry(name: "Futbol", icon: LucideIcons.trophy, color: Colors.green),
      _ServiceEntry(name: "Ishchi", icon: LucideIcons.users, color: Colors.orange),
      _ServiceEntry(name: "Usta", icon: LucideIcons.wrench, color: Colors.teal),
      _ServiceEntry(name: "Elektrik", icon: LucideIcons.zap, color: Color(0xFFF59E0B)),
      _ServiceEntry(name: "Santexnik", icon: LucideIcons.droplet, color: Colors.lightBlue),
      _ServiceEntry(name: "Oshpaz", icon: LucideIcons.utensils, color: Colors.brown),
      _ServiceEntry(name: "Haydovchi", icon: LucideIcons.car, color: Colors.indigo),
    ];

    if (query.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Yaqin atrofdagi sartaroshlar",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: BarberShop.demoShops.length,
              itemBuilder: (ctx, i) => _ShopListItem(shop: BarberShop.demoShops[i]),
            ),
          ),
        ],
      );
    }

    final filtered = services
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final s = filtered[i];
        return GlassSurface(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          borderRadius: GlassTokens.radiusMd,
          onTap: () {},
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: s.color.withValues(alpha: 0.2)),
                ),
                child: Icon(s.icon, color: s.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: GlassTokens.secondaryText(context), size: 18),
            ],
          ),
        );
      },
    );
  }
}

class _ShopListItem extends StatelessWidget {
  final BarberShop shop;
  const _ShopListItem({required this.shop});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderRadius: GlassTokens.radiusLg,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BarberMapScreen(shops: [shop])),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.scissors, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shop.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: GlassTokens.secondaryText(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  Text(
                    ' ${shop.rating}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                ],
              ),
              Text(
                '${shop.reviewCount} sharh',
                style: TextStyle(
                  fontSize: 11,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
