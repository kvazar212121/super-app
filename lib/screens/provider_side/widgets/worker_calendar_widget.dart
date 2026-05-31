import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkerCalendarWidget extends StatefulWidget {
  const WorkerCalendarWidget({super.key});

  @override
  State<WorkerCalendarWidget> createState() => _WorkerCalendarWidgetState();
}

class _WorkerCalendarWidgetState extends State<WorkerCalendarWidget> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _scheduleItems = [
    {
      'time': '08:00 - 12:00',
      'type': 'Yuk tashuvchi',
      'workers': '2 kishi',
      'duration': '4 soat',
      'status': 'Tugallangan',
      'location': 'Chilonzor, 9-kv',
    },
    {
      'time': '13:00 - 18:00',
      'type': 'Qora ishchi',
      'workers': '4 kishi',
      'duration': 'Kunlik',
      'status': 'Bajarilmoqda',
      'location': 'Sergeli, 5-mavze',
    },
    {
      'time': '09:00 - 13:00',
      'type': 'Ko\'chirish',
      'workers': '1 kishi',
      'duration': '4 soat',
      'status': 'Rejalashtirilgan',
      'location': 'Yunusabad, 8-kv',
    },
    {
      'time': '14:00 - 18:00',
      'type': 'Yuk tashuvchi',
      'workers': '3 kishi',
      'duration': '4 soat',
      'status': 'Rejalashtirilgan',
      'location': 'Mirzo Ulug\'bek',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tugallangan':
        return const Color(0xFF10B981);
      case 'Bajarilmoqda':
        return const Color(0xFFF97316);
      case 'Rejalashtirilgan':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
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
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Jadval',
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
          icon: const Icon(LucideIcons.calendarDays, color: Color(0xFFF97316)),
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
                color: isSelected ? const Color(0xFFF97316) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF97316) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
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
        const SizedBox(width: 8),
        _buildLegendItem('Bajarilmoqda', const Color(0xFFF97316)),
        const SizedBox(width: 8),
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
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scheduleItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _scheduleItems[index];
        final statusColor = _getStatusColor(item['status'] as String);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['time'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item['type'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.users, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    item['workers'] as String,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.clock, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    item['duration'] as String,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    item['location'] as String,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
