import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/master_portal_service.dart';
import '../../provider_side/provider_theme.dart';
import 'master_solo_screen.dart';
import 'master_brigade_screen.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// Usta ro'yxatdan o'tish — yakka yoki brigada.
class MasterRoleSelectionScreen extends StatelessWidget {
  const MasterRoleSelectionScreen({super.key});

  void _open(BuildContext context, MasterRegistrationRole role) {
    final screen = switch (role) {
      MasterRegistrationRole.solo => const MasterSoloScreen(),
      MasterRegistrationRole.brigade => const MasterBrigadeScreen(),
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
            appBar: AppBar(title: Text('Usta sifatida'.tr)),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Qanday ishlayapsiz?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usta chaqirish xizmati yakka kishi yoki brigada sifatida ko\'rsatilishi mumkin.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: LucideIcons.user,
                  title: 'Yakka usta',
                  subtitle:
                      'O\'zingiz mijoz manziliga borasiz — kichik ta\'mirlash ishlar',
                  color: const Color(0xFF78716C),
                  onTap: () => _open(context, MasterRegistrationRole.solo),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: LucideIcons.users,
                  title: 'Ustalar brigadasi',
                  subtitle:
                      'Bir necha usta bilan katta ta\'mirlash va montaj ishlar',
                  color: Colors.black,
                  onTap: () => _open(context, MasterRegistrationRole.brigade),
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
