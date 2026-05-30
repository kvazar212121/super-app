import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/worker_calendar_widget.dart';
import 'widgets/worker_reports_widget.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isActive = true;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildBody(theme),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(theme);
      case 1:
        return const WorkerCalendarWidget();
      case 2:
        return const WorkerReportsWidget();
      default:
        return _buildDashboard(theme);
    }
  }

  Widget _buildDashboard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 24),
        _buildStatusToggle(theme),
        const SizedBox(height: 24),
        _buildWorkerTypeOverview(theme),
        const SizedBox(height: 24),
        _buildSummaryRow(theme),
        const SizedBox(height: 24),
        _buildCurrentJob(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi ishlar', theme),
        const SizedBox(height: 16),
        _buildJobsList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.hardHat, color: Color(0xFFF97316), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ishchi guruh',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.7 (85 sharh)', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.bell),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatusToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _isActive ? const Color(0xFFF97316).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isActive ? const Color(0xFFF97316) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isActive ? 'Ishga tayyor' : 'Dam olishda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isActive ? const Color(0xFFF97316) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerTypeOverview(ThemeData theme) {
    final workerTypes = [
      {'type': 'Yuk tashuvchi', 'icon': LucideIcons.package, 'count': '3 kishi'},
      {'type': 'Qora ishchi', 'icon': LucideIcons.shovel, 'count': '5 kishi'},
      {'type': 'Ko\'chirish', 'icon': LucideIcons.move, 'count': '2 kishi'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ishchi turlari',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: workerTypes.map((item) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(item['icon'] as IconData, color: const Color(0xFFF97316), size: 24),
                    const SizedBox(height: 8),
                    Text(
                      item['type'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['count'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF97316)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Ishlar', '8', LucideIcons.clipboardList, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Daromad', '1.2M', LucideIcons.banknote, theme),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFF97316), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentJob(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.briefcase, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Hozirgi ish',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Yuk ko\'tarish - 2 kishi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.clock, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Text(
                '4 soat',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Chilonzor, 5-mavze',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.phone, size: 16),
                label: const Text('Qo\'ng\'iroq'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.navigation, size: 16),
                label: const Text('Navigatsiya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Barchasi')),
      ],
    );
  }

  Widget _buildJobsList(ThemeData theme) {
    final jobs = [
      {
        'time': '09:00',
        'type': 'Yuk tashuvchi',
        'workers': '2 kishi',
        'duration': '4 soat',
        'location': 'Sergeli, 7-mavze',
        'price': '200 000',
      },
      {
        'time': '13:00',
        'type': 'Qora ishchi',
        'workers': '4 kishi',
        'duration': 'Kunlik',
        'location': 'Yunusabad, 3-kv',
        'price': '500 000',
      },
      {
        'time': '15:00',
        'type': 'Ko\'chirish',
        'workers': '1 kishi',
        'duration': '4 soat',
        'location': 'Mirzo Ulug\'bek, 12-uy',
        'price': '150 000',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = jobs[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['type']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${item['workers']} • ${item['duration']}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${item['location']} • ${item['price']} so\'m',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFF97316),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Panel'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Kalendar'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.barChart3), label: 'Hisobotlar'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Sozlamalar'),
      ],
    );
  }
}
