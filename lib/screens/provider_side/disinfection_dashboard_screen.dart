import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/disinfection_calendar_widget.dart';
import 'widgets/disinfection_reports_widget.dart';

class DisinfectionDashboardScreen extends StatefulWidget {
  const DisinfectionDashboardScreen({super.key});

  @override
  State<DisinfectionDashboardScreen> createState() => _DisinfectionDashboardScreenState();
}

class _DisinfectionDashboardScreenState extends State<DisinfectionDashboardScreen> {
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
        return const DisinfectionCalendarWidget();
      case 2:
        return const DisinfectionReportsWidget();
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
        _buildAreaTypeOverview(theme),
        const SizedBox(height: 24),
        _buildChemicalsStatus(theme),
        const SizedBox(height: 24),
        _buildCurrentJob(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi dezinfeksiya', theme),
        const SizedBox(height: 16),
        _buildDisinfectionList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sardor (Dezinfeksiya)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.9 (92 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isAvailable ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
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
        _buildSummaryCard('Buyurtmalar', '6', LucideIcons.clipboardList, theme),
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
            Icon(icon, color: const Color(0xFF10B981), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaTypeOverview(ThemeData theme) {
    final areaTypes = [
      {'name': 'Kvartira', 'count': '2', 'icon': LucideIcons.building},
      {'name': 'Ofis', 'count': '1', 'icon': LucideIcons.briefcase},
      {'name': 'Mashina', 'count': '1', 'icon': LucideIcons.car},
      {'name': 'Maktab/bog\'cha', 'count': '2', 'icon': LucideIcons.school},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hudud turlari bo\'yicha',
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
          itemCount: areaTypes.length,
          itemBuilder: (context, index) {
            final item = areaTypes[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF10B981), size: 24),
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

  Widget _buildChemicalsStatus(ThemeData theme) {
    final chemicals = [
      {'name': 'Xlorli eritma', 'level': '75%', 'icon': LucideIcons.flaskConical},
      {'name': 'Vodorod peroksid', 'level': '40%', 'icon': LucideIcons.testTube},
      {'name': 'Antiseptik sprey', 'level': '90%', 'icon': LucideIcons.sprayCan},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kimyoviy moddalar holati',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...chemicals.map((chem) {
          final level = double.parse((chem['level'] as String).replaceAll('%', ''));
          final barColor = level > 60
              ? const Color(0xFF10B981)
              : level > 30
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(chem['icon'] as IconData, size: 18, color: const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      Text(
                        chem['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        chem['level'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: level / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 6,
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

  Widget _buildCurrentJob(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
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
            'Kuchaytirilgan dezinfeksiya - Kvartira',
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
              const Text('Chilonzor, 8-kv, 3-uy', style: TextStyle(color: Colors.white70)),
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
                child: const Text('Maydon: 85 m²', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Kuchaytirilgan', style: TextStyle(color: Colors.white)),
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
                child: const Text('Kimyo: Xlorli eritma', style: TextStyle(color: Colors.white, fontSize: 11)),
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
              foregroundColor: const Color(0xFF10B981),
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

  Widget _buildDisinfectionList(ThemeData theme) {
    final disinfections = [
      {
        'time': '10:00',
        'service': 'Kvartira dezinfeksiya',
        'address': 'Yunusabad',
        'price': '200 000',
        'areaType': 'Kvartira',
        'area': '85 m²',
        'safety': 'Kuchaytirilgan',
      },
      {
        'time': '13:00',
        'service': 'Ofis dezinfeksiya',
        'address': 'Mirzo Ulug\'bek',
        'price': '350 000',
        'areaType': 'Ofis',
        'area': '150 m²',
        'safety': 'Standart',
      },
      {
        'time': '16:00',
        'service': 'Mashina dezinfeksiya',
        'address': 'Sergeli',
        'price': '100 000',
        'areaType': 'Mashina',
        'area': '-',
        'safety': 'Standart',
      },
    ];

    final safetyColors = {
      'Standart': const Color(0xFF10B981),
      'Kuchaytirilgan': const Color(0xFFF59E0B),
      'Maxsus': const Color(0xFFEF4444),
    };

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: disinfections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = disinfections[index];
        final safetyColor = safetyColors[item['safety']] ?? Colors.grey;

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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
                            '${item['areaType']} • ${item['area']}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: safetyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['safety']!,
                            style: TextStyle(
                              color: safetyColor,
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
      selectedItemColor: const Color(0xFF10B981),
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
