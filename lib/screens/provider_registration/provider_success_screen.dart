import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main_screen.dart';
import '../provider_side/barber_dashboard_screen.dart';
import '../provider_side/salon_dashboard_screen.dart';
import '../provider_side/plumber_dashboard_screen.dart';
import '../provider_side/electrician_dashboard_screen.dart';
import '../provider_side/cleaning_dashboard_screen.dart';
import '../provider_side/auto_workshop_dashboard_screen.dart';
import '../provider_side/football_dashboard_screen.dart';
import '../provider_side/education_dashboard_screen.dart';
import '../provider_side/master_dashboard_screen.dart';
import '../provider_side/worker_dashboard_screen.dart';
import '../provider_side/ac_dashboard_screen.dart';
import '../provider_side/nanny_dashboard_screen.dart';
import '../provider_side/tutor_dashboard_screen.dart';
import '../provider_side/disinfection_dashboard_screen.dart';
import '../provider_side/appliance_dashboard_screen.dart';
import '../provider_side/courier_dashboard_screen.dart';
import '../provider_side/massage_dashboard_screen.dart';
import '../provider_side/nurse_dashboard_screen.dart';
import '../provider_side/events_dashboard_screen.dart';

class ProviderSuccessScreen extends StatelessWidget {
  final String providerName;
  final String categoryName;
  final String categoryId;

  const ProviderSuccessScreen({
    super.key,
    this.providerName = '',
    this.categoryName = '',
    this.categoryId = '',
  });

  Widget _getDashboard() {
    return switch (categoryId) {
      'barber' => const BarberDashboardScreen(),
      'salon' => const SalonDashboardScreen(),
      'plumber' => const PlumberDashboardScreen(),
      'electrician' => const ElectricianDashboardScreen(),
      'cleaner' => const CleaningDashboardScreen(),
      'auto' => const AutoWorkshopDashboardScreen(),
      'futbol' => const FootballDashboardScreen(),
      'education' => const EducationDashboardScreen(),
      'builder' => const MasterDashboardScreen(),
      'worker' => const WorkerDashboardScreen(),
      'ac' => const AcDashboardScreen(),
      'nanny' => const NannyDashboardScreen(),
      'tutor' => const TutorDashboardScreen(),
      'disinfection' => const DisinfectionDashboardScreen(),
      'appliance' => const ApplianceDashboardScreen(),
      'courier' => const CourierDashboardScreen(),
      'massage' => const MassageDashboardScreen(),
      'nurse' => const NurseDashboardScreen(),
      'events' => const EventsDashboardScreen(),
      _ => const MainScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Tabriklaymiz!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (providerName.isNotEmpty && categoryName.isNotEmpty)
                Text(
                  '$providerName — $categoryName sifatida ro\'yxatdan o\'tdi!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              const SizedBox(height: 12),
              const Text(
                'Administrator tasdiqlaganidan keyin profilingiz mijozlarga ko\'rinadi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => _getDashboard()),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Panelga o\'tish'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Bosh sahifaga qaytish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
