import 'package:flutter/material.dart';
import '../models/service_order.dart';

class OrderTimelineStep {
  final String label;
  final OrderStatus status;
  final bool isDone;
  final bool isActive;
  final bool isFailed;

  const OrderTimelineStep({
    required this.label,
    required this.status,
    this.isDone = false,
    this.isActive = false,
    this.isFailed = false,
  });
}

/// Buyurtma holati ketma-ketligi.
List<OrderTimelineStep> buildOrderTimeline(OrderStatus current) {
  const steps = [
    (OrderStatus.pending, 'Yuborildi'),
    (OrderStatus.accepted, 'Qabul qilindi'),
    (OrderStatus.inProgress, 'Jarayonda'),
    (OrderStatus.completed, 'Yakunlandi'),
  ];

  if (current == OrderStatus.cancelled) {
    return [
      const OrderTimelineStep(
        label: 'Yuborildi',
        status: OrderStatus.pending,
        isDone: true,
      ),
      const OrderTimelineStep(
        label: 'Bekor qilindi',
        status: OrderStatus.cancelled,
        isActive: true,
        isFailed: true,
      ),
    ];
  }

  final currentIndex = switch (current) {
    OrderStatus.pending => 0,
    OrderStatus.accepted => 1,
    OrderStatus.inProgress => 2,
    OrderStatus.completed => 3,
    OrderStatus.cancelled => -1,
  };

  return steps.asMap().entries.map((e) {
    final i = e.key;
    final (status, label) = e.value;
    return OrderTimelineStep(
      label: label,
      status: status,
      isDone: i < currentIndex,
      isActive: i == currentIndex,
    );
  }).toList();
}

class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus status;
  final Color accent;

  const OrderStatusTimeline({
    super.key,
    required this.status,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final steps = buildOrderTimeline(status);
    final theme = Theme.of(context);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;

        Color dotColor;
        if (step.isFailed) {
          dotColor = const Color(0xFFEF4444);
        } else if (step.isActive) {
          dotColor = accent;
        } else if (step.isDone) {
          dotColor = const Color(0xFF10B981);
        } else {
          dotColor = theme.colorScheme.outlineVariant;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: step.isActive
                            ? Border.all(color: accent.withValues(alpha: 0.4), width: 3)
                            : null,
                      ),
                      child: step.isDone
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: step.isDone
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: step.isActive ? FontWeight.bold : FontWeight.w500,
                      color: step.isActive || step.isDone
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: step.isActive ? 15 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
