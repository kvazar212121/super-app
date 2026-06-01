import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/provider_category_config.dart';
import '../../services/provider_portal_service.dart';
import 'widgets/provider_calendar_widget.dart';
import 'widgets/provider_barber_team_widget.dart';
import 'widgets/provider_salon_team_widget.dart';
import 'widgets/provider_football_settings_widget.dart';
import 'widgets/provider_cleaning_settings_widget.dart';
import 'widgets/provider_master_settings_widget.dart';
import 'widgets/provider_electrician_settings_widget.dart';
import 'widgets/provider_plumber_settings_widget.dart';
import 'widgets/provider_courier_settings_widget.dart';
import 'widgets/provider_auto_settings_widget.dart';
import 'widgets/provider_auto_workshop_settings_widget.dart';
import 'widgets/provider_ac_settings_widget.dart';
import 'widgets/provider_nanny_settings_widget.dart';
import 'widgets/provider_tutor_settings_widget.dart';
import 'widgets/provider_pending_orders_widget.dart';
import '../provider_registration/nanny/nanny_pending_screen.dart';
import '../provider_registration/tutor/tutor_pending_screen.dart';
import '../provider_registration/disinfection/disinfection_pending_screen.dart';
import '../provider_registration/massage/massage_pending_screen.dart';
import '../provider_registration/nurse/nurse_pending_screen.dart';
import '../provider_registration/dental/dental_pending_screen.dart';
import '../provider_registration/event/event_pending_screen.dart';
import 'widgets/provider_disinfection_settings_widget.dart';
import 'widgets/provider_massage_settings_widget.dart';
import 'widgets/provider_nurse_settings_widget.dart';
import 'widgets/provider_dental_settings_widget.dart';
import 'widgets/provider_event_settings_widget.dart';
import 'widgets/provider_reports_widget.dart';
import 'widgets/provider_venue_settings_widget.dart';

/// Barcha soha egasi panellari — DB/API dan ma'lumot oladi.
class UnifiedProviderDashboardScreen extends StatefulWidget {
  final ProviderCategoryConfig config;

  const UnifiedProviderDashboardScreen({
    super.key,
    required this.config,
  });

  @override
  State<UnifiedProviderDashboardScreen> createState() =>
      _UnifiedProviderDashboardScreenState();
}

