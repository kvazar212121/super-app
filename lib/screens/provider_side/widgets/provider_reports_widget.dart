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
            const Text(
              'Tushumlar hisoboti',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(icon: const Icon(LucideIcons.refreshCw, color: Colors.black), onPressed: _loadAll),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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

    final totalLeads = data['total_leads'] as int? ?? 0;
    final completedOrders = data['completed_orders'] as int? ?? 0;
    final leadFeeCharged = (data['lead_fee_charged'] as num?)?.toDouble() ?? 0.0;
    final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black26, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label jami tushum', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormat('#,###').format(total)} so\'m',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('$orders ta buyurtma', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Mijozlar (Leads)',
                  '$totalLeads ta',
                  LucideIcons.users,
                  Colors.blue.shade900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Tugallangan',
                  '$completedOrders ta',
                  LucideIcons.checkCircle2,
                  Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Xizmat haqi',
                  '${NumberFormat('#,###').format(leadFeeCharged)} so\'m',
                  LucideIcons.banknote,
                  Colors.amber.shade900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Hisob balansi',
                  '${NumberFormat('#,###').format(balance)} so\'m',
                  LucideIcons.wallet,
                  balance < 0 ? Colors.red.shade900 : Colors.teal.shade900,
                  subtitle: balance < 0 ? 'Balans manfiy!' : 'Balans yetarli',
                ),
              ),
            ],
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 1),
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
          const Text('Xizmatlar bo\'yicha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Text('Ma\'lumot yo\'q', style: TextStyle(color: Colors.black87))
          else
            ...breakdown.map((b) {
              final amount = (b['amount'] as num?)?.toDouble() ?? 0;
              final count = b['count'] as int? ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('${b['title']} ($count ta)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                    Text('${NumberFormat('#,###').format(amount)} so\'m',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
