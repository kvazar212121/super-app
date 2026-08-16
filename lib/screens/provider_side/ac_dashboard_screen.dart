import 'package:flutter/material.dart';
import '../../config/provider_category_config.dart';
import 'unified_provider_dashboard_screen.dart';

/// ESKIRGAN: Konditsioner endi "Texnika ustasi" ichidagi xizmat turi.
///
/// Yangi provayderlar bu kategoriyada ro'yxatdan o'ta olmaydi, ammo AVVAL
/// shu yerda ro'yxatdan o'tganlar paneli ochilishi uchun ekran saqlanadi.
class AcDashboardScreen extends StatelessWidget {
  const AcDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return UnifiedProviderDashboardScreen(config: ProviderCategoryConfig.ac);
  }
}
