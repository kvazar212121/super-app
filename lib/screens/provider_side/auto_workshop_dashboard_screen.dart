import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/auto_calendar_widget.dart';
import 'widgets/auto_reports_widget.dart';

class AutoWorkshopDashboardScreen extends StatefulWidget {
  const AutoWorkshopDashboardScreen({super.key});

  @override
  State<AutoWorkshopDashboardScreen> createState() => _AutoWorkshopDashboardScreenState();
}

class _AutoWorkshopDashboardScreenState extends State<AutoWorkshopDashboardScreen> {
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
        return const AutoCalendarWidget();
      case 2:
        return const AutoReportsWidget();
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
        _buildMechanicsOverview(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi mashinalar', theme),
        const SizedBox(height: 16),
        _buildCarsList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.wrench, color: Color(0xFF6366F1), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AvtoMaster Servis',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.7 (92 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isOpen ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isOpen ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isOpen ? const Color(0xFF6366F1) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isOpen ? 'Hozir ochiq' : 'Yopiq',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isOpen ? const Color(0xFF6366F1) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Mashinalar', '6', LucideIcons.car, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Daromad', '3.2M', LucideIcons.banknote, theme),
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
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicsOverview(ThemeData theme) {
    final mechanics = [
      {'name': 'Rustam (Dvigatel)', 'status': 'Band', 'car': 'Cobalt #456', 'color': const Color(0xFFEF4444)},
      {'name': 'Bobur (Tormoz)', 'status': 'Bo\'sh', 'car': '-', 'color': const Color(0xFF10B981)},
      {'name': 'Anvar (Elektr)', 'status': 'Tashxis', 'car': 'Malibu #789', 'color': const Color(0xFFF59E0B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ustalar holati',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...mechanics.map((mechanic) => Padding(
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
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.wrench, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mechanic['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${mechanic['status']} ${mechanic['car'] != '-' ? '• ${mechanic['car']}' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: mechanic['color'] as Color,
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

  Widget _buildCarsList(ThemeData theme) {
    final cars = [
      {'car': 'Cobalt #456', 'time': '09:00', 'service': 'Dvigatel ta\'mirlash', 'mechanic': 'Rustam', 'price': '850 000'},
      {'car': 'Malibu #789', 'time': '10:30', 'service': 'Elektr diagnostika', 'mechanic': 'Anvar', 'price': '200 000'},
      {'car': 'Spark #123', 'time': '14:00', 'service': 'Tormoz almashtirish', 'mechanic': 'Bobur', 'price': '450 000'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cars.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = cars[index];
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['car']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item['service']} • ${item['mechanic']}', style: theme.textTheme.bodySmall),
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
      selectedItemColor: const Color(0xFF6366F1),
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
