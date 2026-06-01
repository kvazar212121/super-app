import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../main_screen.dart';
import '../../config/provider_category_config.dart';
import '../provider_side/unified_provider_dashboard_screen.dart';
import '../provider_side/provider_theme.dart';

class ProviderSuccessScreen extends StatelessWidget {
  final String providerName;
  final String categoryName;
  final String categoryId;

  const ProviderSuccessScreen({
    super.key,
    this.providerName = '',
    this.categoryName = '',
    this.categoryId = '',
  });

  Widget _getDashboard() {
    final config = ProviderCategoryConfig.byRegistrationId(categoryId);
    if (config == null) return const MainScreen();
    return UnifiedProviderDashboardScreen(config: config);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(child: Builder(builder: (context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Tabriklaymiz!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (providerName.isNotEmpty && categoryName.isNotEmpty)
                Text(
                  '$providerName — $categoryName sifatida ro\'yxatdan o\'tdi!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              const SizedBox(height: 12),
              const Text(
                'Administrator tasdiqlaganidan keyin profilingiz mijozlarga ko\'rinadi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => _getDashboard()),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Panelga o\'tish'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Bosh sahifaga qaytish'),
              ),
            ],
          ),
        ),
      ),
    );
    }));
  }
}