class _UnifiedProviderDashboardScreenState
    extends State<UnifiedProviderDashboardScreen> {
  final _portal = ProviderPortalService();
  final _pendingKey = GlobalKey<ProviderPendingOrdersWidgetState>();

  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;
  int _pendingCount = 0;
  Timer? _pollTimer;

  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _todayOrders = [];
  bool _isActive = true;

  bool get _hasVenueSettings {
    final k = widget.config.categoryKey;
    return k == 'sartarosh' || k == 'salon' || k == 'futbol' || k == 'tozalash' || k == 'usta' || k == 'elektrik' || k == 'santexnik' || k == 'kuryerlik' || k == 'avtoYordam' || k == 'konditsioner' || k == 'enaga' || k == 'repetitor' || k == 'dezinfeksiya' || k == 'massajHijoma' || k == 'hamshira' || k == 'stomatologiya' || k == 'tadbirlar';
  }

  bool get _isBarberShopOwner {
    if (widget.config.categoryKey != 'sartarosh') return false;
    final meta = _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>?;
    final role = meta?['barber_role'];
    return role == 'shop_owner' ||
        (role == null && meta?['type'] == 'barber_shop');
  }

  String? get _barberInviteCode {
    final meta = _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>?;
    return meta?['invite_code']?.toString();
  }

  bool get _isSalonOwner {
    if (widget.config.categoryKey != 'salon') return false;
    final meta = _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>?;
    final role = meta?['salon_role'];
    return role == 'salon_owner' ||
        (role == null && meta?['type'] == 'beauty_salon');
  }

  String? get _salonInviteCode {
    final meta = _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>?;
    return meta?['invite_code']?.toString();
  }

  bool get _isAutoWorkshop {
    if (widget.config.categoryKey != 'avtoYordam') return false;
    final meta = _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>?;
    return meta?['type'] == 'auto_workshop' || meta?['auto_role'] == 'workshop';
  }

  bool get _isEducationCenter {
    if (widget.config.categoryKey != 'repetitor') return false;
    final meta = _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>?;
    return meta?['type'] == 'education_center' || meta?['tutor_role'] == 'center';
  }

  int get _reportsIndex => _hasVenueSettings ? 3 : 2;
  int get _settingsIndex => 2;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollPending());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final key = widget.config.categoryKey;
      final results = await Future.wait([
        _portal.getMe(key),
        _portal.getStats(key),
        _portal.getTodayOrders(key),
        _portal.getPendingOrders(key),
      ]);
      _provider = results[0] as Map<String, dynamic>;
      _stats = results[1] as Map<String, dynamic>;
      _todayOrders = results[2] as List<Map<String, dynamic>>;
      _pendingCount = (results[3] as List).length;
      _isActive = _provider?['is_active'] == true;
    } catch (e) {
      _error = 'Ma\'lumotlarni yuklab bo\'lmadi.\nRo\'yxatdan o\'tganingizni tekshiring.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pollPending() async {
    if (!mounted) return;
    try {
      final prev = _pendingCount;
      final pending = await _portal.getPendingOrders(widget.config.categoryKey);
      if (!mounted) return;
      if (pending.length > prev && prev >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pending.length - prev} ta yangi buyurtma!'),
            action: SnackBarAction(
              label: 'Ko\'rish',
              onPressed: () => setState(() => _selectedIndex = 0),
            ),
          ),
        );
      }
      setState(() => _pendingCount = pending.length);
      _pendingKey.currentState?.load();
    } catch (_) {}
  }

  Future<void> _refreshDashboard() async {
    await _load();
    _pendingKey.currentState?.load();
  }

  Future<void> _toggleActive(bool v) async {
    setState(() => _isActive = v);
    try {
      await _portal.setActive(widget.config.categoryKey, v);
    } catch (_) {
      if (mounted) setState(() => _isActive = !v);
    }
  }

  String _formatMoney(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.config.accentColor;

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: accent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.config.title} paneli')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circleAlert, size: 48, color: accent),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Qayta urinish')),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.config.categoryKey == 'enaga' && !_isActive) {
      return NannyPendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }
    if (widget.config.categoryKey == 'repetitor' && !_isActive) {
      return TutorPendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }
    if (widget.config.categoryKey == 'dezinfeksiya' && !_isActive) {
      return DisinfectionPendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }
    if (widget.config.categoryKey == 'massajHijoma' && !_isActive) {
      return MassagePendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }
    if (widget.config.categoryKey == 'hamshira' && !_isActive) {
      return NursePendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }
    if (widget.config.categoryKey == 'stomatologiya' && !_isActive) {
      return DentalPendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }
    if (widget.config.categoryKey == 'tadbirlar' && !_isActive) {
      return EventPendingScreen(
        providerName: _provider?['name'] as String? ?? widget.config.title,
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildBody(theme, accent),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(accent),
    );
  }

  Widget _buildBody(ThemeData theme, Color accent) {
    if (_selectedIndex == 1) {
      return ProviderCalendarWidget(
        categoryKey: widget.config.categoryKey,
        accent: accent,
      );
    }
    if (_hasVenueSettings && _selectedIndex == _settingsIndex) {
      if (widget.config.categoryKey == 'futbol') {
        return ProviderFootballSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'tozalash') {
        return ProviderCleaningSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'usta') {
        return ProviderMasterSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'elektrik') {
        return ProviderElectricianSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'santexnik') {
        return ProviderPlumberSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'kuryerlik') {
        return ProviderCourierSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'avtoYordam') {
        if (_isAutoWorkshop) {
          return ProviderAutoWorkshopSettingsWidget(
            categoryKey: widget.config.categoryKey,
            accent: accent,
          );
        }
        return ProviderAutoSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'konditsioner') {
        return ProviderAcSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'enaga') {
        return ProviderNannySettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'repetitor') {
        if (_isEducationCenter) {
          return ProviderVenueSettingsWidget(
            categoryKey: widget.config.categoryKey,
            accent: accent,
            staffLabel: 'O\'qituvchi',
            staffMetadataKey: 'teachers',
          );
        }
        return ProviderTutorSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'dezinfeksiya') {
        return ProviderDisinfectionSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'massajHijoma') {
        return ProviderMassageSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'hamshira') {
        return ProviderNurseSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'stomatologiya') {
        return ProviderDentalSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      if (widget.config.categoryKey == 'tadbirlar') {
        return ProviderEventSettingsWidget(
          categoryKey: widget.config.categoryKey,
          accent: accent,
        );
      }
      return ProviderVenueSettingsWidget(
        categoryKey: widget.config.categoryKey,
        accent: accent,
        staffLabel: widget.config.categoryKey == 'salon' ? 'Mutaxassis' : 'Usta',
        staffMetadataKey: widget.config.categoryKey == 'salon' ? 'staff' : 'barbers',
      );
    }
    if (_selectedIndex == _reportsIndex) {
      return ProviderReportsWidget(categoryKey: widget.config.categoryKey);
    }
    return _buildDashboard(theme, accent);
  }

  Widget _buildDashboard(ThemeData theme, Color accent) {
    final name = _provider?['name'] as String? ?? widget.config.title;
    final rating = (_provider?['rating'] as num?)?.toDouble() ?? 0;
    final reviews = _provider?['review_count'] as int? ?? 0;
    final ordersToday = _stats?['orders_today'] as int? ?? 0;
    final revenueMonth = (_stats?['revenue_month'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: accent.withValues(alpha: 0.1),
              child: Icon(widget.config.icon, color: accent, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('$rating ($reviews sharh)', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _refreshDashboard,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isActive
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
                color: _isActive ? const Color(0xFF10B981) : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                _isActive ? 'Hozir ishlayapman' : 'Tanaffusda',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isActive ? const Color(0xFF10B981) : Colors.grey,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isActive,
                onChanged: _toggleActive,
                activeColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ProviderPendingOrdersWidget(
          key: _pendingKey,
          categoryKey: widget.config.categoryKey,
          accent: accent,
          onChanged: _refreshDashboard,
        ),
        if (_pendingCount > 0) const SizedBox(height: 16),
        if (_isBarberShopOwner) ...[
          ProviderBarberTeamWidget(accent: accent, inviteCode: _barberInviteCode),
          const SizedBox(height: 24),
        ],
        if (_isSalonOwner) ...[
          ProviderSalonTeamWidget(accent: accent, inviteCode: _salonInviteCode),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Bugungi buyurtmalar',
                '$ordersToday',
                LucideIcons.shoppingBag,
                accent,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _summaryCard(
                'Oylik daromad',
                _formatMoney(revenueMonth),
                LucideIcons.banknote,
                accent,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Bugungi buyurtmalar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_todayOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Bugun buyurtmalar yo\'q',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _orderTile(_todayOrders[i], theme, accent),
          ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color accent,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> o, ThemeData theme, Color accent) {
    final time = o['date'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(o['date'] as String))
        : '—';
    final status = o['status'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o['user_name'] as String? ?? 'Mijoz',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  o['service_name'] as String? ?? '',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format((o['price'] as num?) ?? 0)} so\'m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_statusLabel(status), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Kutilmoqda';
      case 'confirmed':
        return 'Tasdiqlangan';
      case 'in_progress':
        return 'Jarayonda';
      case 'completed':
        return 'Bajarildi';
      case 'cancelled':
        return 'Bekor qilindi';
      default:
        return status;
    }
  }

  Widget _buildBottomNav(Color accent) {
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: Badge(
          isLabelVisible: _pendingCount > 0,
          label: Text('$_pendingCount'),
          child: const Icon(LucideIcons.layoutDashboard),
        ),
        label: 'Panel',
      ),
      const NavigationDestination(
        icon: Icon(LucideIcons.calendarDays),
        label: 'Kalendar',
      ),
      if (_hasVenueSettings)
        const NavigationDestination(
          icon: Icon(LucideIcons.settings),
          label: 'Sozlamalar',
        ),
      const NavigationDestination(
        icon: Icon(LucideIcons.chartBar),
        label: 'Hisobot',
      ),
    ];

    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: destinations,
      indicatorColor: accent.withValues(alpha: 0.15),
    );
  }
}
