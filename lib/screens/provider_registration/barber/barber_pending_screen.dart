import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/barber_portal_service.dart';
import '../../main_screen.dart';
import '../../provider_side/provider_theme.dart';
import 'package:super_app/l10n/locale_controller.dart';
import '../../../theme/lux_tokens.dart';

/// Usta xona egasi tasdiqlaguncha (arizani bekor qilish imkoniyati bilan).
class BarberPendingScreen extends StatefulWidget {
  final String shopName;

  const BarberPendingScreen({super.key, required this.shopName});

  @override
  State<BarberPendingScreen> createState() => _BarberPendingScreenState();
}

class _BarberPendingScreenState extends State<BarberPendingScreen> {
  bool _cancelling = false;

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        title: Text(
          'Arizani bekor qilish'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Sartaroshxonaga yuborgan so\'rovingizni bekor qilmoqchimisiz?'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Yo\'q'.tr,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(
              'Ha, bekor qilish'.tr,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cancelling = true);
    try {
      await BarberPortalService().cancelJoin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arizangiz bekor qilindi'.tr)),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'So\'rov yuborildi'.tr,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.shopName} xona egasi so\'rovingizni ko\'rib, qabul qiladi yoki rad etadi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: LuxTokens.textMuted, height: 1.45),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tasdiqlangandan keyin panelingiz ochiladi.'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: LuxTokens.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 36),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelling ? null : _cancelRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: _cancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                          )
                        : Text('Arizani bekor qilish'.tr),
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
