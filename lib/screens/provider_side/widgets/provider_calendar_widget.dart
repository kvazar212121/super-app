import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_availability_service.dart';
import '../../../services/provider_portal_service.dart';

class ProviderCalendarWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderCalendarWidget({
    super.key,
    required this.categoryKey,
    this.accent = const Color(0xFF6366F1),
  });

  @override
  State<ProviderCalendarWidget> createState() => _ProviderCalendarWidgetState();
}

class _ProviderCalendarWidgetState extends State<ProviderCalendarWidget> {
  final _portal = ProviderPortalService();
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  List<String> _timeSlots = List.of(ProviderAvailability.defaultSlots);
  List<String> _busySlots = [];
  List<Map<String, dynamic>> _orders = [];
  int? _actingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _portal.getMe(widget.categoryKey),
        _portal.getCalendar(widget.categoryKey, _selectedDate),
      ]);
      final meta = results[0]['metadata_json'] as Map<String, dynamic>? ?? {};
      final slots = (meta['time_slots'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      if (slots != null && slots.isNotEmpty) {
        _timeSlots = slots;
      }

      final data = results[1];
      _busySlots = (data['busy_slots'] as List<dynamic>? ?? [])
          .map((e) => _normalizeSlot(e.toString()))
          .toList();
      _orders = (data['orders'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {
      _busySlots = [];
      _orders = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  String _normalizeSlot(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  bool _isBusy(String slot) => _busySlots.contains(_normalizeSlot(slot));

  Future<void> _updateStatus(int orderId, String status) async {
    setState(() => _actingId = orderId);
    try {
      await _portal.updateOrderStatus(widget.categoryKey, orderId, status);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status yangilanmadi')),
        );
      }
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
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
              icon: Icon(LucideIcons.refreshCw, color: widget.accent),
              onPressed: _load,
            ),
            IconButton(
              icon: Icon(LucideIcons.calendarDays, color: widget.accent),
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
                    color: isSelected ? widget.accent : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? widget.accent
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
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
        Text(
          'Ish vaqtlari',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
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
            final isBusy = _isBusy(slot);
            return Container(
              decoration: BoxDecoration(
                color: isBusy
                    ? widget.accent.withValues(alpha: 0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isBusy
                      ? widget.accent
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: isBusy ? FontWeight.bold : FontWeight.normal,
                    color: isBusy ? widget.accent : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
        if (_orders.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Kun buyurtmalari',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._orders.map((o) => _orderCard(o, theme)),
        ],
      ],
    );
  }

  Widget _orderCard(Map<String, dynamic> o, ThemeData theme) {
    final id = o['id'] as int;
    final acting = _actingId == id;
    final status = o['status'] as String? ?? '';
    final time = o['date'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(o['date'] as String))
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: widget.accent)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o['user_name'] as String? ?? 'Mijoz',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(_statusLabel(status), style: theme.textTheme.bodySmall),
            ],
          ),
          Text(
            '${o['service_name'] ?? ''} · ${NumberFormat('#,###').format((o['price'] as num?) ?? 0)} so\'m',
            style: theme.textTheme.bodySmall,
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: acting ? null : () => _updateStatus(id, 'cancelled'),
                    child: const Text('Rad'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: acting ? null : () => _updateStatus(id, 'confirmed'),
                    style: FilledButton.styleFrom(backgroundColor: widget.accent),
                    child: const Text('Qabul'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'confirmed') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: acting ? null : () => _updateStatus(id, 'completed'),
                child: const Text('Bajarildi deb belgilash'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Kutilmoqda';
      case 'confirmed':
        return 'Tasdiqlangan';
      case 'in_progress':
        return 'Jarayonda';
      case 'completed':
        return 'Bajarildi';
      case 'cancelled':
        return 'Bekor';
      default:
        return status;
    }
  }
}
