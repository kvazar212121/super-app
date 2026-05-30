import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NurseReportsWidget extends StatefulWidget {
  const NurseReportsWidget({super.key});

  @override
  State<NurseReportsWidget> createState() => _NurseReportsWidgetState();
}

class _NurseReportsWidgetState extends State<NurseReportsWidget> with SingleTickerProviderStateMixin {
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
          'Xizmatlar hisoboti',
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
              color: const Color(0xFFE53935),
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
              _buildReportContent('Bugun', '850 000', [40, 70, 50, 90, 60, 80, 30], theme),
              _buildReportContent('Shu oy', '18 200 000', [60, 40, 80, 50, 70, 90, 60], theme),
              _buildReportContent('Shu yil', '195 400 000', [70, 90, 50, 80, 60, 40, 70], theme),
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
            'Xizmat turi bo\'yicha',
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
          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.3),
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
                '+18% o\'tgan davrga nisbatan',
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
                  color: const Color(0xFFE53935).withValues(alpha: 0.8),
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
      {'title': "In'ektsiya (30 ta)", 'amount': '150 000', 'icon': LucideIcons.syringe},
      {'title': 'Qon tahlili (15 ta)', 'amount': '120 000', 'icon': LucideIcons.testTube},
      {'title': 'Dori berish (20 ta)', 'amount': '80 000', 'icon': LucideIcons.pill},
      {'title': 'Tomchilatish (10 ta)', 'amount': '120 000', 'icon': LucideIcons.flaskConical},
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
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, size: 20, color: const Color(0xFFE53935)),
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
