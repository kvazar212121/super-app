import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../services/call_service.dart';
import '../theme/glass_tokens.dart';
import 'calls/call_screen.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_surface.dart';
import '../widgets/order_status_timeline.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _cancelling = false;

  ServiceOrder? _findOrder(AppProvider p) {
    for (final o in p.orders) {
      if (o.id == widget.orderId) return o;
    }
    return null;
  }

  Future<void> _cancelOrder(AppProvider p, ServiceOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buyurtmani bekor qilish'),
        content: const Text('Haqiqatan ham buyurtmani bekor qilmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await p.cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyurtma bekor qilindi')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bekor qilib bo\'lmadi')),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending => const Color(0xFFF59E0B),
        OrderStatus.accepted => const Color(0xFF3B82F6),
        OrderStatus.inProgress => const Color(0xFFA855F7),
        OrderStatus.completed => const Color(0xFF10B981),
        OrderStatus.cancelled => const Color(0xFFEF4444),
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final order = _findOrder(app);

    if (order == null) {
      return GlassScaffold(
        showBackButton: true,
        title: 'Buyurtma',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => app.fetchOrders(),
                child: const Text('Yangilash'),
              ),
            ],
          ),
        ),
      );
    }

    final accent = order.category.accent;
    final statusColor = _statusColor(order.status);
    final two = (int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(order.date.day)}.${two(order.date.month)}.${order.date.year}  '
        '${two(order.date.hour)}:${two(order.date.minute)}';
    final canCancel = order.status == OrderStatus.pending;

    return GlassScaffold(
      showBackButton: true,
      title: 'Buyurtma #${order.id}',
      body: RefreshIndicator(
        onRefresh: () => app.fetchOrders(),
        color: accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: GlassTokens.radiusLg,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(order.category.icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.serviceName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: GlassTokens.primaryText(context),
                          ),
                        ),
                        Text(
                          order.providerName,
                          style: TextStyle(color: GlassTokens.secondaryText(context)),
                        ),
                      ],
                    ),
                  ),
                  if (order.providerId != null)
                    IconButton(
                      icon: const Icon(LucideIcons.phone, color: Colors.green),
                      onPressed: () {
                        CallService().startCall(order.providerId!, order.providerName);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CallScreen(isIncoming: false),
                          ),
                        );
                      },
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: GlassTokens.radiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OrderStatusTimeline(status: order.status, accent: accent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: GlassTokens.radiusLg,
              child: Column(
                children: [
                  _infoRow(context, LucideIcons.calendar, 'Vaqt', dateStr),
                  if (order.address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(context, LucideIcons.mapPin, 'Manzil', order.address),
                  ],
                  if (order.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(context, LucideIcons.messageSquare, 'Izoh', order.notes),
                  ],
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jami',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(order.price)} so\'m',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelling ? null : () => _cancelOrder(app, order),
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.xCircle),
                  label: const Text('Buyurtmani bekor qilish'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: GlassTokens.secondaryText(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context))),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
