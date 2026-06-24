import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/cleaning_portal_service.dart';
import '../../provider_side/provider_theme.dart';
import 'cleaning_solo_screen.dart';
import 'cleaning_team_screen.dart';

/// Tozalash ro'yxatdan o'tish — yakka yoki jamoa.
class CleaningRoleSelectionScreen extends StatelessWidget {
  const CleaningRoleSelectionScreen({super.key});

  void _open(BuildContext context, CleaningRegistrationRole role) {
    final screen = switch (role) {
      CleaningRegistrationRole.solo => const CleaningSoloScreen(),
      CleaningRegistrationRole.team => const CleaningTeamScreen(),
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
            appBar: AppBar(title: const Text('Tozalash xizmati')),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Qanday ishlayapsiz?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tozalash xizmati yakka kishi yoki jamoa sifatida ko\'rsatilishi mumkin. O\'zingizga mos turini tanlang.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: LucideIcons.user,
                  title: 'Yakka tozalovchi',
                  subtitle: 'O\'zingiz uyga borib tozalaysiz — 1–2 xonali kvartiralar uchun qulay',
                  color: const Color(0xFF10B981),
                  onTap: () => _open(context, CleaningRegistrationRole.solo),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: LucideIcons.users,
                  title: 'Tozalash jamoasi / kompaniya',
                  subtitle: 'Bir necha kishilik jamoa — katta kvartira, ofis va general tozalash',
                  color: const Color(0xFF06B6D4),
                  onTap: () => _open(context, CleaningRegistrationRole.team),
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
