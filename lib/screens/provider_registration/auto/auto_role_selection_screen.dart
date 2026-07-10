import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../provider_side/provider_theme.dart';
import 'auto_mobile_screen.dart';
import 'auto_workshop_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Avto-yordam ro'yxatdan o'tish — mobil yoki ustaxona.
class AutoRoleSelectionScreen extends StatelessWidget {
  const AutoRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Avto-yordam'.tr)),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Qanday xizmat ko\'rsatasiz?'.tr,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Mobil yordam (yo\'lda) yoki doimiy ustaxona — o\'zingizga mos turini tanlang.'.tr,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 28),
            _RoleCard(
              icon: LucideIcons.truck,
              title: 'Mobil avto-yordam'.tr,
              subtitle:
                  'Evakuator, benzin yetkazish, joyida ta\'mirlash — yo\'lda xizmat'.tr,
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutoMobileScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: LucideIcons.home,
              title: 'Ustaxona'.tr,
              subtitle:
                  'Doimiy servis markazi — diagnostika, remont, shinopompa'.tr,
              color: const Color(0xFF334155),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AutoWorkshopScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
