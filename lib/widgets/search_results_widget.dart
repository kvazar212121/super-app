import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/barber_shop.dart';
import '../screens/barber_map_screen.dart';

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

    final filtered = services.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final s = filtered[i];
        return ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(s.icon, color: s.color),
        ),
        title: Text(s.name),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {},
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
