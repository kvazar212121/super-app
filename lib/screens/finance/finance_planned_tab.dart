import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/finance_models.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'finance_utils.dart';

class FinancePlannedTab extends StatelessWidget {
  final List<PlannedPayment> plannedPayments;
  final void Function(PlannedPayment payment) onMarkPaid;
  final void Function(int id) onDelete;

  const FinancePlannedTab({
    super.key,
    required this.plannedPayments,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Kutilayotgan to'lovlar".tr,
                style: TextStyle(
                  color: GlassTokens.primaryText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${'Jami:'.tr} ${plannedPayments.length} ${'ta'.tr}",
                style: TextStyle(
                  color: GlassTokens.secondaryText(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          plannedPayments.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.calendarCheck,
                        size: 44,
                        color: GlassTokens.secondaryText(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Rejalashtirilgan to'lovlar yo'q".tr,
                        style: TextStyle(
                          color: GlassTokens.secondaryText(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plannedPayments.length,
                  itemBuilder: (context, index) {
                    final item = plannedPayments[index];
                    final isOverdue =
                        item.dueDate.isBefore(today) && !item.isPaid;
                    final dueStr =
                        "${item.dueDate.day}-${financeMonthNameUz(item.dueDate.month).tr.substring(0, 3)} ${item.dueDate.year}";

                    Color statusColor = Colors.orangeAccent;
                    String statusText = "Kutilmoqda".tr;
                    if (item.isPaid) {
                      statusColor = Colors.greenAccent;
                      statusText = "To'landi".tr;
                    } else if (isOverdue) {
                      statusColor = Colors.redAccent;
                      statusText = "Muddati o'tdi".tr;
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isOverdue
                                  ? Colors.redAccent
                                  : GlassTokens.glassBorder(context),
                            ),
                            boxShadow: GlassTokens.glassShadow(context),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.category == 'Kredit'
                                          ? LucideIcons.landmark
                                          : item.category == 'Obuna'
                                          ? LucideIcons.refreshCw
                                          : item.category == 'Qarz'
                                          ? LucideIcons.hand
                                          : LucideIcons.moreHorizontal,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: GlassTokens.primaryText(
                                              context,
                                            ),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.category.tr,
                                          style: TextStyle(
                                            color: GlassTokens.secondaryText(
                                              context,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatFinanceCurrency(item.amount),
                                    style: TextStyle(
                                      color: GlassTokens.primaryText(context),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color: GlassTokens.glassBorder(context),
                                height: 1,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.calendar,
                                        size: 14,
                                        color: GlassTokens.secondaryText(
                                          context,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dueStr,
                                        style: TextStyle(
                                          color: GlassTokens.secondaryText(
                                            context,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (item.isRecurring) ...[
                                        const SizedBox(width: 12),
                                        const Icon(
                                          LucideIcons.repeat,
                                          size: 12,
                                          color: Colors.blueAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Obuna".tr,
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!item.isPaid) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () => onMarkPaid(item),
                                        icon: const Icon(
                                          LucideIcons.check,
                                          size: 16,
                                        ),
                                        label: Text(
                                          "To'landi".tr,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        onPressed: () => onDelete(item.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
