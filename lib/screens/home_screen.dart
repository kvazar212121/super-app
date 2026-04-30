import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/banner_slider_widget.dart';
import '../widgets/services_grid_widget.dart';
import '../widgets/recommended_section_widget.dart';

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
              const SizedBox(height: 20),
              const HomeHeaderWidget(),
              const SizedBox(height: 25),
              const SearchBarWidget(),
              const SizedBox(height: 25),
              const BannerSliderWidget(),
              const SizedBox(height: 30),
              const ServicesGridWidget(),
              const SizedBox(height: 30),
              const RecommendedSectionWidget(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
