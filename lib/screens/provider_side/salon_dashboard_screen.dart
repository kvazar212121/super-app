import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/salon_calendar_widget.dart';
import 'widgets/salon_reports_widget.dart';

class SalonDashboardScreen extends StatefulWidget {
  const SalonDashboardScreen({super.key});

  @override
  State<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends State<SalonDashboardScreen> {
  bool _isOpen = true;
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
        return const SalonCalendarWidget();
      case 2:
        return const SalonReportsWidget();
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
        _buildSummaryRow(theme),
        const SizedBox(height: 24),
        _buildMastersOverview(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi mijozlar', theme),
        const SizedBox(height: 16),
        _buildAppointmentsList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.sparkles, color: Color(0xFFEC4899), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nafis Beauty Salon',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.9 (156 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isOpen ? const Color(0xFFEC4899).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isOpen ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isOpen ? const Color(0xFFEC4899) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isOpen ? 'Hozir ochiq' : 'Yopiq',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isOpen ? const Color(0xFFEC4899) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            activeColor: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Mijozlar', '18', LucideIcons.users, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Daromad', '1.8M', LucideIcons.banknote, theme),
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
            Icon(icon, color: const Color(0xFFEC4899), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildMastersOverview(ThemeData theme) {
    final masters = [
      {'name': 'Malika (Soch)', 'status': 'Bo\'sh', 'next': '15:00', 'color': const Color(0xFF10B981)},
      {'name': 'Zarina (Tirnoq)', 'status': 'Band', 'next': '16:30', 'color': const Color(0xFFEF4444)},
      {'name': 'Nilufar (Makiyaj)', 'status': 'Bo\'sh', 'next': '14:00', 'color': const Color(0xFF10B981)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masterlar holati',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...masters.map((master) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.user, color: Color(0xFFEC4899), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        master['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${master['status']} • Keyingi: ${master['next']}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: master['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
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

  Widget _buildAppointmentsList(ThemeData theme) {
    final appointments = [
      {'name': 'Aziza R.', 'time': '14:00', 'service': 'Soch kesish + Bo\'yash', 'master': 'Malika', 'price': '180 000'},
      {'name': 'Dildora K.', 'time': '15:00', 'service': 'Manikyur', 'master': 'Zarina', 'price': '80 000'},
      {'name': 'Shahlo M.', 'time': '16:00', 'service': 'Makiyaj', 'master': 'Nilufar', 'price': '150 000'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = appointments[index];
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
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item['service']} • ${item['master']}', style: theme.textTheme.bodySmall),
                    Text('${item['price']} so\'m', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
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
      selectedItemColor: const Color(0xFFEC4899),
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
