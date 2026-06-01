import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/salon_portal_service.dart';
import '../../provider_side/provider_theme.dart';
import 'salon_employee_join_screen.dart';
import 'salon_mobile_screen.dart';
import 'salon_owner_screen.dart';

class SalonRoleSelectionScreen extends StatelessWidget {
  const SalonRoleSelectionScreen({super.key});

  void _open(BuildContext context, SalonRegistrationRole role) {
    final screen = switch (role) {
      SalonRegistrationRole.owner => const SalonOwnerScreen(),
      SalonRegistrationRole.employee => const SalonEmployeeJoinScreen(),
      SalonRegistrationRole.mobile => const SalonMobileScreen(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(title: const Text('Salon sifatida')),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Siz kimsiz?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salonda bir nechta mutaxassis ishlashi mumkin. O\'zingizga mos turini tanlang.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: LucideIcons.store,
                  title: 'Salon egasi',
                  subtitle: 'O\'z saloningiz, joylashuv, xodimlar va taklif kodi',
                  color: const Color(0xFFEC4899),
                  onTap: () => _open(context, SalonRegistrationRole.owner),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: LucideIcons.sparkles,
                  title: 'Salonda ishlayman',
                  subtitle: 'Mavjud salonni tanlang yoki taklif kodi bilan qo\'shiling',
                  color: const Color(0xFF6366F1),
                  onTap: () => _open(context, SalonRegistrationRole.employee),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: LucideIcons.home,
                  title: 'Uyga borib xizmat qilaman',
                  subtitle: 'Mobil kosmetolog — mijoz manziliga borasiz',
                  color: const Color(0xFF10B981),
                  onTap: () => _open(context, SalonRegistrationRole.mobile),
                ),
              ],
            ),
          );
        },
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
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], height: 1.35, fontSize: 13)),
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
