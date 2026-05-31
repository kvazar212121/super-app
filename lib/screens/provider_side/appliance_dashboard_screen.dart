import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/appliance_calendar_widget.dart';
import 'widgets/appliance_reports_widget.dart';

class ApplianceDashboardScreen extends StatefulWidget {
  const ApplianceDashboardScreen({super.key});

  @override
  State<ApplianceDashboardScreen> createState() => _ApplianceDashboardScreenState();
}

class _ApplianceDashboardScreenState extends State<ApplianceDashboardScreen> {
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
        return const ApplianceCalendarWidget();
      case 2:
        return const ApplianceReportsWidget();
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
        _buildApplianceTypeOverview(theme),
        const SizedBox(height: 24),
        _buildBrandInfo(theme),
        const SizedBox(height: 24),
        _buildCurrentRepair(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi ta\'mirlash', theme),
        const SizedBox(height: 16),
        _buildRepairList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF607D8B).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.monitor, color: Color(0xFF607D8B), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Abdulloh (Maishiy texnika)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.8 (118 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isAvailable
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isAvailable ? const Color(0xFF10B981) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isAvailable ? 'Ishga tayyor' : 'Dam olishda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isAvailable ? const Color(0xFF10B981) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('Buyurtmalar', '8', LucideIcons.clipboardList, theme),
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
            Icon(icon, color: const Color(0xFF607D8B), size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildApplianceTypeOverview(ThemeData theme) {
    final applianceTypes = [
      {'name': 'Kir yuvish', 'count': '3', 'icon': LucideIcons.waves},
      {'name': 'Muzlatgich', 'count': '2', 'icon': LucideIcons.snowflake},
      {'name': 'TV', 'count': '2', 'icon': LucideIcons.monitor},
      {'name': 'Pech', 'count': '1', 'icon': LucideIcons.flame},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Texnika turlari bo\'yicha',
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
          itemCount: applianceTypes.length,
          itemBuilder: (context, index) {
            final item = applianceTypes[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF607D8B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF607D8B).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF607D8B), size: 24),
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

  Widget _buildBrandInfo(ThemeData theme) {
    final brands = [
      {'name': 'Samsung', 'count': '3', 'icon': LucideIcons.badgeCheck},
      {'name': 'LG', 'count': '2', 'icon': LucideIcons.badgeCheck},
      {'name': 'Bosch', 'count': '2', 'icon': LucideIcons.badgeCheck},
      {'name': 'Boshqa', 'count': '1', 'icon': LucideIcons.badgeCheck},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brendlar bo\'yicha',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...brands.map((brand) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(brand['icon'] as IconData, size: 18, color: const Color(0xFF607D8B)),
                  const SizedBox(width: 12),
                  Text(
                    brand['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '${brand['count']} ta',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF607D8B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCurrentRepair(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
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
              const Icon(LucideIcons.wrench, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Hozirgi ta\'mir', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Samsung Kir yuvish mashinasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Text('Chilonzor, 12-uy, 5-xonadon', style: TextStyle(color: Colors.white70)),
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
                child: const Text('Model: WW80T', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Kafolatda', style: TextStyle(color: Colors.white)),
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
              foregroundColor: const Color(0xFF607D8B),
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

  Widget _buildRepairList(ThemeData theme) {
    final repairs = [
      {
        'time': '10:00',
        'service': 'Kir yuvish ta\'mirlash',
        'address': 'Yunusabad',
        'price': '250 000',
        'applianceType': 'Kir yuvish',
        'brand': 'Samsung',
        'model': 'WW80T',
        'warranty': 'Kafolatda',
      },
      {
        'time': '13:00',
        'service': 'Muzlatgich ta\'mirlash',
        'address': 'Mirzo Ulug\'bek',
        'price': '350 000',
        'applianceType': 'Muzlatgich',
        'brand': 'LG',
        'model': 'GA-B509',
        'warranty': 'Chiqqan',
      },
      {
        'time': '16:00',
        'service': 'TV ta\'mirlash',
        'address': 'Sergeli',
        'price': '180 000',
        'applianceType': 'TV',
        'brand': 'Bosch',
        'model': '55QLED',
        'warranty': 'Kafolatda',
      },
      {
        'time': '18:00',
        'service': 'Pech ta\'mirlash',
        'address': 'Chilonzor',
        'price': '200 000',
        'applianceType': 'Pech',
        'brand': 'Samsung',
        'model': 'NZ64R',
        'warranty': 'Chiqqan',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: repairs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = repairs[index];
        final warrantyColor =
            item['warranty'] == 'Kafolatda' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

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
                  color: const Color(0xFF607D8B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF607D8B),
                  ),
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
                        Text(
                          '${item['price']} so\'m',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['applianceType']} • ${item['brand']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: warrantyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['warranty']!,
                            style: TextStyle(
                              color: warrantyColor,
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
      selectedItemColor: const Color(0xFF607D8B),
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
