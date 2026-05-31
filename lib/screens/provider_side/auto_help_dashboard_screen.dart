import 'package:flutter/material.dart';
import '../../config/provider_category_config.dart';
import 'unified_provider_dashboard_screen.dart';

class AutoHelpDashboardScreen extends StatelessWidget {
  const AutoHelpDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedProviderDashboardScreen(config: ProviderCategoryConfig.auto);
  }
}
