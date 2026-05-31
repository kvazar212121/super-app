import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CourierCalendarWidget extends StatefulWidget {
  const CourierCalendarWidget({super.key});

  @override
  State<CourierCalendarWidget> createState() => _CourierCalendarWidgetState();
}

class _CourierCalendarWidgetState extends State<CourierCalendarWidget> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _deliveries = [
    {
      'time': '09:00',
      'type': 'Hujjat',
      'weight': '0.3 kg',
      'distance': '5.2 km',
      'status': 'Tugallangan',
    },
    {
      'time': '11:30',
      'type': 'Sovg\'a',
      'weight': '1.8 kg',
      'distance': '8.4 km',
      'status': 'Bajarilmoqda',
    },
    {
      'time': '14:00',
      'type': 'Kichik yuk',
      'weight': '4.5 kg',
      'distance': '12.1 km',
      'status': 'Rejalashtirilgan',
    },
    {
      'time': '16:30',
      'type': 'Katta yuk',
      'weight': '15.0 kg',
      'distance': '20.3 km',
      'status': 'Rejalashtirilgan',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tugallangan':
        return const Color(0xFF10B981);
      case 'Bajarilmoqda':
        return const Color(0xFFFFB300);
      case 'Rejalashtirilgan':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Hujjat':
        return LucideIcons.fileText;
      case 'Sovg\'a':
        return LucideIcons.gift;
      case 'Kichik yuk':
        return LucideIcons.package;
      case 'Katta yuk':
        return LucideIcons.truck;
      default:
        return LucideIcons.package;
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
              'Yetkazishlar',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildLegend(theme),
          ],
        ),
        const SizedBox(height: 16),
        _buildDeliveryList(theme),
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
          icon: const Icon(LucideIcons.calendarDays, color: Color(0xFFFFB300)),
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
                color: isSelected ? const Color(0xFFFFB300) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFB300) : Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.3),
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
        _buildLegendItem('Bajarilmoqda', const Color(0xFFFFB300)),
        const SizedBox(width: 12),
        _buildLegendItem('Rejalashtirilgan', const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
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

  Widget _buildDeliveryList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _deliveries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _deliveries[index];
        final statusColor = _getStatusColor(item['status'] as String);

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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(item['type'] as String),
                      color: const Color(0xFFFFB300),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['type'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item['weight']} • ${item['distance']}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      item['time'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
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
