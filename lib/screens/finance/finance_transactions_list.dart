import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/finance_models.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'finance_utils.dart';

class FinanceTransactionsList extends StatelessWidget {
  final List<FinanceRecord> records;
  final void Function(int id) onDelete;

  const FinanceTransactionsList({
    super.key,
    required this.records,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Oxirgi amallar".tr,
            style: TextStyle(
              color: GlassTokens.secondaryText(context),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          records.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  child: Text(
                    "Tranzaksiyalar mavjud emas".tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];
                    final isExpense = item.type == "expense";
                    final dateStr =
                        "${item.date.day}-${financeMonthNameUz(item.date.month).tr.substring(0, 3)}";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: GlassTokens.glassBorder(context),
                        ),
                        boxShadow: GlassTokens.glassShadow(context),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : Colors.greenAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpense
                                  ? LucideIcons.arrowUpRight
                                  : LucideIcons.arrowDownLeft,
                              color: isExpense
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category.tr,
                                  style: TextStyle(
                                    color: GlassTokens.primaryText(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.userName != null
                                      ? '${item.userName} · ${item.description ?? dateStr}'
                                      : (item.description ?? dateStr),
                                  style: TextStyle(
                                    color: item.userName != null
                                        ? const Color(0xFF34D399)
                                        : GlassTokens.secondaryText(context),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isExpense ? '-' : '+'}${formatFinanceCurrency(item.amount)}",
                                style: TextStyle(
                                  color: isExpense
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: GlassTokens.secondaryText(context),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              LucideIcons.trash2,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            onPressed: () => onDelete(item.id),
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
