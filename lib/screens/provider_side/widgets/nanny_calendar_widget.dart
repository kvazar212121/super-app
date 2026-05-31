import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NannyCalendarWidget extends StatefulWidget {
  const NannyCalendarWidget({super.key});

  @override
  State<NannyCalendarWidget> createState() => _NannyCalendarWidgetState();
}

class _NannyCalendarWidgetState extends State<NannyCalendarWidget> {
  DateTime _selectedDate = DateTime.now();

  final Map<String, List<Map<String, String>>> _appointments = {
    '2026-05-15': [
      {
        'time': '09:00 - 14:00',
        'child': 'Aziza (2 yosh)',
        'parent': 'Aziza Karimova',
        'type': 'To\'liq kun (10 soat)',
        'requirements': 'Allergiya: Sut',
        'status': 'Bajarilmoqda',
      },
      {
        'time': '15:00 - 18:00',
        'child': 'Olim (3+ yosh)',
        'parent': 'Madina Rustamova',
        'type': 'Soatbay (3 soat)',
        'requirements': 'Dori: Vitamin D',
        'status': 'Rejalashtirilgan',
      },
    ],
    '2026-05-16': [
      {
        'time': '08:00 - 13:00',
        'child': 'Sofiya (1 yosh)',
        'parent': 'Dilshod Aliyev',
        'type': 'Yarim kun (5 soat)',
        'requirements': 'Ovqat: Maxsus parhez',
        'status': 'Rejalashtirilgan',
      },
    ],
    '2026-05-17': [
      {
        'time': '20:00 - 04:00',
        'child': 'Amir (2 yosh)',
        'parent': 'Zarina Hakimova',
        'type': 'Tunda (8 soat)',
        'requirements': 'Allergiya: Yongoq',
        'status': 'Rejalashtirilgan',
      },
      {
        'time': '09:00 - 14:00',
        'child': 'Laylo (3+ yosh)',
        'parent': 'Bobur Komilov',
        'type': 'Yarim kun (5 soat)',
        'requirements': '',
        'status': 'Tugallangan',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateKey = DateFormat('yyyy-MM-dd', 'uz_UZ').format(_selectedDate);
    final dayAppointments = _appointments[dateKey] ?? [];

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
        if (dayAppointments.isEmpty)
          _buildEmptyState(theme)
        else
          _buildAppointmentList(dayAppointments, theme),
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
          icon: const Icon(LucideIcons.calendarDays, color: Color(0xFF9333EA)),
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
          final dateKey = DateFormat('yyyy-MM-dd', 'uz_UZ').format(date);
          final hasAppointments = _appointments.containsKey(dateKey);

          return InkWell(
            onTap: () => setState(() => _selectedDate = date),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF9333EA) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF9333EA) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.3),
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
                  if (hasAppointments && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9333EA),
                        shape: BoxShape.circle,
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
        _buildLegendItem('Bajarilmoqda', const Color(0xFF9333EA)),
        const SizedBox(width: 12),
        _buildLegendItem('Rejalashtirilgan', const Color(0xFF6366F1)),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.calendarOff, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Bu kunda reja yo\'q',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Hozircha bu sanada bolalar parvarishi rejalashtirilmagan',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tugallangan':
        return const Color(0xFF10B981);
      case 'Bajarilmoqda':
        return const Color(0xFF9333EA);
      case 'Rejalashtirilgan':
        return const Color(0xFF6366F1);
      default:
        return Colors.grey;
    }
  }

  Widget _buildAppointmentList(List<Map<String, String>> appointments, ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = appointments[index];
        final statusColor = _getStatusColor(item['status']!);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.baby, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['child']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item['parent']!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['status']!,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(item['time']!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(LucideIcons.timer, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['type']!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (item['requirements']!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item['requirements']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
