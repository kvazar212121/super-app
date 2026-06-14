import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../services/provider_portal_service.dart';

/// Yangi (pending) buyurtmalar — qabul / rad etish.
class ProviderPendingOrdersWidget extends StatefulWidget {
  final String categoryKey;
  final Color accent;
  final VoidCallback? onChanged;

  const ProviderPendingOrdersWidget({
    super.key,
    required this.categoryKey,
    required this.accent,
    this.onChanged,
  });

  @override
  State<ProviderPendingOrdersWidget> createState() =>
      ProviderPendingOrdersWidgetState();
}

class ProviderPendingOrdersWidgetState
    extends State<ProviderPendingOrdersWidget> {
  final _portal = ProviderPortalService();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  int? _actingId;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    try {
      _orders = await _portal.getPendingOrders(widget.categoryKey);
    } catch (_) {
      _orders = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _respond(int orderId, String status) async {
    setState(() => _actingId = orderId);
    try {
      await _portal.updateOrderStatus(widget.categoryKey, orderId, status);
      await load();
      widget.onChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmed'
                  ? 'Buyurtma qabul qilindi'
                  : 'Buyurtma rad etildi',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amal bajarilmadi')),
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
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_orders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.bellRing, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Yangi buyurtmalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_orders.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._orders.map((o) => _tile(o, theme)),
      ],
    );
  }

  Widget _tile(Map<String, dynamic> o, ThemeData theme) {
    final id = o['id'] as int;
    final acting = _actingId == id;
    final time = o['date'] != null
        ? DateFormat('dd.MM HH:mm').format(DateTime.parse(o['date'] as String))
        : '—';
    final price = (o['price'] as num?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o['user_name'] as String? ?? 'Mijoz',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                    ),
                    Text(
                      '${o['service_name'] ?? ''} · $time',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    if ((o['notes'] as String?)?.isNotEmpty == true)
                      Text(
                        o['notes'] as String,
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(price)} so\'m',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: acting ? null : () => _respond(id, 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Rad etish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: acting ? null : () => _respond(id, 'confirmed'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: acting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Qabul qilish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
