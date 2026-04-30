import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';

/// Asosiy ekrandagi "joriy buyurtma" karta-banneri.
/// Faol buyurtma bo'lmasa hech narsa ko'rsatmaydi.
class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({super.key});

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.accepted => Colors.blue,
        OrderStatus.inProgress => Colors.purple,
        OrderStatus.completed => Colors.green,
        OrderStatus.cancelled => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final active = context.watch<AppProvider>().activeOrders;
    if (active.isEmpty) return const SizedBox.shrink();

    final order = active.first;
    final accent = order.category.accent;
    final statusColor = _statusColor(order.status);
    final two = (int n) => n.toString().padLeft(2, '0');
    final dateStr =
        "${two(order.date.day)}.${two(order.date.month)}  ${two(order.date.hour)}:${two(order.date.minute)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(order.category.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.statusText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(children: [
                      const Icon(LucideIcons.clock,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  order.serviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.price.toStringAsFixed(0)} so‘m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }
}
