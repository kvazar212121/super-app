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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: order.serviceColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(order.icon, color: order.serviceColor)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(order.providerName, style: const TextStyle(color: Colors.grey)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_getStatusText(order.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.w500))),
            ]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Sana: ${order.date}", style: const TextStyle(fontSize: 12)),
              Text("Narx: ${order.price} so'm", style: const TextStyle(fontWeight: FontWeight.bold)),
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
