import 'package:flutter/material.dart';
import '../widgets/active_order_banner.dart';
import '../widgets/home_promo_section.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/services_grid_widget.dart';

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
            children: const [
              SizedBox(height: 18),
              HomeHeaderWidget(),
              SizedBox(height: 22),
              SearchBarWidget(),
              SizedBox(height: 22),
              ActiveOrderBanner(),
              ServicesGridWidget(),
              SizedBox(height: 28),
              HomePromoSection(),
              SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
