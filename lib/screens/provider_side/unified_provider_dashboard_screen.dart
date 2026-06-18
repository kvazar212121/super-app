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
import '../../services/call_history_service.dart';
import '../../services/call_service.dart';
import '../calls/call_screen.dart';

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
  bool _isPaused = false;

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

  int get _calendarIndex => 1;
  int get _settingsIndex => 2;
  int get _callsIndex => _hasVenueSettings ? 3 : 2;
  int get _reportsIndex => _hasVenueSettings ? 4 : 3;

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
      _isPaused = _provider?['is_paused'] == true;
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

  Future<void> _togglePaused(bool v) async {
    setState(() => _isPaused = v);
    try {
      await _portal.setPaused(widget.config.categoryKey, v);
    } catch (_) {
      if (mounted) setState(() => _isPaused = !v);
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
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: Text('${widget.config.title} paneli'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.circleAlert, size: 48, color: Colors.black),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Qayta urinish'),
                ),
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

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          outline: Colors.black,
          outlineVariant: Colors.black54,
        ),
        textTheme: Typography.material2021().black,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: (_selectedIndex == _callsIndex)
              ? _buildBody(theme, Colors.black)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildBody(theme, Colors.black),
                ),
        ),
        bottomNavigationBar: _buildBottomNav(Colors.black),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, Color accent) {
    if (_selectedIndex == _calendarIndex) {
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
    if (_selectedIndex == _callsIndex) {
      return _buildCallsAndBlockTab(theme, accent);
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Icon(widget.config.icon, color: Colors.black, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black, size: 16),
                      const SizedBox(width: 4),
                      Text('$rating ($reviews sharh)', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Colors.black),
                onPressed: _refreshDashboard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              Text(
                _isActive ? 'Hozir ishlayapman' : 'Faol emas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isActive,
                onChanged: _toggleActive,
                activeColor: Colors.black,
                activeTrackColor: Colors.black12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                _isPaused ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                color: Colors.black,
              ),
              const SizedBox(width: 12),
              const Text(
                'Uzoq muddatli tanaffus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isPaused,
                onChanged: _togglePaused,
                activeColor: Colors.black,
                activeTrackColor: Colors.black12,
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(time, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o['user_name'] as String? ?? 'Mijoz',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 16),
                ),
                Text(
                  o['service_name'] as String? ?? '',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format((o['price'] as num?) ?? 0)} so\'m',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 15),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
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
        icon: Icon(LucideIcons.phone),
        label: 'Muloqot',
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
      backgroundColor: Colors.white,
      indicatorColor: Colors.black12,
    );
  }

  Widget _buildCallsAndBlockTab(ThemeData theme, Color accent) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Qo\'ng\'iroqlar'),
                Tab(text: 'Bloklanganlar'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildCallHistoryList(theme, accent),
            _buildBlockedUsersList(theme, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildCallHistoryList(ThemeData theme, Color accent) {
    return ListenableBuilder(
      listenable: CallHistoryService(),
      builder: (context, _) {
        final logs = CallHistoryService().history;
        if (logs.isEmpty) {
          return const Center(
            child: Text(
              'Qo\'ng\'iroqlar tarixi bo\'sh',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(log.timestamp);

            IconData iconData;
            Color iconColor;
            String statusText = '';

            if (log.status == 'connected') {
              iconData = log.isIncoming ? LucideIcons.phoneIncoming : LucideIcons.phoneOutgoing;
              iconColor = Colors.green;
              statusText = log.isIncoming ? 'Kiruvchi' : 'Chiquvchi';
            } else if (log.status == 'declined') {
              iconData = LucideIcons.phoneOff;
              iconColor = Colors.orange;
              statusText = 'Rad etilgan';
            } else if (log.status == 'cancelled') {
              iconData = LucideIcons.phoneOff;
              iconColor = Colors.grey;
              statusText = 'Bekor qilingan';
            } else {
              iconData = log.isIncoming ? LucideIcons.phoneMissed : LucideIcons.phoneOff;
              iconColor = Colors.red;
              statusText = log.isIncoming ? 'Javobsiz' : 'Ulanmagan';
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              title: Text(
                log.userName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              subtitle: Text(
                '$statusText • $dateStr\nDavomiyligi: ${log.duration}',
                style: const TextStyle(color: Colors.black87),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.phone, color: Colors.green),
                    onPressed: () {
                      CallService().startCall(log.userId, log.userName);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CallScreen(isIncoming: false),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.ban, color: Colors.red),
                    onPressed: () {
                      _showBlockDialog(log.userId, log.userName);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBlockDialog(int userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$userName bloklansinmi?'),
        content: const Text('Ushbu foydalanuvchidan keladigan qo\'ng\'iroqlar avtomatik rad etiladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bekor qilish', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              CallHistoryService().blockUser(userId, userName);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$userName bloklandi')),
              );
            },
            child: const Text('Bloklash', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList(ThemeData theme, Color accent) {
    return ListenableBuilder(
      listenable: CallHistoryService(),
      builder: (context, _) {
        final blocked = CallHistoryService().blocked;
        if (blocked.isEmpty) {
          return const Center(
            child: Text(
              'Bloklangan foydalanuvchilar yo\'q',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: blocked.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = blocked[index];
            final dateStr = DateFormat('dd.MM.yyyy').format(user.blockedAt);

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: const Icon(LucideIcons.ban, color: Colors.red, size: 20),
              ),
              title: Text(
                user.userName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              subtitle: Text(
                'Bloklangan sana: $dateStr',
                style: const TextStyle(color: Colors.black87),
              ),
              trailing: FilledButton(
                onPressed: () {
                  CallHistoryService().unblockUser(user.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user.userName} blokdan chiqarildi')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                child: const Text('Ochish'),
              ),
            );
          },
        );
      },
    );
  }
}
