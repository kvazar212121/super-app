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

List<OrderTimelineStep> buildOrderTimeline(OrderStatus current) {
  if (current == OrderStatus.cancelled ||
      current == OrderStatus.noShow ||
      current == OrderStatus.disputed) {
    final label = switch (current) {
      OrderStatus.cancelled => 'Bekor qilindi',
      OrderStatus.noShow => 'Kelmadi',
      OrderStatus.disputed => 'Nizoli',
      _ => 'Xatolik',
    };
    return [
      const OrderTimelineStep(
        label: 'Yuborildi',
        status: OrderStatus.pending,
        isDone: true,
      ),
      OrderTimelineStep(
        label: label,
        status: current,
        isActive: true,
        isFailed: true,
      ),
    ];
  }

  final steps = <(OrderStatus, String)>[
    (OrderStatus.pending, 'Yuborildi'),
    (OrderStatus.accepted, 'Qabul qilindi'),
  ];

  if (current == OrderStatus.onTheWay) {
    steps.add((OrderStatus.onTheWay, 'Yo\'lda'));
  } else if (current == OrderStatus.arrived) {
    steps.add((OrderStatus.arrived, 'Yetib keldi'));
  } else if (current == OrderStatus.preparing) {
    steps.add((OrderStatus.preparing, 'Tayyorlanmoqda'));
  }

  steps.add((OrderStatus.inProgress, 'Jarayonda'));

  if (current == OrderStatus.delivered) {
    steps.add((OrderStatus.delivered, 'Yetkazildi'));
  } else {
    steps.add((OrderStatus.completed, 'Yakunlandi'));
  }

  int currentIndex = 0;
  if (current == OrderStatus.pending)
    currentIndex = 0;
  else if (current == OrderStatus.accepted)
    currentIndex = 1;
  else if (current == OrderStatus.onTheWay ||
      current == OrderStatus.arrived ||
      current == OrderStatus.preparing)
    currentIndex = 2;
  else if (current == OrderStatus.inProgress)
    currentIndex = steps.length - 2;
  else
    currentIndex = steps.length - 1; // delivered or completed

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
                            ? Border.all(color: accent, width: 3)
                            : null,
                      ),
                      child: step.isDone
                          ? const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: step.isDone
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.outlineVariant,
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
                      fontWeight: step.isActive
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: step.isActive || step.isDone
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface,
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
