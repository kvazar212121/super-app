import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/service_hub_kind.dart';
import '../models/service_order.dart';
import '../providers/app_provider.dart';
import '../screens/order_detail_screen.dart';
import '../theme/glass_tokens.dart';

/// Asosiy ekrandagi "joriy buyurtma" — shaffof gradient glass karta.
class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({super.key});

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending => const Color(0xFFF59E0B),
        OrderStatus.accepted => const Color(0xFF3B82F6),
        OrderStatus.inProgress => const Color(0xFFA855F7),
        OrderStatus.completed => const Color(0xFF10B981),
        OrderStatus.cancelled => const Color(0xFFEF4444),
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
        '${two(order.date.day)}.${two(order.date.month)}  ${two(order.date.hour)}:${two(order.date.minute)}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: order.id),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassTokens.glassBlur,
          sigmaY: GlassTokens.glassBlur,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.75),
                accent.withValues(alpha: 0.45),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(order.category.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.statusText,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
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
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
