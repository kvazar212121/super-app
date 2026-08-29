import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../provider_side/provider_theme.dart';
import 'tutor_solo_screen.dart';
import 'tutor_center_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../theme/lux_tokens.dart';

class TutorRoleSelectionScreen extends StatelessWidget {
  const TutorRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        appBar: AppBar(title: Text('Repetitor'.tr)),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Qanday xizmat ko\'rsatasiz?'.tr,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Yakka repetitor (onlayn yoki uyga) yoki o\'quv markazi — band odamlar va o\'quvchilar uchun.'.tr,
              style: TextStyle(color: LuxTokens.textMuted, height: 1.4),
            ),
            const SizedBox(height: 28),
            _RoleCard(
              icon: LucideIcons.user,
              title: 'Yakka repetitor'.tr,
              subtitle:
                  'Onlayn (Zoom/Telegram) yoki uyga kelib individual dars'.tr,
              color: const Color(0xFFB8921F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorSoloScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: LucideIcons.school,
              title: 'O\'quv markazi'.tr,
              subtitle: 'Markazda guruh yoki individual kurslar'.tr,
              color: Colors.black,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorCenterScreen()),
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
