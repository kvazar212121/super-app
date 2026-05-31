import 'package:flutter/material.dart';
import '../../config/provider_category_config.dart';
import 'unified_provider_dashboard_screen.dart';

class EducationDashboardScreen extends StatelessWidget {
  const EducationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedProviderDashboardScreen(config: ProviderCategoryConfig.education);
  }
}
