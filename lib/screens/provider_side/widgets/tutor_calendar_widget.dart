import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TutorCalendarWidget extends StatefulWidget {
  const TutorCalendarWidget({super.key});

  @override
  State<TutorCalendarWidget> createState() => _TutorCalendarWidgetState();
}

class _TutorCalendarWidgetState extends State<TutorCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, List<Map<String, String>>> _schedule = {
    '09:00': [
      {'subject': 'Matematika', 'student': 'Karimova N.', 'format': 'Online', 'status': 'Tugallangan'},
    ],
    '10:00': [
      {'subject': 'Ingliz tili', 'student': 'Rustamov A.', 'format': 'Online', 'status': 'Tugallangan'},
    ],
    '11:00': [
      {'subject': 'Fizika', 'student': 'Toshmatov B.', 'format': 'Offline (uyda)', 'status': 'Tugallangan'},
    ],
    '14:00': [
      {'subject': 'Matematika', 'student': 'Sobirov K.', 'format': 'Online', 'status': 'Bajarilmoqda'},
    ],
    '15:00': [
      {'subject': 'Test tayyorlov', 'student': 'Azimova D.', 'format': 'Offline (uyda)', 'status': 'Bajarilmoqda'},
    ],
    '16:00': [
      {'subject': 'Ingliz tili', 'student': 'Jabborov M.', 'format': 'Online', 'status': 'Rejalashtirilgan'},
    ],
    '17:00': [
      {'subject': 'Fizika', 'student': 'Xasanov R.', 'format': 'Offline (uyda)', 'status': 'Rejalashtirilgan'},
    ],
    '18:00': [
      {'subject': 'Matematika', 'student': 'Mirzovali S.', 'format': 'Online', 'status': 'Rejalashtirilgan'},
    ],
  };

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00',
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tugallangan':
        return const Color(0xFF10B981);
      case 'Bajarilmoqda':
        return const Color(0xFF7C3AED);
      case 'Rejalashtirilgan':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  IconData _getFormatIcon(String format) {
    return format.contains('Online') ? LucideIcons.wifi : LucideIcons.home;
  }

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
        _buildScheduleList(theme),
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
          icon: const Icon(LucideIcons.calendarDays, color: Color(0xFF7C3AED)),
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
                color: isSelected ? const Color(0xFF7C3AED) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
        _buildLegendItem('Tugallangan', const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _buildLegendItem('Bajarilmoqda', const Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        _buildLegendItem('Rejalashtirilgan', const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildScheduleList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final lessons = _schedule[slot] ?? [];

        if (lessons.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text(
                  slot,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  'Bo\'sh',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: lessons.map((lesson) {
            final statusColor = _getStatusColor(lesson['status']!);
            final formatIcon = _getFormatIcon(lesson['format']!);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        slot,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lesson['status']!,
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.bookOpen, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['subject']!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lesson['student']!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(formatIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            lesson['format']!,
                            style: TextStyle(fontSize: 12, color: statusColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
