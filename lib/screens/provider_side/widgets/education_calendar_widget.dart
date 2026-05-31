import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EducationCalendarWidget extends StatefulWidget {
  const EducationCalendarWidget({super.key});

  @override
  State<EducationCalendarWidget> createState() => _EducationCalendarWidgetState();
}

class _EducationCalendarWidgetState extends State<EducationCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, Map<String, String>> _schedule = {
    '09:00': {'IELTS': 'Speaking', 'Matematika': '-', 'Dasturlash': '-'},
    '10:00': {'IELTS': 'Reading + Writing', 'Matematika': '-', 'Dasturlash': '-'},
    '11:00': {'IELTS': 'Listening', 'Matematika': 'Algebra', 'Dasturlash': '-'},
    '14:00': {'IELTS': '-', 'Matematika': 'Geometriya', 'Dasturlash': 'Python Basics'},
    '15:00': {'IELTS': '-', 'Matematika': 'Algebra', 'Dasturlash': 'Python OOP'},
    '16:00': {'IELTS': '-', 'Matematika': '-', 'Dasturlash': 'Python OOP'},
  };

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00',
  ];

  final List<String> _courses = ['IELTS', 'Matematika', 'Dasturlash'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(theme),
        const SizedBox(height: 20),
        _buildHorizontalDatePicker(theme),
        const SizedBox(height: 32),
        Row(
          children: [
            Text(
              'Dars jadvali',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildLegend(theme),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimeGrid(theme),
      ],
    );
  }

  Widget _buildDateHeader(ThemeData theme) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM, yyyy', 'uz_UZ').format(_selectedDate),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Bugun: ${DateFormat('d-MMMM', 'uz_UZ').format(DateTime.now())}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(LucideIcons.calendarDays, color: Color(0xFF8B5CF6)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalDatePicker(ThemeData theme) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);

          return InkWell(
            onTap: () => setState(() => _selectedDate = date),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B5CF6) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'uz_UZ').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      children: [
        _buildLegendItem('Bo\'sh', Colors.white, Colors.grey.withValues(alpha: 0.3)),
        const SizedBox(width: 12),
        _buildLegendItem('Dars bor', const Color(0xFF8B5CF6).withValues(alpha: 0.1), const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeGrid(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final courseSchedule = _schedule[slot] ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ..._courses.map((course) {
                final topic = courseSchedule[course] ?? '-';
                final hasLesson = topic != '-';
                final courseColors = {
                  'IELTS': const Color(0xFF10B981),
                  'Matematika': const Color(0xFFF59E0B),
                  'Dasturlash': const Color(0xFF6366F1),
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hasLesson ? courseColors[course] : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        course,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          topic,
                          style: TextStyle(
                            color: hasLesson ? courseColors[course] : Colors.grey,
                            fontStyle: hasLesson ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
