import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/cleaning_calendar_widget.dart';
import 'widgets/cleaning_reports_widget.dart';

class CleaningDashboardScreen extends StatefulWidget {
  const CleaningDashboardScreen({super.key});

  @override
  State<CleaningDashboardScreen> createState() => _CleaningDashboardScreenState();
}

class _CleaningDashboardScreenState extends State<CleaningDashboardScreen> {
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
        return const CleaningCalendarWidget();
      case 2:
        return const CleaningReportsWidget();
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
        _buildRoomTypeOverview(theme),
        const SizedBox(height: 24),
        _buildCurrentJob(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi tozalash', theme),
        const SizedBox(height: 16),
        _buildCleaningList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.sprayCan, color: Color(0xFF06B6D4), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dilnoza (Tozalash)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.8 (78 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isAvailable ? const Color(0xFF06B6D4).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isAvailable ? const Color(0xFF06B6D4) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isAvailable ? 'Ishga tayyor' : 'Dam olishda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isAvailable ? const Color(0xFF06B6D4) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: const Color(0xFF06B6D4),
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
        _buildSummaryCard('Daromad', '750k', LucideIcons.banknote, theme),
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
            Icon(icon, color: const Color(0xFF06B6D4), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeOverview(ThemeData theme) {
    final roomTypes = [
      {'name': '1-xonali', 'count': '2', 'icon': LucideIcons.bedSingle},
      {'name': '2-xonali', 'count': '1', 'icon': LucideIcons.bedDouble},
      {'name': '3-xonali', 'count': '1', 'icon': LucideIcons.home},
      {'name': 'Ofis', 'count': '1', 'icon': LucideIcons.building2},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xona turlari bo\'yicha',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: roomTypes.length,
          itemBuilder: (context, index) {
            final item = roomTypes[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF06B6D4), size: 24),
                  const Spacer(),
                  Text(
                    item['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  Text(
                    '${item['count']} ta',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
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
            'Umumiy tozalash - 2-xonali',
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
              const Text('Chilonzor, 12-kv, 8-uy', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Xonalar: 4', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Maydon: 65 m²', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Material: Klient materiali', style: TextStyle(color: Colors.white, fontSize: 11)),
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
              foregroundColor: const Color(0xFF06B6D4),
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

  Widget _buildCleaningList(ThemeData theme) {
    final cleanings = [
      {
        'time': '10:00',
        'service': 'Umumiy tozalash',
        'address': 'Yunusabad',
        'price': '180 000',
        'rooms': '3 ta',
        'area': '80 m²',
        'material': 'O\'z materiali',
      },
      {
        'time': '13:00',
        'service': 'Derazalar tozalash',
        'address': 'Mirzo Ulug\'bek',
        'price': '120 000',
        'rooms': '2 ta',
        'area': '55 m²',
        'material': 'Klient materiali',
      },
      {
        'time': '16:00',
        'service': 'Ofis tozalash',
        'address': 'Chilonzor',
        'price': '200 000',
        'rooms': '5 ta',
        'area': '120 m²',
        'material': 'O\'z materiali',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cleanings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = cleanings[index];
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
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['service']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item['address']!, style: theme.textTheme.bodySmall),
                    Row(
                      children: [
                        Text('${item['price']} so\'m', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['rooms']} xona • ${item['area']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (item['material'] == 'O\'z materiali'
                                ? const Color(0xFF06B6D4)
                                : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['material']!,
                            style: TextStyle(
                              color: item['material'] == 'O\'z materiali'
                                  ? const Color(0xFF06B6D4)
                                  : const Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
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
      selectedItemColor: const Color(0xFF06B6D4),
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
