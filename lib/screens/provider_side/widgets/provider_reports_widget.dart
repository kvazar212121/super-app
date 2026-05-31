import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';

class ProviderReportsWidget extends StatefulWidget {
  final String categoryKey;
  const ProviderReportsWidget({super.key, required this.categoryKey});

  @override
  State<ProviderReportsWidget> createState() => _ProviderReportsWidgetState();
}

class _ProviderReportsWidgetState extends State<ProviderReportsWidget>
    with SingleTickerProviderStateMixin {
  final _portal = ProviderPortalService();
  late TabController _tabController;
  static const _periods = ['daily', 'monthly', 'yearly'];
  static const _periodLabels = ['Kunlik', 'Oylik', 'Yillik'];

  Map<String, dynamic>? _daily;
  Map<String, dynamic>? _monthly;
  Map<String, dynamic>? _yearly;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _portal.getReport(widget.categoryKey, 'daily'),
        _portal.getReport(widget.categoryKey, 'monthly'),
        _portal.getReport(widget.categoryKey, 'yearly'),
      ]);
      _daily = results[0];
      _monthly = results[1];
      _yearly = results[2];
    } catch (_) {
      _daily = _monthly = _yearly = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reports = [_daily, _monthly, _yearly];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tushumlar hisoboti',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: _loadAll),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF6366F1),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
            tabs: _periodLabels.map((l) => Tab(text: l)).toList(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 520,
          child: TabBarView(
            controller: _tabController,
            children: List.generate(3, (i) => _buildReportContent(reports[i], _periodLabels[i], theme)),
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent(Map<String, dynamic>? data, String label, ThemeData theme) {
    if (data == null) {
      return const Center(child: Text('Hisobot yuklanmadi'));
    }
    final total = (data['total_revenue'] as num?)?.toDouble() ?? 0;
    final orders = data['total_orders'] as int? ?? 0;
    final chart = (data['chart'] as List<dynamic>? ?? []);
    final breakdown = (data['breakdown'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label jami tushum', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormat('#,###').format(total)} so\'m',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$orders ta buyurtma', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (chart.isNotEmpty) ...[
            Text('Grafik', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chart.take(7).map((c) {
                  final v = (c['value'] as num?)?.toDouble() ?? 0;
                  final max = chart.map((x) => (x['value'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);
                  final h = max > 0 ? (v / max) * 80 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: h.clamp(4, 80),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('Xizmatlar bo\'yicha', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Text('Ma\'lumot yo\'q')
          else
            ...breakdown.map((b) {
              final amount = (b['amount'] as num?)?.toDouble() ?? 0;
              final count = b['count'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text('${b['title']} ($count ta)')),
                    Text('${NumberFormat('#,###').format(amount)} so\'m',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
