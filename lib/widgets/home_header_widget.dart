import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final unreadCount = provider.unreadCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assalomu alaykum,',
              style: TextStyle(
                fontSize: 14,
                color: GlassTokens.secondaryText(context),
              ),
            ),
            Text(
              provider.user.name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: GlassTokens.primaryText(context),
              ),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GlassSurface(
              padding: EdgeInsets.zero,
              borderRadius: GlassTokens.radiusMd,
              opacity: 0.58,
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
