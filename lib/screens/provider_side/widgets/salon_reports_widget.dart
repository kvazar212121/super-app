import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SalonReportsWidget extends StatefulWidget {
  const SalonReportsWidget({super.key});

  @override
  State<SalonReportsWidget> createState() => _SalonReportsWidgetState();
}

class _SalonReportsWidgetState extends State<SalonReportsWidget> with SingleTickerProviderStateMixin {
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
              color: const Color(0xFFEC4899),
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
              _buildReportContent('Bugun', '1 800 000', [50, 70, 60, 80, 40, 90, 30], theme),
              _buildReportContent('Shu oy', '38 000 000', [60, 80, 70, 90, 50, 100, 60], theme),
              _buildReportContent('Shu yil', '420 000 000', [70, 90, 80, 60, 100, 50, 70], theme),
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
          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.3),
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
                '+15% o\'tgan davrga nisbatan',
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
                  color: const Color(0xFFEC4899).withValues(alpha: 0.8),
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
      {'service': 'Soch kesish', 'count': '24', 'amount': '1 440 000'},
      {'service': 'Bo\'yash', 'count': '12', 'amount': '2 400 000'},
      {'service': 'Manikyur/Pedikyur', 'count': '18', 'amount': '1 440 000'},
      {'service': 'Makiyaj', 'count': '8', 'amount': '1 200 000'},
      {'service': 'Boshqa xizmatlar', 'count': '6', 'amount': '520 000'},
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
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.sparkles, size: 20, color: Color(0xFFEC4899)),
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
                      '${item['count']} ta xizmat',
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
