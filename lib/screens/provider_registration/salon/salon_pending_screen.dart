import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../main_screen.dart';
import '../../provider_side/provider_theme.dart';
import 'package:super_app/l10n/locale_controller.dart';

class SalonPendingScreen extends StatelessWidget {
  final String salonName;

  const SalonPendingScreen({super.key, required this.salonName});

  @override
  Widget build(BuildContext context) {
    return ProviderTheme(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    size: 48,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 28),
                Text('So\'rov yuborildi'.tr,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '$salonName salon egasi so\'rovingizni ko\'rib, qabul qiladi yoki rad etadi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], height: 1.45),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (_) => false,
                      );
                    },
                    child: Text('Bosh sahifaga'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
