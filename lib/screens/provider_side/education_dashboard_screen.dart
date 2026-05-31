import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'widgets/education_calendar_widget.dart';
import 'widgets/education_reports_widget.dart';

class EducationDashboardScreen extends StatefulWidget {
  const EducationDashboardScreen({super.key});

  @override
  State<EducationDashboardScreen> createState() => _EducationDashboardScreenState();
}

class _EducationDashboardScreenState extends State<EducationDashboardScreen> {
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
        return const EducationCalendarWidget();
      case 2:
        return const EducationReportsWidget();
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
        _buildCoursesOverview(theme),
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
          backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          child: const Icon(LucideIcons.graduationCap, color: Color(0xFF8B5CF6), size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ziyo Education Center',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('4.9 (210 sharh)', style: theme.textTheme.bodySmall),
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
        color: _isOpen ? const Color(0xFF8B5CF6).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isOpen ? LucideIcons.checkCircle2 : LucideIcons.pauseCircle,
            color: _isOpen ? const Color(0xFF8B5CF6) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            _isOpen ? 'Hozir ochiq' : 'Yopiq',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isOpen ? const Color(0xFF8B5CF6) : Colors.grey,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v),
            activeColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    return Row(
      children: [
        _buildSummaryCard('O\'quvchilar', '156', LucideIcons.users, theme),
        const SizedBox(width: 16),
        _buildSummaryCard('Kurslar', '12', LucideIcons.bookOpen, theme),
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
            Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesOverview(ThemeData theme) {
    final courses = [
      {'name': 'IELTS Preparation', 'students': '45', 'teacher': 'Mr. John', 'time': '10:00-12:00', 'status': 'Dars boshlandi'},
      {'name': ' Matematika', 'students': '38', 'teacher': 'Azimov A.', 'time': '14:00-16:00', 'status': 'Kutyapti'},
      {'name': 'Dasturlash (Python)', 'students': '32', 'teacher': 'Karimov B.', 'time': '16:00-18:00', 'status': 'Kutyapti'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kurslar holati',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...courses.map((course) => Padding(
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.bookOpen, color: Color(0xFF8B5CF6), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${course['students']} o\'quvchi • ${course['teacher']}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${course['time']} • ${course['status']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: course['status'] == 'Dars boshlandi' 
                              ? const Color(0xFF10B981) 
                              : Colors.grey,
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
      {'course': 'IELTS Preparation', 'time': '10:00', 'topic': 'Reading + Writing', 'teacher': 'Mr. John', 'students': '45'},
      {'course': 'Matematika', 'time': '14:00', 'topic': 'Algebra - Tenglamalar', 'teacher': 'Azimov A.', 'students': '38'},
      {'course': 'Dasturlash (Python)', 'time': '16:00', 'topic': 'OOP - Classes', 'teacher': 'Karimov B.', 'students': '32'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lessons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = lessons[index];
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['time']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['course']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item['topic']!, style: theme.textTheme.bodySmall),
                    Text('${item['teacher']} • ${item['students']} o\'quvchi', style: theme.textTheme.bodySmall),
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
      selectedItemColor: const Color(0xFF8B5CF6),
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
