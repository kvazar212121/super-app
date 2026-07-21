import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/finance_models.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'finance_utils.dart';

class FinanceBalanceCard extends StatelessWidget {
  final FinanceStats? stats;

  const FinanceBalanceCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final income = stats?.totalIncome ?? 0.0;
    final expense = stats?.totalExpense ?? 0.0;
    final balance = stats?.balance ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GlassTokens.glassBorder(context)),
              boxShadow: GlassTokens.glassShadow(context),
            ),
            child: Column(
              children: [
                Text(
                  "Jami Balans".tr,
                  style: TextStyle(
                    color: GlassTokens.secondaryText(context),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatFinanceCurrency(balance),
                  style: TextStyle(
                    color: balance >= 0
                        ? GlassTokens.primaryText(context)
                        : Colors.redAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.arrowDownLeft,
                                  color: Colors.greenAccent,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Daromad".tr,
                                style: TextStyle(
                                  color: GlassTokens.secondaryText(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatFinanceCurrency(income),
                            style: TextStyle(
                              color: GlassTokens.primaryText(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: GlassTokens.glassBorder(context)),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.arrowUpRight,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Xarajat".tr,
                                style: TextStyle(
                                  color: GlassTokens.secondaryText(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatFinanceCurrency(expense),
                            style: TextStyle(
                              color: GlassTokens.primaryText(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
