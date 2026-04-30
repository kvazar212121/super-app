import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../screens/barber_map_screen.dart';

class ServicesGridWidget extends StatelessWidget {
  const ServicesGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Xizmatlar", style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () {}, child: const Text("Barchasi")),
          ],
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
          children: [
            _ServiceItem(title: "Sartarosh", icon: LucideIcons.scissors, color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BarberMapScreen(shops: [])))),
            _ServiceItem(title: "Salon", icon: LucideIcons.sparkles, color: Colors.pink, onTap: () {}),
            _ServiceItem(title: "Futbol", icon: LucideIcons.trophy, color: Colors.green, onTap: () {}),
            _ServiceItem(title: "Ishchi", icon: LucideIcons.users, color: Colors.orange, onTap: () {}),
            _ServiceItem(title: "Usta", icon: LucideIcons.wrench, color: Colors.teal, onTap: () {}),
            _ServiceItem(title: "Elektrik", icon: LucideIcons.zap, color: Colors.yellow[700]!, onTap: () {}),
            _ServiceItem(title: "Santexnik", icon: LucideIcons.droplet, color: Colors.lightBlue, onTap: () {}),
            _ServiceItem(title: "Yana", icon: LucideIcons.moreHorizontal, color: Colors.grey, onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
