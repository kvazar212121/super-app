import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/auth_gate_screen.dart';
import 'glass/glass_surface.dart';
import '../theme/glass_tokens.dart';

class GuestBlockerWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const GuestBlockerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassSurface(
          padding: const EdgeInsets.all(20),
          borderRadius: GlassTokens.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: GlassTokens.primaryText(context)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GlassTokens.secondaryText(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const AuthGateScreen(),
                      ),
                    );
                    if (ok == true && context.mounted) {
                      final auth = context.read<AuthProvider>();
                      if (auth.user != null) {
                        context.read<AppProvider>().applyAuthUser(auth.user!);
                        await context.read<AppProvider>().fetchInitialData();
                      }
                    }
                  },
                  child: const Text('Kirish / Ro\'yxatdan o\'tish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
