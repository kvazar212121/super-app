import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/lux_tokens.dart';
import 'daily_utilities_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final unreadCount = provider.unreadCount;

    return Row(
      children: [
        const Expanded(child: DailyUtilitiesWidget()),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: LucideIcons.bell,
          badgeCount: unreadCount,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: LucideIcons.user,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }
}

/// Shisha va Oltin uslubidagi ixcham tugma (qo'ng'iroqcha/profil).
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return _buildLight(context);

    // PREMIUM (dark): qora fon, oltin ramka va sof oltin rangli ikonka.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: Material(
            color: LuxTokens.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LuxTokens.border),
                ),
                child: Icon(icon, color: LuxTokens.gold, size: 20),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LuxTokens.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: LuxTokens.bg, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Color(0xFF14100A),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLight(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFC9A227).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: LuxTokens.gold.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFFC9A227),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
