import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../l10n/locale_controller.dart';
import '../provider_side/provider_theme.dart';
import 'provider_category_selection_screen.dart';

class ProviderOnboardingScreen extends StatelessWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: Text('Xizmat ko\'rsatish'.tr),
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.briefcase,
                      size: 52,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'O\'z xizmatingizni taqdim eting'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bizning platformada minglab mijozlar o\'ziga kerakli ustani qidirmoqda. Siz ham ular orasida bo\'ling!'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureItem(
                      context,
                      LucideIcons.users,
                      'Mijozlar oqimini ko\'paytiring'.tr,
                      'Doimiy mijozlar va ko\'proq buyurtmalar oling.'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      LucideIcons.clock,
                      'Erkin ish grafigi'.tr,
                      'O\'zingizga qulay vaqtda va joyda ishlang.'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      LucideIcons.shieldCheck,
                      'Ishonchli to\'lov'.tr,
                      'Xizmatlaringiz uchun kafolatlangan to\'lovlar.'.tr,
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProviderCategorySelectionScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Davom etish'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
