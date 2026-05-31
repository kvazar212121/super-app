import 'package:flutter/material.dart';
import '../../config/provider_category_config.dart';
import 'unified_provider_dashboard_screen.dart';

class ElectricianDashboardScreen extends StatelessWidget {
  const ElectricianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedProviderDashboardScreen(config: ProviderCategoryConfig.electrician);
  }
}
