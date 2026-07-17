import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'finance_utils.dart';

class FinanceMonthSelector extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const FinanceMonthSelector({
    super.key,
    required this.currentMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.chevronLeft,
              color: GlassTokens.primaryText(context),
            ),
            onPressed: onPrev,
          ),
          Text(
            "${financeMonthNameUz(currentMonth.month).tr}, ${currentMonth.year}",
            style: TextStyle(
              color: GlassTokens.primaryText(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.chevronRight,
              color: GlassTokens.primaryText(context),
            ),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
