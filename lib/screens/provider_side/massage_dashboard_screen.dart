import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/massage_calendar_widget.dart';
import 'widgets/massage_reports_widget.dart';

class MassageDashboardScreen extends StatefulWidget {
  const MassageDashboardScreen({super.key});

  @override
  State<MassageDashboardScreen> createState() => _MassageDashboardScreenState();
}

class _MassageDashboardScreenState extends State<MassageDashboardScreen> {
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
        return const MassageCalendarWidget();
      case 2:
        return const MassageReportsWidget();
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
        _buildServiceTypeCards(theme),
        const SizedBox(height: 24),
        _buildSummaryRow(theme),
        const SizedBox(height: 24),
        _buildStatsRow(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi seanslar', theme),
        const SizedBox(height: 16),
        _buildSessionList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF795548).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.hand, color: Color(0xFF795548), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nilufar (Massaj va Hijoma)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.9 (150 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
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
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeCards(ThemeData theme) {
    final types = [
      {'label': 'Massaj', 'icon': LucideIcons.hand, 'count': '4'},
      {'label': 'Hijoma erkaklar', 'icon': LucideIcons.droplet, 'count': '2'},
      {'label': 'Hijoma ayollar', 'icon': LucideIcons.droplets, 'count': '3'},
      {'label': 'Spa paket', 'icon': LucideIcons.sparkles, 'count': '1'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final item = types[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF795548).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF795548).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item['icon'] as IconData, color: const Color(0xFF795548), size: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    item['count'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF795548),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Seanslar', '10', LucideIcons.calendarCheck, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Daromad', '680k', LucideIcons.banknote, theme),
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
            Icon(icon, color: const Color(0xFF795548), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        _buildStatCard('Erkaklar', '4', LucideIcons.user, theme),
        const SizedBox(width: 16),
        _buildStatCard('Ayollar', '6', LucideIcons.heart, theme),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF795548), size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    return Row(
      children: [
        _buildLocationItem('Salon', '7', LucideIcons.building, theme),
        const SizedBox(width: 16),
        _buildLocationItem('Uyga borish', '3', LucideIcons.home, theme),
      ],
    );
  }

  Widget _buildLocationItem(String title, String value, IconData icon, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF795548), size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
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

  Widget _buildSessionList(ThemeData theme) {
    final sessions = [
      {
        'time': '10:00',
        'name': 'Madina Karimova',
        'service': 'Massaj',
        'gender': 'Ayollar',
        'location': 'Salon',
        'price': '80 000',
      },
      {
        'time': '11:30',
        'name': 'Farxod Aliyev',
        'service': 'Hijoma',
        'gender': 'Erkaklar',
        'location': 'Salon',
        'price': '60 000',
      },
      {
        'time': '14:00',
        'name': 'Dilnoza Rustamova',
        'service': 'Spa paket',
        'gender': 'Ayollar',
        'location': 'Uyga borish',
        'price': '150 000',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sessions[index];
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
                width: 55,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF795548)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${item['service']} • ${item['gender']}',
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
      selectedItemColor: const Color(0xFF795548),
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
