import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/glass_tokens.dart';
import '../../l10n/locale_controller.dart';
import 'finance_utils.dart';

void showAddTransactionSheet(
  BuildContext context, {
  required List<String> customExpenseCategories,
  required List<String> customIncomeCategories,
  required Future<void> Function(
    String type,
    double amount,
    String category,
    String? description,
    DateTime date,
  )
  onSubmit,
  required VoidCallback onCategoriesChanged,
}) {
  String selectedType = "expense";
  String? selectedCategory;
  final amountController = TextEditingController();
  final descController = TextEditingController();
  DateTime chosenDate = DateTime.now();

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Oziq-ovqat', 'icon': LucideIcons.shoppingBag},
    {'name': 'Transport', 'icon': LucideIcons.car},
    {'name': 'Xaridlar', 'icon': LucideIcons.creditCard},
    {'name': 'Kommunal', 'icon': LucideIcons.home},
    {'name': 'Ko\'ngilochar', 'icon': LucideIcons.gamepad2},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Maosh', 'icon': LucideIcons.banknote},
    {'name': 'Biznes', 'icon': LucideIcons.briefcase},
    {'name': 'Keshbek', 'icon': LucideIcons.coins},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GlassTokens.radiusLg),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final activeCategories = List<Map<String, dynamic>>.from(
            selectedType == "expense" ? expenseCategories : incomeCategories,
          );

          final customCats = selectedType == "expense"
              ? customExpenseCategories
              : customIncomeCategories;
          for (var c in customCats) {
            activeCategories.add({'name': c, 'icon': LucideIcons.tag});
          }
          activeCategories.add({
            'name': 'Boshqa',
            'icon': LucideIcons.moreHorizontal,
          });
          activeCategories.add({
            'name': 'Toifa qo\'shish',
            'icon': LucideIcons.plus,
            'isAdd': true,
          });

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Yangi tranzaksiya".tr,
                        style: TextStyle(
                          color: GlassTokens.primaryText(context),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: GlassTokens.secondaryText(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedType = "expense";
                              selectedCategory = null;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == "expense"
                                  ? Colors.redAccent
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == "expense"
                                    ? Colors.redAccent
                                    : GlassTokens.glassBorder(context),
                              ),
                            ),
                            child: Text(
                              "Xarajat".tr,
                              style: TextStyle(
                                color: selectedType == "expense"
                                    ? Colors.white
                                    : GlassTokens.secondaryText(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedType = "income";
                              selectedCategory = null;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == "income"
                                  ? Colors.green.shade700
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == "income"
                                    ? Colors.green.shade700
                                    : GlassTokens.glassBorder(context),
                              ),
                            ),
                            child: Text(
                              "Daromad".tr,
                              style: TextStyle(
                                color: selectedType == "income"
                                    ? Colors.white
                                    : GlassTokens.secondaryText(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: GlassTokens.primaryText(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: "Summa (UZS)".tr,
                      labelStyle: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.banknote,
                        color: Colors.blueAccent,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: GlassTokens.glassBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Toifani tanlang".tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.25,
                        ),
                    itemCount: activeCategories.length,
                    itemBuilder: (context, index) {
                      final cat = activeCategories[index];
                      final isSelected = selectedCategory == cat['name'];

                      return GestureDetector(
                        onTap: () {
                          if (cat['isAdd'] == true) {
                            _showAddCategoryDialog(
                              context,
                              selectedType,
                              setSheetState,
                              customExpenseCategories,
                              customIncomeCategories,
                              onCategoriesChanged,
                            );
                          } else {
                            setSheetState(() {
                              selectedCategory = cat['name'];
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : GlassTokens.glassBorder(context),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : GlassTokens.secondaryText(context),
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (cat['name'] as String).tr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : GlassTokens.secondaryText(context),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descController,
                    style: TextStyle(color: GlassTokens.primaryText(context)),
                    decoration: InputDecoration(
                      labelText: "Izoh (ixtiyoriy)".tr,
                      labelStyle: TextStyle(
                        color: GlassTokens.secondaryText(context),
                      ),
                      prefixIcon: Icon(
                        LucideIcons.pencil,
                        color: GlassTokens.secondaryText(context),
                        size: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: GlassTokens.glassBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: chosenDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => chosenDate = picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${'Sana:'.tr} ${chosenDate.day}-${financeMonthNameUz(chosenDate.month).tr} ${chosenDate.year}-${'yil'.tr}",
                              style: TextStyle(
                                color: GlassTokens.primaryText(context),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: GlassTokens.secondaryText(context),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Iltimos, to'g'ri summani kiriting".tr,
                              ),
                            ),
                          );
                          return;
                        }
                        if (selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Iltimos, toifani tanlang".tr),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        onSubmit(
                          selectedType,
                          amount,
                          selectedCategory!,
                          descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          chosenDate,
                        );
                      },
                      child: Text(
                        "Saqlash".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showAddCategoryDialog(
  BuildContext context,
  String type,
  StateSetter setSheetState,
  List<String> customExpenseCategories,
  List<String> customIncomeCategories,
  VoidCallback onCategoriesChanged,
) {
  final catController = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Yangi toifa qo\'shish'.tr,
          style: TextStyle(
            color: GlassTokens.primaryText(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: catController,
          style: TextStyle(color: GlassTokens.primaryText(context)),
          decoration: InputDecoration(
            hintText: 'Toifa nomi'.tr,
            hintStyle: TextStyle(color: GlassTokens.secondaryText(context)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: GlassTokens.glassBorder(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Bekor qilish'.tr,
              style: TextStyle(color: GlassTokens.secondaryText(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final name = catController.text.trim();
              if (name.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                if (type == 'expense') {
                  customExpenseCategories.add(name);
                  await prefs.setStringList(
                    'customExpenseCategories',
                    customExpenseCategories,
                  );
                } else {
                  customIncomeCategories.add(name);
                  await prefs.setStringList(
                    'customIncomeCategories',
                    customIncomeCategories,
                  );
                }
                setSheetState(() {});
                onCategoriesChanged();
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Qo\'shish'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void showAddPlannedPaymentSheet(
  BuildContext context, {
  required Future<void> Function(
    String title,
    double amount,
    String category,
    DateTime dueDate,
    bool isRecurring,
  )
  onSubmit,
}) {
  String? selectedCategory;
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  DateTime chosenDate = DateTime.now();
  bool isRecurring = false;

  final List<Map<String, dynamic>> plannedCategories = [
    {'name': 'Kredit', 'icon': LucideIcons.landmark},
    {'name': 'Obuna', 'icon': LucideIcons.refreshCw},
    {'name': 'Qarz', 'icon': LucideIcons.hand},
    {'name': 'Boshqa', 'icon': LucideIcons.moreHorizontal},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GlassTokens.radiusLg),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rejalashtirilgan to'lov".tr,
                        style: TextStyle(
                          color: GlassTokens.primaryText(context),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: GlassTokens.secondaryText(context),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title field
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: GlassTokens.primaryText(context)),
                    decoration: InputDecoration(
                      labelText: "To'lov nomi (Masalan: Kredit to'lovi)".tr,
                      labelStyle: TextStyle(
                        color: GlassTokens.secondaryText(context),
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.pencil,
                        color: Colors.blueAccent,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: GlassTokens.glassBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: GlassTokens.primaryText(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: "Summa (UZS)".tr,
                      labelStyle: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.banknote,
                        color: Colors.blueAccent,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: GlassTokens.glassBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Category Grid
                  Text(
                    "Toifani tanlang".tr,
                    style: TextStyle(
                      color: GlassTokens.secondaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: plannedCategories.length,
                    itemBuilder: (context, index) {
                      final cat = plannedCategories[index];
                      final isSelected = selectedCategory == cat['name'];

                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedCategory = cat['name'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : GlassTokens.glassBorder(context),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : GlassTokens.secondaryText(context),
                                size: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (cat['name'] as String).tr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : GlassTokens.secondaryText(context),
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Recurring Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Har oy takrorlash".tr,
                            style: TextStyle(
                              color: GlassTokens.primaryText(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Har oy belgilangan sanada eslatiladi".tr,
                            style: TextStyle(
                              color: GlassTokens.secondaryText(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isRecurring,
                        onChanged: (val) {
                          setSheetState(() => isRecurring = val);
                        },
                        activeColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date pick row
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: chosenDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => chosenDate = picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${'Muddati:'.tr} ${chosenDate.day}-${financeMonthNameUz(chosenDate.month).tr} ${chosenDate.year}-${'yil'.tr}",
                              style: TextStyle(
                                color: GlassTokens.primaryText(context),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: GlassTokens.secondaryText(context),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Iltimos, to'lov nomini kiriting".tr,
                              ),
                            ),
                          );
                          return;
                        }
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Iltimos, to'g'ri summani kiriting".tr,
                              ),
                            ),
                          );
                          return;
                        }
                        if (selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Iltimos, toifani tanlang".tr),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        onSubmit(
                          title,
                          amount,
                          selectedCategory!,
                          chosenDate,
                          isRecurring,
                        );
                      },
                      child: Text(
                        "Saqlash".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
