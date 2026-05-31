import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/provider_portal_entry.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/services_grid_widget.dart';

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
            const SizedBox(height: 4),
            const ProviderPortalEntry(),
            const SizedBox(height: 28),
            const HomePromoSection(),
          ],
        ),
      ),
    );
  }
}
