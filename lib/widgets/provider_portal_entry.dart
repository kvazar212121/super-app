import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../config/provider_category_config.dart';
import '../providers/auth_provider.dart';
import '../screens/provider_registration/provider_onboarding_screen.dart';
import '../screens/provider_side/unified_provider_dashboard_screen.dart';
import '../screens/provider_registration/barber/barber_pending_screen.dart';
import '../screens/provider_registration/salon/salon_pending_screen.dart';
import '../services/provider_portal_service.dart';
import '../services/barber_portal_service.dart';
import '../services/salon_portal_service.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

/// Soha egasi paneliga kirish yoki ro'yxatdan o'tish.
class ProviderPortalEntry extends StatefulWidget {
  final bool compact;

  const ProviderPortalEntry({super.key, this.compact = false});

  @override
  State<ProviderPortalEntry> createState() => _ProviderPortalEntryState();
}

class _ProviderPortalEntryState extends State<ProviderPortalEntry> {
  final _portal = ProviderPortalService();
  final _barberPortal = BarberPortalService();
  final _salonPortal = SalonPortalService();
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _barberStatus;
  Map<String, dynamic>? _salonStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      _providers = await _portal.listMine();
      if (_providers.isEmpty) {
        _barberStatus = await _barberPortal.getMyStatus();
        _salonStatus = await _salonPortal.getMyStatus();
      }
    } catch (_) {
      _providers = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openDashboard(Map<String, dynamic> provider) {
    final key = provider['category_key'] as String?;
    if (key == null) return;
    final config = ProviderCategoryConfig.byCategoryKey(key);
    if (config == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProviderDashboardScreen(config: config),
      ),
    );
  }

  void _openOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProviderOnboardingScreen()),
    );
  }

  void _pickProvider() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassSurface(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        borderRadius: GlassTokens.radiusXl,
        opacity: 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Panelni tanlang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(ctx),
              ),
            ),
            const SizedBox(height: 12),
            ..._providers.map((p) {
              final key = p['category_key'] as String? ?? '';
              final config = ProviderCategoryConfig.byCategoryKey(key);
              return ListTile(
                leading: Icon(config?.icon ?? LucideIcons.briefcase),
                title: Text(p['name']?.toString() ?? 'Provider'),
                subtitle: Text(config?.title ?? key),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDashboard(p);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _onTap() async {
    if (_providers.isEmpty) {
      final status = _barberStatus?['status']?.toString();
      final role = _barberStatus?['role']?.toString();
      if (role == 'shop_employee' && status == 'pending') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarberPendingScreen(
              shopName: _barberStatus?['shop_name']?.toString() ?? 'Sartaroshxona',
            ),
          ),
        );
        return;
      }
      final salonRole = _salonStatus?['role']?.toString();
      final salonStatus = _salonStatus?['status']?.toString();
      if (salonRole == 'salon_employee' && salonStatus == 'pending') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SalonPendingScreen(
              salonName: _salonStatus?['salon_name']?.toString() ?? 'Salon',
            ),
          ),
        );
        return;
      }
      _openOnboarding();
      return;
    }
    if (_providers.length == 1) {
      _openDashboard(_providers.first);
      return;
    }
    _pickProvider();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return widget.compact ? const SizedBox.shrink() : _buildGuestCard(context);
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final hasProvider = _providers.isNotEmpty;
    final title = hasProvider ? 'Soha egasi paneli' : 'Siz qaysi soha egasisiz?';
    final subtitle = hasProvider
        ? '${_providers.length} ta xizmat — buyurtmalar va statistika'
        : 'Biz sizni ushbu platformaga qo\'shamiz — mijozlar sizni topadi.';
    final buttonLabel =
        hasProvider ? 'Panelga o\'tish' : 'Usta / xizmat sifatida qo\'shilish';

    if (widget.compact) {
      return GlassSurface(
        onTap: _onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        opacity: 0.5,
        child: Row(
          children: [
            Icon(LucideIcons.briefcase, color: GlassTokens.primaryText(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: GlassTokens.secondaryText(context)),
          ],
        ),
      );
    }

    return GlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: GlassTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1),
                  ),
                ),
                child: const Icon(
                  LucideIcons.briefcase,
                  color: Color(0xFF6366F1),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _onTap, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(20),
      borderRadius: GlassTokens.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soha egasi bo\'lish',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xizmat ko\'rsatuvchi sifatida ro\'yxatdan o\'tish uchun avval kiring.',
            style: TextStyle(color: GlassTokens.secondaryText(context), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: _openOnboarding, child: const Text('Batafsil')),
          ),
        ],
      ),
    );
  }
}
