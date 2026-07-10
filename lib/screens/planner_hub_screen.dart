import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'todo_screen.dart';
import 'shopping_list_screen.dart';
import '../widgets/daily_utilities_widget.dart';
import 'package:super_app/l10n/locale_controller.dart';

class PlannerHubScreen extends StatelessWidget {
  const PlannerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rejalar'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _HubActionCard(
              icon: LucideIcons.checkSquare,
              title: 'Mening rejalarim',
              subtitle: 'Kundalik vazifalar va eslatmalar',
              color: Colors.blueAccent,
              bgImage: 'assets/images/my_plans.jpg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TodoScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _HubActionCard(
              icon: LucideIcons.shoppingBag,
              title: 'Aqlli savdo',
              subtitle: 'Bozorlik ro\'yxati va narxlar',
              color: Colors.orangeAccent,
              bgImage: 'assets/images/smart_shopping.jpg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                );
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
  final String? bgImage;

  const _HubActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.bgImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = bgImage != null
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final iconBgColor = bgImage != null ? Colors.white24 : color;
    final iconColor = bgImage != null ? Colors.white : color;
    final chevronColor = bgImage != null ? Colors.white70 : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgImage != null
              ? Colors.black
              : (isDark
                    ? Color.lerp(const Color(0xFF1E293B), color, 0.15)
                    : Color.lerp(Colors.white, color, 0.1)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color : color),
          image: bgImage != null
              ? DecorationImage(
                  image: AssetImage(bgImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcOver,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                      shadows: bgImage != null
                          ? [
                              const Shadow(
                                color: Colors.black87,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: bgImage != null ? Colors.white70 : textColor,
                      fontSize: 13,
                      shadows: bgImage != null
                          ? [
                              const Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: chevronColor, size: 20),
          ],
        ),
      ),
    );
  }
}
