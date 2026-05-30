import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/events_calendar_widget.dart';
import 'widgets/events_reports_widget.dart';

class EventsDashboardScreen extends StatefulWidget {
  const EventsDashboardScreen({super.key});

  @override
  State<EventsDashboardScreen> createState() => _EventsDashboardScreenState();
}

class _EventsDashboardScreenState extends State<EventsDashboardScreen> {
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
        return const EventsCalendarWidget();
      case 2:
        return const EventsReportsWidget();
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
        _buildEventTypeCards(theme),
        const SizedBox(height: 24),
        _buildSummaryRow(theme),
        const SizedBox(height: 24),
        _buildStatsRow(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi tadbirlar', theme),
        const SizedBox(height: 16),
        _buildEventsList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.partyPopper, color: Color(0xFFE91E63), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sardor (Tadbirlar)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.9 (95 sharh)', style: theme.textTheme.bodySmall),
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

  Widget _buildEventTypeCards(ThemeData theme) {
    final types = [
      {'label': "To'y rejissyor", 'icon': LucideIcons.bell, 'count': '2'},
      {'label': "Tug'ilgan kun", 'icon': LucideIcons.cakeSlice, 'count': '3'},
      {'label': 'Korporativ', 'icon': LucideIcons.briefcase, 'count': '1'},
      {'label': 'Dam olish joyi', 'icon': LucideIcons.treePine, 'count': '2'},
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
            color: const Color(0xFFE91E63).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE91E63).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item['icon'] as IconData, color: const Color(0xFFE91E63), size: 28),
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
                      color: Color(0xFFE91E63),
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
        _buildSummaryCard('Tadbirlar', '8', LucideIcons.calendarCheck, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Daromad', '2.5M', LucideIcons.banknote, theme),
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
            Icon(icon, color: const Color(0xFFE91E63), size: 24),
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
        _buildStatCard('Mehmonlar', '450', LucideIcons.users, theme),
        const SizedBox(width: 16),
        _buildStatCard('Joylar', '5', LucideIcons.mapPin, theme),
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
            Icon(icon, color: const Color(0xFFE91E63), size: 22),
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

  Widget _buildEventsList(ThemeData theme) {
    final events = [
      {
        'time': '10:00',
        'name': "Azimovlar to'yi",
        'eventType': "To'y rejissyor",
        'guestCount': '150',
        'venue': 'Restoran',
        'phase': "O'tkazilmoqda",
        'price': '1 200 000',
      },
      {
        'time': '14:00',
        'name': "Malikaning tug'ilgan kuni",
        'eventType': "Tug'ilgan kun",
        'guestCount': '30',
        'venue': 'Uy',
        'phase': 'Tayyorgarlik',
        'price': '350 000',
      },
      {
        'time': '18:00',
        'name': 'TechCorp korporativ',
        'eventType': 'Korporativ',
        'guestCount': '80',
        'venue': 'Dam olish joyi',
        'phase': 'Tayyorgarlik',
        'price': '800 000',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = events[index];
        Color phaseColor;
        switch (item['phase'] as String) {
          case 'Tayyorgarlik':
            phaseColor = Colors.amber;
            break;
          case "O'tkazilmoqda":
            phaseColor = const Color(0xFFE91E63);
            break;
          case 'Tugallangan':
            phaseColor = const Color(0xFF10B981);
            break;
          default:
            phaseColor = Colors.grey;
        }

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
                  color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${item['eventType']} • ${item['guestCount']} mehmon',
                      style: theme.textTheme.bodySmall,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['phase'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: phaseColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item['venue']} • ${item['price']} so\'m',
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
      selectedItemColor: const Color(0xFFE91E63),
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
