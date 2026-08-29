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
                  color: LuxTokens.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.inbox,
                  size: 40,
                  color: Color(0xFF140D02),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Buyurtmalar topilmadi'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF140D02),
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
                  width: 46,
                  height: 46,
                  decoration: LuxTokens.goldBoxDecoration(radius: 14),
                  child: Icon(icon, color: const Color(0xFF140D02), size: 22),
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
                        style: const TextStyle(
                          color: Color(0xFF8A5D0B),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Color(0xFF140D02),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.address,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF140D02),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            Divider(height: 24, color: GlassTokens.glassBorder(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: Color(0xFF140D02),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF140D02),
                      ),
                    ),
                  ],
                ),
                Text(
                  "${order.price.toStringAsFixed(0)} ${"so'm".tr}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF140D02),
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
        bg = const Color(0xFFFFFBEB); // Warm Gold Alabaster fon
        border = const Color(0xFFFDE68A); // Oltin ramka
        text = const Color(0xFF8A5D0B); // 24K Oltin to'q braun matn
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 5),
          Text(
            statusText,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
