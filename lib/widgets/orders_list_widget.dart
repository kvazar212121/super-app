import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../screens/order_detail_screen.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';
import 'glass/glass_surface.dart';
import '../theme/lux_tokens.dart';

class OrdersListWidget extends StatelessWidget {
  final String filter;
  const OrdersListWidget({super.key, required this.filter});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return LuxTokens.gold;
      case OrderStatus.onTheWay:
        return LuxTokens.goldSoft;
      case OrderStatus.arrived:
        return LuxTokens.gold;
      case OrderStatus.preparing:
        return Colors.orangeAccent;
      case OrderStatus.inProgress:
        return LuxTokens.gold;
      case OrderStatus.delivered:
        return Colors.greenAccent;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.awaitingConfirmation:
        return LuxTokens.textMuted;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.noShow:
        return Colors.grey;
      case OrderStatus.disputed:
        return Colors.redAccent;
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
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          borderRadius: GlassTokens.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A43).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.inbox,
                  size: 40,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Buyurtmalar topilmadi'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
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
    final icon = order.category.icon;
    String two(int n) => n.toString().padLeft(2, '0');
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
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF102A43), size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.serviceName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      Text(
                        order.providerName,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  status: order.status,
                  statusText: order.statusText,
                ),
              ],
            ),
            if (order.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            Divider(height: 16, color: GlassTokens.glassBorder(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                Text(
                  "${order.price.toStringAsFixed(0)} ${"so'm".tr}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    color: Color(0xFF0F172A),
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

/// Hashamatli status nishoni (bekor qilingan, yakunlangan va faol holatlar uchun).
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String statusText;

  const _StatusBadge({required this.status, required this.statusText});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon;

    switch (status) {
      case OrderStatus.cancelled:
      case OrderStatus.disputed:
      case OrderStatus.noShow:
        bg = const Color(0xFFFFF1F2); // Rose Alabaster yumshoq fon
        border = const Color(0xFFFECDD3); // Rose Gold nozik ramka
        text = const Color(0xFF9F1239); // Deep Burgundy Crimson to'q matn
        icon = LucideIcons.circleX;
        break;

      case OrderStatus.completed:
      case OrderStatus.delivered:
        bg = const Color(0xFFF0FDF4); // Mint Emerald fon
        border = const Color(0xFFBBF7D0); // Emerald ramka
        text = const Color(0xFF15803D); // To'q zumrad yashil matn
        icon = LucideIcons.circleCheck;
        break;

      case OrderStatus.accepted:
      case OrderStatus.inProgress:
      case OrderStatus.arrived:
      case OrderStatus.onTheWay:
        bg = const Color(0xFFEFF6FF); // Light blue fon
        border = const Color(0xFFBFDBFE); // Light blue ramka
        text = const Color(0xFF1E40AF); // Deep blue matn
        icon = LucideIcons.sparkles;
        break;

      case OrderStatus.pending:
      case OrderStatus.preparing:
      case OrderStatus.awaitingConfirmation:
        bg = const Color(0xFFFFF7ED); // Amber fon
        border = const Color(0xFFFED7AA); // Amber ramka
        text = const Color(0xFFC2410C); // Warm Amber matn
        icon = LucideIcons.clock;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: text,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
