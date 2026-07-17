import 'package:flutter/material.dart';
import '../theme/glass_tokens.dart';
import 'glass/glass_surface.dart';
import 'package:super_app/l10n/locale_controller.dart';

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
    return GlassSurface(
      padding: const EdgeInsets.all(6),
      borderRadius: GlassTokens.radiusLg,
      showShadow: false,
      child: Row(
        children: [
          _chip(context, 'Barchasi'.tr, 'all'),
          _chip(context, 'Faol'.tr, 'active'),
          _chip(context, 'Yakunlangan'.tr, 'completed'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    final selected = currentFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3B82F6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: selected
                  ? Colors.white
                  : GlassTokens.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }
}
