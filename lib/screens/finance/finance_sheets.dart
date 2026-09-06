import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    {'name': 'Boshqa', 'icon': LucideIcons.coins},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          const inputBg = Color(0xFFF1F5F9);
          const textPrimary = Color(0xFF0F172A);
          const textSecondary = Color(0xFF64748B);

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
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: textSecondary,
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
                              gradient: selectedType == "expense"
                                  ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)])
                                  : null,
                              color: selectedType == "expense"
                                  ? null
                                  : inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == "expense"
                                    ? const Color(0xFF102A43)
                                    : const Color(0xFFE2E8F0),
                                width: selectedType == "expense" ? 1.5 : 1.0,
                              ),
                              boxShadow: selectedType == "expense"
                                  ? const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              "Xarajat".tr,
                              style: TextStyle(
                                color: selectedType == "expense"
                                    ? Colors.white
                                    : textSecondary,
                                fontWeight: FontWeight.w900,
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
                              gradient: selectedType == "income"
                                  ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)])
                                  : null,
                              color: selectedType == "income"
                                  ? null
                                  : inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == "income"
                                    ? const Color(0xFF102A43)
                                    : const Color(0xFFE2E8F0),
                                width: selectedType == "income" ? 1.5 : 1.0,
                              ),
                              boxShadow: selectedType == "income"
                                  ? const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              "Daromad".tr,
                              style: TextStyle(
                                color: selectedType == "income"
                                    ? Colors.white
                                    : textSecondary,
                                fontWeight: FontWeight.w900,
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
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: "Summa (UZS)".tr,
                      labelStyle: const TextStyle(
                        color: textSecondary,
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.banknote,
                        color: Color(0xFF102A43),
                      ),
                      filled: true,
                      fillColor: inputBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF102A43),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Toifani tanlang".tr,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)])
                                : null,
                            color: isSelected
                                ? null
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF102A43)
                                  : const Color(0xFFE2E8F0),
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
                                    : textSecondary,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (cat['name'] as String).tr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
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
                    style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Izoh (ixtiyoriy)".tr,
                      labelStyle: const TextStyle(
                        color: textSecondary,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.pencil,
                        color: textSecondary,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF102A43),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: chosenDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF102A43),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Color(0xFF0F172A),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF102A43),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setSheetState(() => chosenDate = picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Color(0xFF102A43),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${'Sana:'.tr} ${chosenDate.day}-${financeMonthNameUz(chosenDate.month).tr} ${chosenDate.year}-${'yil'.tr}",
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          fontWeight: FontWeight.w900,
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFF102A43).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        title: Text(
          'Yangi toifa qo\'shish'.tr,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: catController,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Toifa nomi'.tr,
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Bekor qilish'.tr,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(
                'Qo\'shish'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
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
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          const inputBg = Color(0xFFF1F5F9);
          const textPrimary = Color(0xFF0F172A);
          const textSecondary = Color(0xFF64748B);

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
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title field
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "To'lov nomi (Masalan: Kredit to'lovi)".tr,
                      labelStyle: const TextStyle(
                        color: textSecondary,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.pencil,
                        color: Color(0xFF102A43),
                      ),
                      filled: true,
                      fillColor: inputBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF102A43),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: "Summa (UZS)".tr,
                      labelStyle: const TextStyle(
                        color: textSecondary,
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.banknote,
                        color: Color(0xFF102A43),
                      ),
                      filled: true,
                      fillColor: inputBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF102A43),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Category Grid
                  Text(
                    "Toifani tanlang".tr,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)])
                                : null,
                            color: isSelected
                                ? null
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF102A43)
                                  : const Color(0xFFE2E8F0),
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
                                    : textSecondary,
                                size: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (cat['name'] as String).tr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
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
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Har oy belgilangan sanada eslatiladi".tr,
                            style: const TextStyle(
                              color: textSecondary,
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
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF102A43),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date pick row
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
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
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF102A43),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Color(0xFF0F172A),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF102A43),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setSheetState(() => chosenDate = picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Color(0xFF102A43),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${'Muddati:'.tr} ${chosenDate.day}-${financeMonthNameUz(chosenDate.month).tr} ${chosenDate.year}-${'yil'.tr}",
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF244E77)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          fontWeight: FontWeight.w900,
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
