import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../config/provider_category_config.dart';
import '../models/service_order.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../screens/order_detail_screen.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../screens/provider_registration/provider_onboarding_screen.dart';
import '../screens/provider_registration/barber/barber_pending_screen.dart';
import '../screens/provider_registration/salon/salon_pending_screen.dart';
import '../services/provider_portal_service.dart';
import '../services/barber_portal_service.dart';
import '../services/salon_portal_service.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';
import '../l10n/locale_controller.dart';

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
      final all = await _portal.listMine();
      // Faqat kategoriyasi TO'G'RI (config'da mavjud) providerlar. Kategoriyasiz
      // yoki buzuq (orphaned, masalan eski "goo") yozuvlar hisobga olinmaydi —
      // shunda foydalanuvchi to'g'ridan-to'g'ri ro'yxatdan o'tishga yo'naltiriladi.
      _providers = all.where((p) {
        final key = (p['category_key'] as String?)?.trim();
        return key != null &&
            key.isNotEmpty &&
            ProviderCategoryConfig.byCategoryKey(key) != null;
      }).toList();
      if (_providers.isEmpty) {
        _barberStatus = await _barberPortal.getMyStatus();
        _salonStatus = await _salonPortal.getMyStatus();
      }
    } catch (_) {
      _providers = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  ProviderCategoryConfig? _resolveConfig(String? key) {
    if (key == null) return null;
    final k = key.trim();
    // categoryKey → registrationId fallback (probel/format farqlarini ham yutadi)
    return ProviderCategoryConfig.byCategoryKey(k) ??
        ProviderCategoryConfig.byRegistrationId(k);
  }

  void _openDashboard(Map<String, dynamic> provider) {
    final key = provider['category_key'] as String?;
    final config = _resolveConfig(key);
    if (config == null) {
      // Jim yiqilmasin — MARKAZDA dialog (pastki menyu ostida yashirinmaydi).
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: const Text('Panel ochilmadi'),
            content: Text(
              'Provider kategoriyangiz ilova sozlamasi bilan mos kelmadi.\n\n'
              'category_key: ${key ?? "null (kategoriya biriktirilmagan)"}\n'
              'nomi: ${provider['name'] ?? "-"}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    // Push emas — aktiv rejimni "provider"ga o'tkazamiz. RootShell qayta quriladi
    // va soha egasi panelini ko'rsatadi (rejim saqlanadi, qayta ochilganda tiklanadi).
    final nav = Navigator.of(context);
    context.read<AppProvider>().switchToProvider(config.categoryKey);
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
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
              'Panelni tanlang'.tr,
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
    // Tizim: AVVAL oddiy user bo'lib kirish (telefon raqami), KEYIN soha egasi
    // bo'lish. Login qilinmagan bo'lsa — provider onboarding xato bermasligi
    // uchun avval kirish/ro'yxat ekraniga o'tkazamiz.
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthGateScreen()),
      );
      // Kirgach — provider ro'yxatini qayta yuklaymiz
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        setState(() => _loading = true);
        await _load();
      }
      return;
    }
    if (_providers.isEmpty) {
      final status = _barberStatus?['status']?.toString();
      final role = _barberStatus?['role']?.toString();
      if (role == 'shop_employee' && status == 'pending') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarberPendingScreen(
              shopName:
                  _barberStatus?['shop_name']?.toString() ?? 'Sartaroshxona'.tr,
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
              salonName: _salonStatus?['salon_name']?.toString() ?? 'Salon'.tr,
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

    // Login qilingan bo'lsa — provider ma'lumoti yuklanmoqda
    if (auth.isAuthenticated && _loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // To'g'ri kategoriyali provider bo'lsagina "panel". Aks holda (login yo'q
    // yoki ro'yxatdan o'tmagan) — DOIM "Ro'yxatdan o'tish" tugmasi ko'rsatiladi
    // (hech qachon yashirilmaydi).
    final hasProvider = auth.isAuthenticated && _providers.isNotEmpty;

    final title = hasProvider
        ? 'Soha egasi paneli'.tr
        : 'Siz soha egasi bo\'lishni xohlaysizmi?'.tr;
    final subtitle = hasProvider
        ? '${_providers.length} ${'ta xizmat — buyurtmalar va statistika'.tr}'
        : 'Xizmat ko\'rsatuvchi sifatida ro\'yxatdan o\'ting — mijozlar sizni topadi.'
            .tr;
    final buttonLabel = hasProvider
        ? 'Panelga o\'tish'.tr
        : 'Ro\'yxatdan o\'tish'.tr;

    if (widget.compact) {
      return GlassSurface(
        onTap: _onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        opacity: 0.5,
        child: Row(
          children: [
            Icon(
              LucideIcons.briefcase,
              color: GlassTokens.primaryText(context),
            ),
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
            // Ro'yxatdan o'tmagan bo'lsa — aniq "Ro'yxatdan o'tish" chipi
            if (!hasProvider)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ro\'yxatdan o\'tish'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: GlassTokens.secondaryText(context),
              ),
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
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: GlassTokens.primaryText(context),
            ),
          ),
          if (!hasProvider) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: GlassTokens.secondaryText(context),
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ],
          // Provider-ga tegishli alert buyurtmalar (Kelmadi, Nizo)
          if (hasProvider) ..._buildProviderAlerts(context),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _onTap, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProviderAlerts(BuildContext context) {
    final alerts = context.watch<AppProvider>().providerAlertOrders;
    if (alerts.isEmpty) return [];
    return [
      const SizedBox(height: 14),
      ...alerts.map((order) => _ProviderAlertTile(order: order)),
    ];
  }
}

/// Ixcham alert tile — "Kelmadi" / "Nizo" statusli buyurtmalar uchun.
class _ProviderAlertTile extends StatelessWidget {
  final ServiceOrder order;
  const _ProviderAlertTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusLabel = order.statusText;
    final statusColor = switch (order.status) {
      OrderStatus.pending => const Color(0xFFF59E0B),
      OrderStatus.accepted => const Color(0xFF3B82F6),
      OrderStatus.onTheWay => const Color(0xFF0EA5E9),
      OrderStatus.arrived => const Color(0xFF8B5CF6),
      OrderStatus.preparing => const Color(0xFFF59E0B),
      OrderStatus.inProgress => const Color(0xFFA855F7),
      OrderStatus.noShow => const Color(0xFF6B7280),
      OrderStatus.disputed => const Color(0xFFDC2626),
      _ => const Color(0xFF6B7280),
    };

    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(order.date.day)}.${two(order.date.month)} ${two(order.date.hour)}:${two(order.date.minute)}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: order.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${order.serviceName} — ${order.price.toStringAsFixed(0)} ${'so\'m'.tr}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GlassTokens.primaryText(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 11,
                color: GlassTokens.secondaryText(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: GlassTokens.secondaryText(context),
            ),
          ],
        ),
      ),
    );
  }
}
