import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/services_grid_widget.dart';
import 'provider_registration/provider_onboarding_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18),
              HomeHeaderWidget(),
              SizedBox(height: 22),
              SearchBarWidget(),
              SizedBox(height: 22),
              ActiveOrderBanner(),
              const ServicesGridWidget(),
              const SizedBox(height: 24),
              _buildProviderCard(context),
              const SizedBox(height: 28),
              const HomePromoSection(),
              SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.briefcase, color: Color(0xFF6366F1), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Siz qaysi soha egasisiz?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Biz sizni ushbu platformaga qo\'shamiz — mijozlar sizni topadi, buyurtmalar keladi.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProviderOnboardingScreen()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Usta / xizmat sifatida qo\'shilish'),
            ),
          ),
        ],
      ),
    );
  }
}
