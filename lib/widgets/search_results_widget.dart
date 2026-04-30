import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../screens/barber_map_screen.dart';

class SearchResultsWidget extends StatelessWidget {
  final String query;
  const SearchResultsWidget({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final services = [
      {"name": "Sartarosh", "icon": LucideIcons.scissors, "color": Colors.blue},
      {"name": "Salon", "icon": LucideIcons.sparkles, "color": Colors.pink},
      {"name": "Futbol", "icon": LucideIcons.trophy, "color": Colors.green},
      {"name": "Ishchi", "icon": LucideIcons.users, "color": Colors.orange},
      {"name": "Usta", "icon": LucideIcons.wrench, "color": Colors.teal},
      {"name": "Elektrik", "icon": LucideIcons.zap, "color": Colors.yellow[700]!},
      {"name": "Santexnik", "icon": LucideIcons.droplet, "color": Colors.lightBlue},
      {"name": "Oshpaz", "icon": LucideIcons.utensils, "color": Colors.brown},
      {"name": "Haydovchi", "icon": LucideIcons.car, "color": Colors.indigo},
    ];

    if (query.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Yaqin atrofdagi sartaroshlar", style: TextStyle(fontWeight: FontWeight.bold)),
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

    final filtered = services.where((s) => s["name"].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: filtered[i]["color"].withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(filtered[i]["icon"], color: filtered[i]["color"]),
        ),
        title: Text(filtered[i]["name"]),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {},
      ),
    );
  }
}

class _ShopListItem extends StatelessWidget {
  final BarberShop shop;
  const _ShopListItem({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.cut)),
        title: Text(shop.name),
        subtitle: Text(shop.address),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, size: 14, color: Colors.amber), Text(" ${shop.rating}")]),
            Text("${shop.reviewCount} sharh", style: const TextStyle(fontSize: 10)),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BarberMapScreen(shops: [shop]))),
      ),
    );
  }
}
