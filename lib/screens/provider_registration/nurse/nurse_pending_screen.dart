import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/provider_category_config.dart';
import '../../main_screen.dart';
import '../../provider_side/provider_theme.dart';
import '../../provider_side/unified_provider_dashboard_screen.dart';
import '../../../services/provider_portal_service.dart';
import 'package:super_app/l10n/locale_controller.dart';

class NursePendingScreen extends StatefulWidget {
  final String providerName;

  const NursePendingScreen({super.key, required this.providerName});

  @override
  State<NursePendingScreen> createState() => _NursePendingScreenState();
}

class _NursePendingScreenState extends State<NursePendingScreen> {
  final _portal = ProviderPortalService();
  bool _checking = false;
  String? _statusMessage;

  Future<void> _checkStatus() async {
    setState(() {
      _checking = true;
      _statusMessage = null;
    });
    try {
      final data = await _portal.getMe('hamshira');
      final active = data['is_active'] == true;
      final meta =
          data['metadata'] as Map<String, dynamic>? ??
          data['metadata_json'] as Map<String, dynamic>? ??
          {};
      final rejected = meta['verification_status'] == 'rejected';
      final verified = meta['verification_status'] == 'verified';

      if (!mounted) return;
      if (rejected) {
        setState(() {
          _statusMessage =
              'Ariza rad etildi. Qo\'llab-quvvatlash xizmatiga murojaat qiling.';
        });
        return;
      }
      if (active && verified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedProviderDashboardScreen(
              config: ProviderCategoryConfig.nurse,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hali tasdiqlanmagan. Biroz kuting.'.tr)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Holatni tekshirib bo\'lmadi'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2563EB);
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
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.stethoscope,
                    size: 48,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text('So\'rov yuborildi'.tr,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.providerName.isNotEmpty
                      ? '${widget.providerName} — profilingiz tekshirilmoqda.'
                      : 'Profilingiz tekshirilmoqda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], height: 1.45),
                ),
                const SizedBox(height: 8),
                Text('Tasdiqlangandan keyin mijozlar uyga chaqirish orqali xizmat buyurtma qiladi.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _checking ? null : _checkStatus,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(LucideIcons.refreshCw),
                    label: Text('Holatni tekshirish'.tr),
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
