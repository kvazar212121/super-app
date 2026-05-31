import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PlumberReportsWidget extends StatefulWidget {
  const PlumberReportsWidget({super.key});

  @override
  State<PlumberReportsWidget> createState() => _PlumberReportsWidgetState();
}

class _PlumberReportsWidgetState extends State<PlumberReportsWidget> with SingleTickerProviderStateMixin {
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
          'Tushumlar hisoboti',
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
              color: const Color(0xFF0EA5E9),
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
              _buildReportContent('Bugun', '920 000', [40, 60, 50, 80, 70, 90, 30], theme),
              _buildReportContent('Shu oy', '18 500 000', [60, 80, 70, 90, 100, 50, 80], theme),
              _buildReportContent('Shu yil', '210 000 000', [70, 90, 80, 60, 100, 50, 70], theme),
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
            'Xizmatlar bo\'yicha',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildServiceReportList(theme),
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
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
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
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.8),
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

  Widget _buildServiceReportList(ThemeData theme) {
    final items = [
      {'service': 'Kran almashtirish', 'count': '15', 'amount': '5 400 000'},
      {'service': 'Quvur ulash/almashtirish', 'count': '12', 'amount': '7 200 000'},
      {'service': 'Kanalizatsiya tozalash', 'count': '8', 'amount': '3 600 000'},
      {'service': 'Smesitel o\'rnatish', 'count': '10', 'amount': '4 300 000'},
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
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.droplets, size: 20, color: Color(0xFF0EA5E9)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['service']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${item['count']} chaqiruv',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
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
