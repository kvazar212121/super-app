import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/provider_category_config.dart';
import '../../services/provider_portal_service.dart';
import 'widgets/provider_calendar_widget.dart';
import 'widgets/provider_reports_widget.dart';

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
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _todayOrders = [];
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _load();
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
      ]);
      _provider = results[0] as Map<String, dynamic>;
      _stats = results[1] as Map<String, dynamic>;
      _todayOrders = results[2] as List<Map<String, dynamic>>;
      _isActive = _provider?['is_active'] == true;
    } catch (e) {
      _error = 'Ma\'lumotlarni yuklab bo\'lmadi.\nRo\'yxatdan o\'tganingizni tekshiring.';
    }
    if (mounted) setState(() => _loading = false);
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
    switch (_selectedIndex) {
      case 1:
        return ProviderCalendarWidget(categoryKey: widget.config.categoryKey);
      case 2:
        return ProviderReportsWidget(categoryKey: widget.config.categoryKey);
      default:
        return _buildDashboard(theme, accent);
    }
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
            IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _load),
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
          Text(
            '${NumberFormat('#,###').format((o['price'] as num?) ?? 0)} so\'m',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color accent) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: const [
        NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Panel'),
        NavigationDestination(icon: Icon(LucideIcons.calendarDays), label: 'Kalendar'),
        NavigationDestination(icon: Icon(LucideIcons.chartBar), label: 'Hisobot'),
      ],
      indicatorColor: accent.withValues(alpha: 0.15),
    );
  }
}
