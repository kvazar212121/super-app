import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/services_grid_widget.dart';
import 'provider_registration/provider_onboarding_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/glass/glass_surface.dart';
import '../theme/glass_tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeaderWidget(),
            const SizedBox(height: 22),
            const SearchBarWidget(),
            const SizedBox(height: 22),
            const ActiveOrderBanner(),
            const ServicesGridWidget(),
            const SizedBox(height: 24),
            _buildProviderCard(context),
            const SizedBox(height: 28),
            const HomePromoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: GlassTokens.radiusLg,
      opacity: 0.62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  LucideIcons.briefcase,
                  color: Color(0xFF6366F1),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Siz qaysi soha egasisiz?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Biz sizni ushbu platformaga qo\'shamiz — mijozlar sizni topadi, buyurtmalar keladi.',
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderOnboardingScreen(),
                  ),
                );
              },
              child: const Text('Usta / xizmat sifatida qo\'shilish'),
            ),
          ),
        ],
      ),
    );
  }
}
