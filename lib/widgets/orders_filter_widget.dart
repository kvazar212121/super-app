import 'package:flutter/material.dart';
import 'package:super_app/l10n/locale_controller.dart';

/// 3-xonali buyurtmalar filtr paneli.
/// Har bir tugma (tanlanganida) ikkala yon tarafi ham 100% bir xil va teng silliq qayrilgan kapsula (pill) shaklida bo'ladi.
class OrdersFilterWidget extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const OrdersFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Barchasi'.tr, 'value': 'all'},
      {'label': 'Faol'.tr, 'value': 'active'},
      {'label': 'Yakunlangan'.tr, 'value': 'completed'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = currentFilter == item['value'];
          final pillRadius = BorderRadius.circular(999);

          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterChanged(item['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: selected
                    ? BoxDecoration(
                        color: const Color(0xFF102A43),
                        borderRadius: pillRadius,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22102A43),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: pillRadius,
                      ),
                child: Text(
                  item['label']!,
                  textAlign: TextAlign.center,
                  style: selected
                      ? const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        )
                      : const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          color: Color(0xFF0F172A),
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
