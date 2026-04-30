import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/service_order.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyurtmalarim"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ServiceOrder.demoOrders.length,
        itemBuilder: (ctx, i) => _OrderCard(order: ServiceOrder.demoOrders[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Yangi buyurtma yaratildi")),
          );
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text("Yangi"),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ServiceOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(order.serviceIcon), color: Colors.indigo),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${order.date.day}.${order.date.month}.${order.date.year}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${order.price.toStringAsFixed(0)} so'm",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.statusText,
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
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
}
