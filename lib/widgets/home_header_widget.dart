import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';
import 'daily_utilities_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final unreadCount = provider.unreadCount;
    final greetingName = auth.isAuthenticated ? provider.user.name : auth.displayName;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(child: DailyUtilitiesWidget()),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GlassSurface(
              padding: EdgeInsets.zero,
              borderRadius: GlassTokens.radiusMd,
              child: IconButton(
                icon: Icon(
                  LucideIcons.bell,
                  color: GlassTokens.primaryText(context),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
            if (unreadCount > 0)
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
                    unreadCount.toString(),
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
        ),
      ],
    );
  }
}
