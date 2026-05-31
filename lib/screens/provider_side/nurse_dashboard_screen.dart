import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/nurse_calendar_widget.dart';
import 'widgets/nurse_reports_widget.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
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
        return const NurseCalendarWidget();
      case 2:
        return const NurseReportsWidget();
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
        _buildSectionTitle('Bugungi xizmatlar', theme),
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
          backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.heartPulse, color: Color(0xFFE53935), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hamshira Dilfuza',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.8 (120 sharh)', style: theme.textTheme.bodySmall),
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
      {'label': "In'ektsiya", 'icon': LucideIcons.syringe, 'count': '5'},
      {'label': 'Qon tahlili', 'icon': LucideIcons.testTube, 'count': '3'},
      {'label': 'Dori berish', 'icon': LucideIcons.pill, 'count': '4'},
      {'label': 'Tomchilatish', 'icon': LucideIcons.flaskConical, 'count': '2'},
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
            color: const Color(0xFFE53935).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item['icon'] as IconData, color: const Color(0xFFE53935), size: 28),
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
                      color: Color(0xFFE53935),
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
        _buildSummaryCard('Xizmatlar', '14', LucideIcons.calendarCheck, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Daromad', '850k', LucideIcons.banknote, theme),
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
            Icon(icon, color: const Color(0xFFE53935), size: 24),
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
        _buildStatCard('Katta', '9', LucideIcons.user, theme),
        const SizedBox(width: 16),
        _buildStatCard('Bola', '5', LucideIcons.baby, theme),
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
            Icon(icon, color: const Color(0xFFE53935), size: 22),
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
        'time': '09:00',
        'name': 'Aziza Rahimova',
        'service': "In'ektsiya",
        'ageGroup': 'Katta',
        'urgency': 'Oddiy',
        'location': 'Uyda',
        'price': '50 000',
      },
      {
        'time': '10:30',
        'name': 'Bobur Karimov',
        'service': 'Qon tahlili',
        'ageGroup': 'Katta',
        'urgency': 'Shoshilinch',
        'location': 'Klinikada',
        'price': '80 000',
      },
      {
        'time': '13:00',
        'name': 'Malika Sardorova',
        'service': 'Tomchilatish',
        'ageGroup': 'Bola',
        'urgency': 'Oddiy',
        'location': 'Uyda',
        'price': '120 000',
      },
      {
        'time': '15:00',
        'name': 'Jasur Aliyev',
        'service': 'Dori berish',
        'ageGroup': 'Katta',
        'urgency': 'Oddiy',
        'location': 'Uyda',
        'price': '40 000',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sessions[index];
        final urgencyColor = item['urgency'] == 'Shoshilinch'
            ? const Color(0xFFE53935)
            : const Color(0xFF10B981);

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
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${item['service']} • ${item['ageGroup']}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['urgency'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item['location']} • ${item['price']} so\'m',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
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
      selectedItemColor: const Color(0xFFE53935),
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
