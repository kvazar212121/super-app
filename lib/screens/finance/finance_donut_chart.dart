import 'package:flutter/material.dart';
import '../../models/finance_models.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'donut_chart_painter.dart';
import 'finance_utils.dart';

class FinanceDonutChart extends StatelessWidget {
  final FinanceStats stats;
  final List<Color> chartColors;

  const FinanceDonutChart({
    super.key,
    required this.stats,
    required this.chartColors,
  });

  @override
  Widget build(BuildContext context) {
    final expense = stats.totalExpense;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: DonutChartPainter(stats.categoryStats, chartColors),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Jami Xarajat".tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      formatFinanceCurrency(expense),
                      style: TextStyle(
                        color: GlassTokens.primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
