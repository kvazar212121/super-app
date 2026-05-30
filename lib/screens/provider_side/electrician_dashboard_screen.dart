import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/electrician_calendar_widget.dart';
import 'widgets/electrician_reports_widget.dart';

class ElectricianDashboardScreen extends StatefulWidget {
  const ElectricianDashboardScreen({super.key});

  @override
  State<ElectricianDashboardScreen> createState() => _ElectricianDashboardScreenState();
}

class _ElectricianDashboardScreenState extends State<ElectricianDashboardScreen> {
  bool _isAvailable = true;
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
        return const ElectricianCalendarWidget();
      case 2:
        return const ElectricianReportsWidget();
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
        _buildUrgencyAlerts(theme),
        const SizedBox(height: 24),
        _buildCurrentJob(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi chaqiruvlar', theme),
        const SizedBox(height: 16),
        _buildCallsList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.zap, color: Color(0xFFD97706), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bobur (Elektrik)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.7 (78 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isAvailable ? const Color(0xFFD97706).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isAvailable ? const Color(0xFFD97706) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isAvailable ? 'Ishga tayyor' : 'Dam olishda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isAvailable ? const Color(0xFFD97706) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Chaqiruvlar', '4', LucideIcons.phoneCall, theme),
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
            Icon(icon, color: const Color(0xFFD97706), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyAlerts(ThemeData theme) {
    final alerts = [
      {'type': 'SHOSHILINCH', 'text': 'Tok urishi xavfi - Chilonzor', 'color': const Color(0xFFEF4444)},
      {'type': 'OGOHLENTRISH', 'text': 'Sim yong\'oni - Yunusabad', 'color': const Color(0xFFF59E0B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ogohlantirishlar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...alerts.map((alert) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (alert['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: alert['color'] as Color),
            ),
            child: Row(
              children: [
                Icon(
                  alert['type'] == 'SHOSHILINCH' ? LucideIcons.alertTriangle : LucideIcons.alertCircle,
                  color: alert['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['type'] as String,
                        style: TextStyle(
                          color: alert['color'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        alert['text'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alert['color'] as Color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Qabul qilish'),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCurrentJob(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Hozirgi ish', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rozetka montaj + Sim almashtirish',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.home, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Text('Chilonzor, 5-kv, 12-uy', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.checkCircle, size: 16),
            label: const Text('Tugallash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD97706),
            ),
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

  Widget _buildCallsList(ThemeData theme) {
    final calls = [
      {'time': '14:00', 'service': 'Lyustra osish', 'address': 'Sergeli', 'price': '80 000', 'status': 'Kutyapti'},
      {'time': '16:00', 'service': 'Elektr tekshiruvi', 'address': 'Yunusabad', 'price': '150 000', 'status': 'Rejalashtirilgan'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: calls.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = calls[index];
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
                  color: const Color(0xFFD97706).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['service']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item['address']} • ${item['price']} so\'m', style: theme.textTheme.bodySmall),
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
      selectedItemColor: const Color(0xFFD97706),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Panel'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Jadval'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.barChart3), label: 'Hisobot'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Sozlamalar'),
      ],
    );
  }
}
