import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AcCalendarWidget extends StatefulWidget {
  const AcCalendarWidget({super.key});

  @override
  State<AcCalendarWidget> createState() => _AcCalendarWidgetState();
}

class _AcCalendarWidgetState extends State<AcCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, Map<String, String>> _schedule = {
    '09:00': {
      'service': 'Samsung Montaj',
      'address': 'Chilonzor',
      'status': 'Tugallangan',
      'gas': 'R410A',
    },
    '11:00': {
      'service': 'LG Profilaktika',
      'address': 'Yunusabad',
      'status': 'Tugallangan',
      'gas': '-',
    },
    '14:00': {
      'service': 'General Gaz to\'ldirish',
      'address': 'Sergeli',
      'status': 'Bajarilmoqda',
      'gas': 'R22',
    },
    '16:00': {
      'service': 'Samsung Demontaj',
      'address': 'Mirzo Ulug\'bek',
      'status': 'Rejalashtirilgan',
      'gas': 'R410A',
    },
  };

  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
  ];

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
              'Kunlik reja',
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
          icon: const Icon(LucideIcons.calendarDays, color: Color(0xFF6366F1)),
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
                color: isSelected ? const Color(0xFF6366F1) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
        _buildLegendItem('Bajarilmoqda', const Color(0xFF6366F1)),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeGrid(ThemeData theme) {
    final statusColors = {
      'Tugallangan': const Color(0xFF10B981),
      'Bajarilmoqda': const Color(0xFF6366F1),
      'Rejalashtirilgan': const Color(0xFF8B5CF6),
    };

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final job = _schedule[slot];
        final isBooked = job != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isBooked
                ? const Color(0xFF6366F1).withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBooked
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: isBooked ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  slot,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: isBooked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColors[job!['status']],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job!['service']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                job!['address']!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (job!['gas'] != '-') ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.gauge, size: 14, color: Color(0xFF6366F1)),
                                const SizedBox(width: 4),
                                Text(
                                  'Gaz: ${job!['gas']}',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            job!['status']!,
                            style: TextStyle(
                              color: statusColors[job!['status']],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Bo\'sh',
                        style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                      ),
              ),
              if (!isBooked)
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Qabul qilish'),
                ),
            ],
          ),
        );
      },
    );
  }
}
