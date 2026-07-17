import 'package:flutter/material.dart';
import '../../models/finance_models.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'finance_utils.dart';

class FinanceCategoryBreakdown extends StatelessWidget {
  final FinanceStats stats;
  final List<Color> chartColors;

  const FinanceCategoryBreakdown({
    super.key,
    required this.stats,
    required this.chartColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Xarajatlar ulushi".tr,
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.categoryStats.length,
            itemBuilder: (context, index) {
              final cat = stats.categoryStats[index];
              final color = chartColors[index % chartColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.category.tr,
                        style: TextStyle(
                          color: GlassTokens.primaryText(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "${cat.percentage.toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      formatFinanceCurrency(cat.amount),
                      style: TextStyle(
                        color: GlassTokens.primaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
