import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'todo_screen.dart';
import 'shopping_list_screen.dart';
import '../widgets/daily_utilities_widget.dart';

class PlannerHubScreen extends StatelessWidget {
  const PlannerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejalar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _HubActionCard(
              icon: LucideIcons.checkSquare,
              title: 'Mening rejalarim',
              subtitle: 'Kundalik vazifalar va eslatmalar',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoScreen()));
              },
            ),
            const SizedBox(height: 16),
            _HubActionCard(
              icon: LucideIcons.shoppingBag,
              title: 'Aqlli savdo',
              subtitle: 'Bozorlik ro\'yxati va narxlar',
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()));
              },
            ),
            const SizedBox(height: 16),
            const PrayerWidget(), // Fits beautifully due to its internal styling
          ],
        ),
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HubActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color.lerp(const Color(0xFF1E293B), color, 0.15) : Color.lerp(Colors.white, color, 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
