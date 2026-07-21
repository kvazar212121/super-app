import '../../../utils/call_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_availability_service.dart';
import '../../../services/provider_portal_service.dart';
import 'package:super_app/l10n/locale_controller.dart';

class ProviderCalendarWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const ProviderCalendarWidget({
    super.key,
    required this.categoryKey,
    this.accent = const Color(0xFF2563EB),
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
  Map<String, dynamic>? _provider;

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
      _provider = results[0];
      final meta =
          _provider?['metadata_json'] as Map<String, dynamic>? ??
          _provider?['metadata'] as Map<String, dynamic>? ??
          {};
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
      _orders = (data['orders'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      _busySlots = [];
      _orders = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _isSuspended {
    final meta =
        _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>? ??
        {};
    return meta['is_suspended'] == true;
  }

  List<String> get _blockedDates {
    final meta =
        _provider?['metadata'] as Map<String, dynamic>? ??
        _provider?['metadata_json'] as Map<String, dynamic>? ??
        {};
    final list = meta['blocked_dates'] as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  bool get _isCurrentDateBlocked {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _blockedDates.contains(dateStr);
  }

  Future<void> _toggleSuspension(bool suspended) async {
    if (_provider == null) return;
    setState(() => _loading = true);
    try {
      final meta = Map<String, dynamic>.from(
        _provider?['metadata'] as Map<String, dynamic>? ??
            _provider?['metadata_json'] as Map<String, dynamic>? ??
            {},
      );
      meta['is_suspended'] = suspended;

      await _portal.updateMetadata(widget.categoryKey, meta);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faoliyat holatini yangilab bo\'lmadi')),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlockCurrentDate(bool block) async {
    if (_provider == null) return;
    setState(() => _loading = true);
    try {
      final meta = Map<String, dynamic>.from(
        _provider?['metadata'] as Map<String, dynamic>? ??
            _provider?['metadata_json'] as Map<String, dynamic>? ??
            {},
      );
      final blocked = List<String>.from(_blockedDates);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      if (block) {
        if (!blocked.contains(dateStr)) {
          blocked.add(dateStr);
        }
      } else {
        blocked.remove(dateStr);
      }
      meta['blocked_dates'] = blocked;

      await _portal.updateMetadata(widget.categoryKey, meta);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kun holatini yangilab bo\'lmadi')),
        );
      }
      setState(() => _loading = false);
    }
  }

  String _normalizeSlot(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  bool _isBusy(String slot) =>
      _isCurrentDateBlocked ||
      _isSuspended ||
      _busySlots.contains(_normalizeSlot(slot));

  Future<void> _updateStatus(
    int orderId,
    String status, {
    bool? notifiedClient,
  }) async {
    setState(() => _actingId = orderId);
    try {
      await _portal.updateOrderStatus(
        widget.categoryKey,
        orderId,
        status,
        notifiedClient: notifiedClient,
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status yangilanmadi'.tr)));
      }
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _confirmCancelOrder(int orderId) async {
    final int? doCancel = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Buyurtmani bekor qilish'.tr),
          content: Text(
            'Ushbu buyurtmani qanday bekor qilmoqchisiz?\n\nMijozga vaziyatni tushuntirsangiz reytingingiz tushmaydi.'
                .tr,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(1),
                  icon: const Icon(LucideIcons.phone, color: Colors.green),
                  label: Text('Tel qilib tushuntirish va bekor qilish'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Shunchaki bekor qilish'.tr),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(0),
                  child: const Text(
                    'Orqaga',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (doCancel == 1) {
      final order = _orders.firstWhere(
        (o) => o['id'] == orderId,
        orElse: () => {},
      );
      final userId = order['user_id'] as int?;
      final userName = order['user_name'] as String? ?? 'Mijoz';
      if (userId != null) {
        CallHelper.makeDirectCall(context, userId, userName);
      }
      await _updateStatus(orderId, 'cancelled', notifiedClient: true);
    } else if (doCancel == 2) {
      await _updateStatus(orderId, 'cancelled', notifiedClient: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSuspended = _isSuspended;
    final isBlocked = _isCurrentDateBlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Uzoq muddatli faoliyatni to'xtatish switch card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSuspended ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSuspended ? Colors.red.shade700 : Colors.black,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSuspended ? Icons.pause_circle_filled : Icons.check_circle,
                color: isSuspended ? Colors.red.shade700 : Colors.black,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uzoq muddatga to\'xtatish',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSuspended ? Colors.red.shade900 : Colors.black,
                      ),
                    ),
                    Text(
                      isSuspended
                          ? 'Faoliyatingiz mijozlarga ko\'rinmaydi'
                          : 'Faoliyatingiz mijozlarga ochiq',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSuspended
                            ? Colors.red.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isSuspended,
                onChanged: _toggleSuspension,
                activeThumbColor: Colors.red.shade700,
                activeTrackColor: Colors.red.shade200,
                inactiveThumbColor: Colors.black,
                inactiveTrackColor: Colors.black12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM, yyyy', 'uz_UZ').format(_selectedDate),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Buyurtmalar: ${_orders.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.black),
              onPressed: _load,
            ),
            IconButton(
              icon: const Icon(LucideIcons.calendarDays, color: Colors.black),
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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                    color: isSelected ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.black54,
                      width: 1.5,
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
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Kunlik dam olish kuni toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isBlocked ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                isBlocked
                    ? Icons.calendar_today
                    : Icons.calendar_today_outlined,
                color: isBlocked ? Colors.grey : Colors.black,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugun dam olish kuni',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBlocked ? Colors.grey : Colors.black,
                      ),
                    ),
                    Text(
                      isBlocked
                          ? 'Ushbu kunda mijozlar buyurtma bera olmaydi'
                          : 'Mijozlar buyurtma berishi mumkin',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isBlocked,
                onChanged: _toggleBlockCurrentDate,
                activeThumbColor: Colors.black,
                activeTrackColor: Colors.black12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ish vaqtlari',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
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
            final hasOrder = _orders.any((o) {
              if (o['date'] == null) return false;
              final od = DateTime.parse(o['date']);
              return '${od.hour.toString().padLeft(2, '0')}:${od.minute.toString().padLeft(2, '0')}' ==
                  slot;
            });

            return GestureDetector(
              onTap: () async {
                if (_isCurrentDateBlocked || _isSuspended) return;
                if (hasOrder) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bu vaqtda buyurtma bor'.tr)),
                  );
                  return;
                }

                setState(() => _loading = true);
                try {
                  if (isBusy) {
                    // Try to unblock. We'll fetch blocked times, find the one that covers this slot, and remove it.
                    final blocks = await _portal.getBlockedTimes(
                      widget.categoryKey,
                    );
                    final dateStr = DateFormat(
                      'yyyy-MM-dd',
                    ).format(_selectedDate);
                    for (final b in blocks) {
                      final st = DateTime.parse(b['start_time']).toLocal();
                      final slotTimeStr =
                          '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
                      final blockDateStr = DateFormat('yyyy-MM-dd').format(st);
                      if (blockDateStr == dateStr && slotTimeStr == slot) {
                        await _portal.removeBlockedTime(
                          widget.categoryKey,
                          b['id'],
                        );
                        break;
                      }
                    }
                  } else {
                    // Block the slot
                    final parts = slot.split(':');
                    final h = int.parse(parts[0]);
                    final m = int.parse(parts[1]);
                    final startDt = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      h,
                      m,
                    );
                    final endDt = startDt.add(
                      const Duration(hours: 1),
                    ); // assuming 1 hr slots for UI
                    await _portal.addBlockedTime(widget.categoryKey, {
                      'start_time': startDt.toUtc().toIso8601String(),
                      'end_time': endDt.toUtc().toIso8601String(),
                      'reason': 'Manual block',
                    });
                  }
                  await _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xatolik yuz berdi: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isBusy ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isBusy ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_orders.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final activeOrders = _orders
                  .where(
                    (o) =>
                        o['status'] != 'completed' &&
                        o['status'] != 'cancelled',
                  )
                  .toList();
              final completedOrders = _orders
                  .where((o) => o['status'] == 'completed')
                  .toList();
              final cancelledOrders = _orders
                  .where((o) => o['status'] == 'cancelled')
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeOrders.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Kun buyurtmalari',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activeOrders.map((o) => _orderCard(o, theme)),
                  ],
                  if (completedOrders.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Bajarilganlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...completedOrders.map((o) => _orderCard(o, theme)),
                  ],
                  if (cancelledOrders.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Bekor qilinganlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...cancelledOrders.map((o) => _orderCard(o, theme)),
                  ],
                ],
              );
            },
          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o['user_name'] as String? ?? 'Mijoz',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                    onPressed: acting ? null : () => _confirmCancelOrder(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Rad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: acting
                        ? null
                        : () => _updateStatus(id, 'confirmed'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Qabul',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'confirmed' || status == 'in_progress') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: acting ? null : () => _updateStatus(id, 'completed'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Bajarildi deb belgilash',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (status == 'awaiting_confirmation') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    'Mijoz tasdiqlashi kutilmoqda...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
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
      case 'awaiting_confirmation':
        return 'Tasdiq kutilyapti';
      case 'cancelled':
        return 'Bekor';
      default:
        return status;
    }
  }
}
