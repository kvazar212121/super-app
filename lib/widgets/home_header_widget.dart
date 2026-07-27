import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';
import 'daily_utilities_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final unreadCount = provider.unreadCount;

    // Chapda — ob-havo/valyuta (ixcham), o'ngda — qo'ng'iroqcha + profil tugmasi.
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
        // Profil endi shu yerda (yuqori o'ng) — pastki menyudan ko'chirildi.
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

/// Shisha uslubidagi ixcham dumaloq-burchakli ikon tugma (qo'ng'iroqcha/profil).
/// Ixtiyoriy [badgeCount] > 0 bo'lsa o'ng-yuqorida qizil hisoblagich chiqadi.
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassSurface(
          padding: EdgeInsets.zero,
          borderRadius: GlassTokens.radiusMd,
          child: IconButton(
            icon: Icon(icon, color: GlassTokens.primaryText(context)),
            onPressed: onTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
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
