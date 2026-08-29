import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/locale_controller.dart';
import '../services/api_service.dart';
import '../theme/glass_tokens.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../theme/lux_tokens.dart';

/// Oilaviy moliya — er-xotin (yoki oila) bitta byudjetni QR orqali ulaydi.
class FamilyFinanceScreen extends StatefulWidget {
  const FamilyFinanceScreen({super.key});

  @override
  State<FamilyFinanceScreen> createState() => _FamilyFinanceScreenState();
}

class _FamilyFinanceScreenState extends State<FamilyFinanceScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _group;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await _api.getFinanceGroup();
      if (mounted) {
        setState(() {
        _group = g;
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showInviteQr() async {
    setState(() => _busy = true);
    try {
      final g = await _api.createFinanceInvite();
      if (!mounted) return;
      setState(() => _group = g);
      final code = g['invite_code'] as String;
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bu QR kodni juftingiz skanerlaydi'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: GlassTokens.primaryText(context),
                  )),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LuxTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 16),
              Text('${'Kod'.tr}: $code',
                  style: TextStyle(
                    fontSize: 13,
                    color: GlassTokens.secondaryText(context),
                  )),
            ],
          ),
        ),
      );
    } catch (_) {
      _toast('Xatolik'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final g = await _api.joinFinanceGroup(code.trim());
      if (!mounted) return;
      setState(() => _group = g);
      _toast('Oilaviy hisobga ulandingiz ✅'.tr);
    } catch (e) {
      _toast(e.toString().contains('chiqing')
          ? 'Avval joriy guruhdan chiqing'.tr
          : 'Kod noto\'g\'ri yoki eskirgan'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Guruhdan chiqish'.tr),
        content: Text('Oilaviy hisobdan chiqasizmi? Yozuvlaringiz shaxsiy hisobga qaytadi.'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Bekor qilish'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Chiqish'.tr, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _api.leaveFinanceGroup();
      if (mounted) setState(() => _group = null);
    } catch (_) {
      _toast('Xatolik'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Oilaviy byudjet'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 16),
                if (_group != null) _membersCard() else _actionsCard(),
              ],
            ),
    );
  }

  Widget _headerCard() {
    final inGroup = _group != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: inGroup
              ? const [Color(0xFF059669), Color(0xFF10B981)]
              : const [Color(0xFFC9A227), Color(0xFFE3C766)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.users, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inGroup ? 'Umumiy hisob faol'.tr : 'Oilaviy byudjet'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  inGroup
                      ? 'Kirim/chiqim ikkalangizda birga hisoblanadi'.tr
                      : 'Juftingiz bilan bitta byudjetni yuriting'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    return Column(
      children: [
        _actionTile(
          icon: LucideIcons.qrCode,
          color: const Color(0xFFC9A227),
          title: 'QR kod ko\'rsatish'.tr,
          subtitle: 'Juftingiz sizning QR kodingizni skanerlaydi'.tr,
          onTap: _busy ? null : _showInviteQr,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: LucideIcons.scanLine,
          color: const Color(0xFFB8921F),
          title: 'QR kod skanerlash'.tr,
          subtitle: 'Juftingizning QR kodini skanerlab ulaning'.tr,
          onTap: _busy ? null : _scanQr,
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      opacity: 0.55,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: GlassTokens.primaryText(context),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlassTokens.secondaryText(context),
                    )),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: GlassTokens.secondaryText(context)),
        ],
      ),
    );
  }

  Widget _membersCard() {
    final members = (_group?['members'] as List<dynamic>? ?? []);
    return Column(
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(16),
          opacity: 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A\'zolar'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: GlassTokens.secondaryText(context),
                    fontSize: 13,
                  )),
              const SizedBox(height: 10),
              ...members.map((m) {
                final mm = Map<String, dynamic>.from(m as Map);
                final isOwner = mm['is_owner'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFC9A227).withValues(alpha: 0.15),
                        child: Text(
                          (mm['name'] as String? ?? '?').characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFC9A227),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(mm['name'] as String? ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: GlassTokens.primaryText(context),
                          )),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A227).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Egasi'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC9A227),
                              )),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Boshqa a'zoni qo'shish uchun yana QR
        _actionTile(
          icon: LucideIcons.userPlus,
          color: const Color(0xFFC9A227),
          title: 'Yana a\'zo qo\'shish'.tr,
          subtitle: 'QR kod ko\'rsatib yangi a\'zoni ulang'.tr,
          onTap: _busy ? null : _showInviteQr,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _leave,
            icon: const Icon(LucideIcons.logOut, color: Color(0xFFEF4444), size: 18),
            label: Text('Guruhdan chiqish'.tr,
                style: const TextStyle(color: Color(0xFFEF4444))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// QR skaner ekrani — kod topilganда Navigator.pop(code).
class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR kodni skanerlang'.tr)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final code = barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            _handled = true;
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
