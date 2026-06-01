import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/provider_category_config.dart';
import '../../main_screen.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import '../../../services/provider_portal_service.dart';

/// Enaga — administrator tasdiqlaguncha.
class NannyPendingScreen extends StatefulWidget {
  final String providerName;

  const NannyPendingScreen({super.key, required this.providerName});

  @override
  State<NannyPendingScreen> createState() => _NannyPendingScreenState();
}

class _NannyPendingScreenState extends State<NannyPendingScreen> {
  final _portal = ProviderPortalService();
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final data = await _portal.getMe('enaga');
      final active = data['is_active'] == true;
      final meta = data['metadata'] as Map<String, dynamic>? ??
          data['metadata_json'] as Map<String, dynamic>? ??
          {};
      final verified = meta['verification_status'] == 'verified' ||
          meta['nanny_role'] == 'verified';

      if (!mounted) return;
      if (active && verified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedProviderDashboardScreen(
              config: ProviderCategoryConfig.nanny,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hali tasdiqlanmagan. Biroz kuting.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Holatni tekshirib bo\'lmadi')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

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
                    color: const Color(0xFFF472B6).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.baby, size: 48, color: Color(0xFFF472B6)),
                ),
                const SizedBox(height: 28),
                const Text(
                  'So\'rov yuborildi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.providerName.isNotEmpty
                      ? '${widget.providerName} — hujjatlaringiz administrator tomonidan tekshirilmoqda.'
                      : 'Hujjatlaringiz administrator tomonidan tekshirilmoqda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], height: 1.45),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tasdiqlangandan keyin profilingiz mijozlarga ko\'rinadi va panel to\'liq ochiladi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checking ? null : _checkStatus,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.refreshCw),
                    label: const Text('Holatni tekshirish'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('Bosh sahifaga'),
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
