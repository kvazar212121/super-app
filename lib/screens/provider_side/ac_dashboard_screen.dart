import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/ac_calendar_widget.dart';
import 'widgets/ac_reports_widget.dart';

class AcDashboardScreen extends StatefulWidget {
  const AcDashboardScreen({super.key});

  @override
  State<AcDashboardScreen> createState() => _AcDashboardScreenState();
}

class _AcDashboardScreenState extends State<AcDashboardScreen> {
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
        return const AcCalendarWidget();
      case 2:
        return const AcReportsWidget();
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
        _buildSeasonalIndicator(theme),
        const SizedBox(height: 24),
        _buildSummaryRow(theme),
        const SizedBox(height: 24),
        _buildServiceTypes(theme),
        const SizedBox(height: 24),
        _buildCurrentJob(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi buyurtmalar', theme),
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
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.wind, color: Color(0xFF6366F1), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sardor (Konditsioner)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.8 (85 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isAvailable ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isAvailable ? const Color(0xFF6366F1) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isAvailable ? 'Ishga tayyor' : 'Dam olishda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isAvailable ? const Color(0xFF6366F1) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalIndicator(ThemeData theme) {
    final now = DateTime.now();
    final month = now.month;
    final isSummer = month >= 5 && month <= 9;
    final seasonText = isSummer ? 'Yoz mavsumi' : 'Qish mavsumi';
    final seasonIcon = isSummer ? LucideIcons.sun : LucideIcons.snowflake;
    final seasonColor = isSummer ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: seasonColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: seasonColor),
      ),
      child: Row(
        children: [
          Icon(seasonIcon, color: seasonColor, size: 24),
          const SizedBox(width: 12),
          Text(
            seasonText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: seasonColor,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            isSummer ? 'Sovuq havo xizmatlari' : 'Isitish xizmatlari',
            style: TextStyle(color: seasonColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Buyurtmalar', '5', LucideIcons.clipboardList, theme),
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
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypes(ThemeData theme) {
    final services = [
      {'name': 'Montaj', 'icon': LucideIcons.plusCircle, 'count': '2'},
      {'name': 'Demontaj', 'icon': LucideIcons.minusCircle, 'count': '1'},
      {'name': 'Profilaktika', 'icon': LucideIcons.brush, 'count': '3'},
      {'name': 'Gaz to\'ldirish', 'icon': LucideIcons.gauge, 'count': '4'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xizmat turlari',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final item = services[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item['count']} ta',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentJob(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
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
            'LG Inverter - Gaz to\'ldirish (R410A)',
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
              const Text('Chilonzor, 9-kv, 18-uy', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Brend: LG', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Gaz: R410A', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.checkCircle, size: 16),
            label: const Text('Tugallash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
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

  Widget _buildAppointmentsList(ThemeData theme) {
    final appointments = [
      {
        'time': '10:00',
        'brand': 'Samsung',
        'service': 'Montaj',
        'gas': 'R410A',
        'address': 'Yunusabad',
        'price': '250 000',
      },
      {
        'time': '12:30',
        'brand': 'General',
        'service': 'Profilaktika tozalash',
        'gas': '-',
        'address': 'Mirzo Ulug\'bek',
        'price': '120 000',
      },
      {
        'time': '15:00',
        'brand': 'LG',
        'service': 'Demontaj',
        'gas': 'R22',
        'address': 'Sergeli',
        'price': '180 000',
      },
      {
        'time': '17:00',
        'brand': 'Samsung',
        'service': 'Gaz to\'ldirish',
        'gas': 'R410A',
        'address': 'Chilonzor',
        'price': '200 000',
      },
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
                    Text(
                      '${item['brand']} - ${item['service']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text('${item['address']} • ${item['price']} so\'m', style: theme.textTheme.bodySmall),
                        const SizedBox(width: 8),
                        if (item['gas'] != '-')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Gaz: ${item['gas']}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6366F1)),
                            ),
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
      selectedItemColor: const Color(0xFF6366F1),
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
