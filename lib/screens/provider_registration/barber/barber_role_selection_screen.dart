import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/barber_portal_service.dart';
import '../../provider_side/provider_theme.dart';
import 'barber_employee_join_screen.dart';
import 'barber_mobile_screen.dart';
import 'barber_shop_owner_screen.dart';

/// Sartarosh ro'yxatdan o'tish — 3 tur tanlash.
class BarberRoleSelectionScreen extends StatelessWidget {
  final int? categoryDbId;

  const BarberRoleSelectionScreen({super.key, this.categoryDbId});

  void _open(BuildContext context, BarberRegistrationRole role) {
    final screen = switch (role) {
      BarberRegistrationRole.shopOwner => BarberShopOwnerScreen(categoryDbId: categoryDbId),
      BarberRegistrationRole.shopEmployee => const BarberEmployeeJoinScreen(),
      BarberRegistrationRole.mobile => const BarberMobileScreen(),
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
            appBar: AppBar(title: const Text('Sartarosh sifatida')),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Siz kimsiz?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sartaroshxonada bir nechta usta ishlashi mumkin. O\'zingizga mos turini tanlang.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: LucideIcons.store,
                  title: 'Sartarosh xona egasi',
                  subtitle: 'O\'z xonangiz, joylashuv, ustalar va taklif kodi',
                  color: Colors.black,
                  onTap: () => _open(context, BarberRegistrationRole.shopOwner),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: LucideIcons.scissors,
                  title: 'Sartaroshxonada ishlayman',
                  subtitle: 'Mavjud xonani tanlang yoki taklif kodi bilan qo\'shiling. Egasi tasdiqlaydi.',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _open(context, BarberRegistrationRole.shopEmployee),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: LucideIcons.car,
                  title: 'Uyga borib xizmat qilaman',
                  subtitle: 'Mobil sartarosh — mijoz manziliga borasiz',
                  color: const Color(0xFF10B981),
                  onTap: () => _open(context, BarberRegistrationRole.mobile),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey, height: 1.35, fontSize: 13)),
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
