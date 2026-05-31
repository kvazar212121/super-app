import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';

class ProviderCalendarWidget extends StatefulWidget {
  final String categoryKey;
  const ProviderCalendarWidget({super.key, required this.categoryKey});

  @override
  State<ProviderCalendarWidget> createState() => _ProviderCalendarWidgetState();
}

class _ProviderCalendarWidgetState extends State<ProviderCalendarWidget> {
  final _portal = ProviderPortalService();
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  List<String> _busySlots = [];
  List<Map<String, dynamic>> _orders = [];

  static const _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _portal.getCalendar(widget.categoryKey, _selectedDate);
      _busySlots = (data['busy_slots'] as List<dynamic>? ?? []).cast<String>();
      _orders = (data['orders'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      _busySlots = [];
      _orders = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM, yyyy', 'uz_UZ').format(_selectedDate),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Buyurtmalar: ${_orders.length}',
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
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _load();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              return InkWell(
                onTap: () {
                  setState(() => _selectedDate = date);
                  _load();
                },
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
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E', 'uz_UZ').format(date),
                        style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey),
                      ),
                      Text(
                        '${date.day}',
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
        ),
        const SizedBox(height: 24),
        Text('Ish vaqtlari (DB buyurtmalari)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final isBusy = _busySlots.contains(slot);
            return Container(
              decoration: BoxDecoration(
                color: isBusy ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isBusy ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: isBusy ? FontWeight.bold : FontWeight.normal,
                    color: isBusy ? const Color(0xFF6366F1) : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
