import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/tutor_calendar_widget.dart';
import 'widgets/tutor_reports_widget.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
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
        return const TutorCalendarWidget();
      case 2:
        return const TutorReportsWidget();
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
        _buildCurrentLesson(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Fanlar', theme),
        const SizedBox(height: 16),
        _buildSubjectsOverview(theme),
        const SizedBox(height: 32),
        _buildSectionTitle('Bugungi darslar', theme),
        const SizedBox(height: 16),
        _buildLessonsList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.bookOpen, color: Color(0xFF7C3AED), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Abdullayev S.',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.8 (185 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isOpen ? const Color(0xFF7C3AED).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isOpen ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isOpen ? const Color(0xFF7C3AED) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isOpen ? 'Hozir dars o\'tilyapti' : 'Bo\'sh',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isOpen ? const Color(0xFF7C3AED) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('O\'quvchilar', '42', LucideIcons.users, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Fanlar', '4', LucideIcons.bookOpen, theme),
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
            Icon(icon, color: const Color(0xFF7C3AED), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLesson(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.clock, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Hozirgi dars',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Matematika',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.user, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('O\'quvchi: Karimova N.', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.wifi, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('Format: Online', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.graduationCap, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('Daraja: Imtihonga tayyorlov', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsOverview(ThemeData theme) {
    final subjects = [
      {'name': 'Matematika', 'students': '15', 'level': 'O\'rta, Yuqori', 'format': 'Online / Offline'},
      {'name': 'Ingliz tili', 'students': '12', 'level': 'Boshlang\'ich, O\'rta', 'format': 'Online'},
      {'name': 'Fizika', 'students': '8', 'level': 'Yuqori, Imtihonga tayyorlov', 'format': 'Offline (uyda)'},
      {'name': 'Test tayyorlov', 'students': '7', 'level': 'Imtihonga tayyorlov', 'format': 'Online / Offline'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...subjects.map((subject) => Padding(
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.bookOpen, color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${subject['students']} o\'quvchi • ${subject['level']}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        subject['format'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
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

  Widget _buildLessonsList(ThemeData theme) {
    final lessons = [
      {'subject': 'Matematika', 'time': '10:00', 'student': 'Karimova N.', 'level': 'Yuqori', 'format': 'Online'},
      {'subject': 'Ingliz tili', 'time': '12:00', 'student': 'Rustamov A.', 'level': 'Boshlang\'ich', 'format': 'Online'},
      {'subject': 'Fizika', 'time': '14:00', 'student': 'Toshmatov B.', 'level': 'Imtihonga tayyorlov', 'format': 'Offline (uyda)'},
      {'subject': 'Test tayyorlov', 'time': '16:00', 'student': 'Azimova D.', 'level': 'Imtihonga tayyorlov', 'format': 'Offline (uyda)'},
      {'subject': 'Matematika', 'time': '18:00', 'student': 'Sobirov K.', 'level': 'O\'rta', 'format': 'Online'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lessons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = lessons[index];
        final formatIcon = (item['format'] as String).contains('Online')
            ? LucideIcons.wifi
            : LucideIcons.home;

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
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['subject']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item['student']} • ${item['level']}', style: theme.textTheme.bodySmall),
                    Row(
                      children: [
                        Icon(formatIcon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(item['format']!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
      selectedItemColor: const Color(0xFF7C3AED),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Panel'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Jadval'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.barChart3), label: 'Hisobotlar'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Sozlamalar'),
      ],
    );
  }
}
