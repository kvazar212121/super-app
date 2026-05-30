import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EventsReportsWidget extends StatefulWidget {
  const EventsReportsWidget({super.key});

  @override
  State<EventsReportsWidget> createState() => _EventsReportsWidgetState();
}

class _EventsReportsWidgetState extends State<EventsReportsWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tadbirlar hisoboti',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
              color: const Color(0xFFE91E63),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Kunlik'),
              Tab(text: 'Oylik'),
              Tab(text: 'Yillik'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportContent('Bugun', '2 500 000', [40, 70, 50, 90, 60, 80, 30], theme),
              _buildReportContent('Shu oy', '45 800 000', [60, 40, 80, 50, 70, 90, 60], theme),
              _buildReportContent('Shu yil', '520 000 000', [70, 90, 50, 80, 60, 40, 70], theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent(String period, String total, List<double> chartData, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalCard(period, total, theme),
          const SizedBox(height: 32),
          Text(
            'Grafik ko\'rinishi',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSimpleChart(chartData, theme),
          const SizedBox(height: 32),
          Text(
            'Tadbir turi bo\'yicha',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildReportList(theme),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String period, String total, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$period jami tushum',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$total so\'m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 4),
              const Text(
                '+22% o\'tgan davrga nisbatan',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<double> data, ThemeData theme) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((value) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 25,
                height: value * 1.2,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Dsh', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportList(ThemeData theme) {
    final items = [
      {'title': "To'y rejissyor (8 ta)", 'amount': '1 200 000', 'icon': LucideIcons.bell},
      {'title': "Tug'ilgan kun (12 ta)", 'amount': '420 000', 'icon': LucideIcons.cakeSlice},
      {'title': 'Korporativ (4 ta)', 'amount': '600 000', 'icon': LucideIcons.briefcase},
      {'title': 'Dam olish joyi (6 ta)', 'amount': '280 000', 'icon': LucideIcons.treePine},
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, size: 20, color: const Color(0xFFE91E63)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${item['amount']} so\'m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
