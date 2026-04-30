import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/service_order.dart';

class OrdersListWidget extends StatelessWidget {
  final String filter;
  const OrdersListWidget({super.key, required this.filter});

  List<ServiceOrder> get _filteredOrders {
    final orders = ServiceOrder.demoOrders;
    if (filter == "all") return orders;
    if (filter == "active") {
      return orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).toList();
    }
    if (filter == "completed") {
      return orders.where((o) => o.status == OrderStatus.completed).toList();
    }
    return orders;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.accepted: return Colors.blue;
      case OrderStatus.inProgress: return Colors.purple;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;
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
      itemBuilder: (ctx, i) => _OrderCard(order: orders[i], statusColor: _getStatusColor(orders[i].status)),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ServiceOrder order;
  final Color statusColor;
  const _OrderCard({required this.order, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final accent = _serviceAccentColor(order.serviceIcon);
    final icon = _serviceIconData(order.serviceIcon);
    final dateStr = "${order.date.day}.${order.date.month}.${order.date.year}";
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accent)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(order.providerName, style: const TextStyle(color: Colors.grey)),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_getStatusText(order.status),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w500))),
            ]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Sana: $dateStr", style: const TextStyle(fontSize: 12)),
              Text("Narx: ${order.price.toStringAsFixed(0)} so'm", style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return "Kutilmoqda";
      case OrderStatus.accepted: return "Qabul qilindi";
      case OrderStatus.inProgress: return "Jarayonda";
      case OrderStatus.completed: return "Yakunlandi";
      case OrderStatus.cancelled: return "Bekor qilindi";
    }
  }
}

IconData _serviceIconData(String name) {
  switch (name) {
    case "scissors":
      return LucideIcons.scissors;
    case "zap":
      return LucideIcons.zap;
    case "droplet":
      return LucideIcons.droplet;
    default:
      return LucideIcons.briefcase;
  }
}

Color _serviceAccentColor(String name) {
  switch (name) {
    case "scissors":
      return Colors.indigo;
    case "zap":
      return Colors.amber.shade700;
    case "droplet":
      return Colors.lightBlue;
    default:
      return Colors.blueGrey;
  }
}
