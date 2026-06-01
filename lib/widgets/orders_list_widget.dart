import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../screens/order_detail_screen.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';

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
        child: GlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.inbox, size: 48, color: GlassTokens.secondaryText(context)),
              const SizedBox(height: 12),
              Text(
                'Buyurtmalar topilmadi',
                style: TextStyle(color: GlassTokens.secondaryText(context)),
              ),
            ],
          ),
        ),
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

    return GlassSurface(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTokens.radiusLg,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ),
        borderRadius: BorderRadius.circular(GlassTokens.radiusLg),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.serviceName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                order.statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          if (order.address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(LucideIcons.mapPin, size: 14, color: GlassTokens.secondaryText(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address,
                  style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],
          Divider(
            height: 24,
            color: GlassTokens.glassBorder(context).withValues(alpha: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(LucideIcons.calendar, size: 14, color: GlassTokens.secondaryText(context)),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
              ]),
              Text(
                "${order.price.toStringAsFixed(0)} so'm",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
