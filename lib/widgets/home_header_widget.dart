import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import 'daily_utilities_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final unreadCount = appProvider.unreadCount;

    final profileUser = appProvider.user;
    final String avatarUrl = (profileUser.avatarUrl != null && profileUser.avatarUrl!.isNotEmpty)
        ? profileUser.avatarUrl!
        : ((authProvider.user?['avatar_url'] as String?) ??
            (authProvider.user?['avatar'] as String?) ??
            (authProvider.user?['image'] as String?) ??
            '');
    final String name = profileUser.name.isNotEmpty ? profileUser.name : authProvider.displayName;
    final String initialLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    const textColor = Color(0xFF0F172A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Top Title Row: HUBSERVIS Logo + Bell Icon + User Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Title Logo
              Text(
                'HUBSERVIS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  // Bell Notification Button with Badge
                  _HeaderIconButton(
                    icon: LucideIcons.bell,
                    badgeCount: unreadCount,
                    textColor: textColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // User Avatar (Photo or Initial Letter Fallback)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E293B),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: AppConfig.formatImageUrl(avatarUrl),
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                memCacheWidth: 120,
                                memCacheHeight: 120,
                                fadeInDuration: const Duration(milliseconds: 120),
                                errorWidget: (_, __, ___) => _buildInitialFallback(initialLetter),
                              )
                            : _buildInitialFallback(initialLetter),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2) Weather & Exchange Rate Pill Chips Row
          const DailyUtilitiesWidget(),
        ],
      ),
    );
  }

  Widget _buildInitialFallback(String letter) {
    return Container(
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFFC9A227),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;
  final Color textColor;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            icon,
            size: 22,
            color: textColor,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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
