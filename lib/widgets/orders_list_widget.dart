import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';

class OrdersListWidget extends StatelessWidget {
  final String filter;
  const OrdersListWidget({super.key, required this.filter});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.accepted: return Colors.blue;
      case OrderStatus.inProgress: return Colors.purple;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  List<ServiceOrder> _apply(AppProvider p) {
    if (filter == "active") return p.activeOrders;
    if (filter == "completed") return p.completedOrders;
    return p.orders;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final orders = _apply(provider);
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.inbox, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Buyurtmalar topilmadi", style: TextStyle(color: Colors.grey[600])),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _OrderCard(
        order: orders[i],
        statusColor: _getStatusColor(orders[i].status),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ServiceOrder order;
  final Color statusColor;
  const _OrderCard({required this.order, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final accent = order.category.accent;
    final icon = order.category.icon;
    final two = (int n) => n.toString().padLeft(2, '0');
    final dateStr =
        "${two(order.date.day)}.${two(order.date.month)}.${order.date.year}  ${two(order.date.hour)}:${two(order.date.minute)}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.serviceName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(order.providerName,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
            if (order.address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(LucideIcons.mapPin, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(LucideIcons.calendar, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 12)),
                ]),
                Text("${order.price.toStringAsFixed(0)} so'm",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
