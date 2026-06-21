import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/finance_models.dart';
import '../services/api_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';

const double pi = 3.1415926535897932;

class FinanceManagerScreen extends StatefulWidget {
  const FinanceManagerScreen({super.key});

  @override
  State<FinanceManagerScreen> createState() => _FinanceManagerScreenState();
}

class _FinanceManagerScreenState extends State<FinanceManagerScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();
  int _activeTab = 0; // 0: Analytics & History, 1: Planned Payments & Debt Reminders
  
  FinanceStats? _stats;
  List<FinanceRecord> _records = [];
  List<PlannedPayment> _plannedPayments = [];

  final List<Color> _chartColors = [
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.amberAccent,
    Colors.redAccent,
    Colors.tealAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getMonthStr(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
  }

  String _getMonthNameUz(int month) {
    const months = ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];
    return months[month - 1];
  }

  String _formatCurrency(double amount) {
    final isNeg = amount < 0;
    final absAmt = amount.abs().toInt();
    final str = absAmt.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      if ((str.length - 1 - i) % 3 == 0 && i != str.length - 1) {
        buffer.write(' ');
      }
    }
    return "${isNeg ? '-' : ''}${buffer.toString()} UZS";
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final monthStr = _getMonthStr(_currentMonth);
    try {
      final statsData = await _api.getFinanceStats(month: monthStr);
      final recordsData = await _api.getFinanceRecords(month: monthStr);
      final plannedData = await _api.getPlannedPayments();
      
      setState(() {
        _stats = FinanceStats.fromJson(statsData);
        _records = (recordsData as List).map((e) => FinanceRecord.fromJson(e)).toList();
        _plannedPayments = (plannedData as List).map((e) => PlannedPayment.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Error loading finance data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
    _loadData();
  }

  Future<void> _addRecord(String type, double amount, String category, String? description, DateTime date) async {
    try {
      await _api.createFinanceRecord(
        type: type,
        amount: amount,
        category: category,
        description: description,
        date: date,
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tranzaksiya kiritishda xatolik yuz berdi")),
      );
    }
  }

  Future<void> _deleteRecord(int id) async {
    final prevRecords = List<FinanceRecord>.from(_records);
    setState(() {
      _records.removeWhere((r) => r.id == id);
    });
    try {
      await _api.deleteFinanceRecord(id);
      _loadData();
    } catch (e) {
      setState(() {
        _records = prevRecords;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O'chirishda xatolik yuz berdi")),
      );
    }
  }

  Future<void> _addPlannedPayment(String title, double amount, String category, DateTime dueDate, bool isRecurring) async {
    try {
      await _api.createPlannedPayment(
        title: title,
        amount: amount,
        category: category,
        dueDate: dueDate,
        isRecurring: isRecurring,
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rejalashtirilgan to'lov qo'shishda xatolik")),
      );
    }
  }

  Future<void> _markPlannedPaymentPaid(PlannedPayment payment) async {
    try {
      await _api.updatePlannedPayment(payment.id, isPaid: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment.isRecurring
              ? "To'lov tasdiqlandi va keyingi oyga ko'chirildi"
              : "To'lov bajarilgan deb belgilandi"),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xatolik yuz berdi")),
      );
    }
  }

  Future<void> _deletePlannedPayment(int id) async {
    try {
      await _api.deletePlannedPayment(id);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xatolik yuz berdi")),
      );
    }
  }

  void _showAddTransactionBottomSheet() {
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
      {'name': 'Boshqa', 'icon': LucideIcons.moreHorizontal},
    ];

    final List<Map<String, dynamic>> incomeCategories = [
      {'name': 'Maosh', 'icon': LucideIcons.banknote},
      {'name': 'Biznes', 'icon': LucideIcons.briefcase},
      {'name': 'Keshbek', 'icon': LucideIcons.coins},
      {'name': 'Boshqa', 'icon': LucideIcons.moreHorizontal},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(GlassTokens.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeCategories = selectedType == "expense" ? expenseCategories : incomeCategories;
            
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
                        const Text(
                          "Yangi tranzaksiya",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Colors.white70),
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
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedType == "expense" ? Colors.redAccent : Colors.white10,
                                ),
                              ),
                              child: Text(
                                "Xarajat",
                                style: TextStyle(
                                  color: selectedType == "expense" ? Colors.white : Colors.white60,
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
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedType == "income" ? Colors.green.shade700 : Colors.white10,
                                ),
                              ),
                              child: Text(
                                "Daromad",
                                style: TextStyle(
                                  color: selectedType == "income" ? Colors.white : Colors.white60,
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
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Summa (UZS)",
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 16),
                        prefixIcon: const Icon(LucideIcons.banknote, color: Colors.blueAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Toifani tanlang",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            setSheetState(() {
                              selectedCategory = cat['name'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.blueAccent
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blueAccent : Colors.white10,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat['icon'], 
                                  color: isSelected ? Colors.white : Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Izoh (ixtiyoriy)",
                        labelStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(LucideIcons.pencil, color: Colors.white54, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: chosenDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => chosenDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Sana: ${chosenDate.day}-${_getMonthNameUz(chosenDate.month)} ${chosenDate.year}-yil",
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 16),
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
                          final amount = double.tryParse(amountController.text.trim());
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Iltimos, to'g'ri summani kiriting")),
                            );
                            return;
                          }
                          if (selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Iltimos, toifani tanlang")),
                            );
                            return;
                          }
                          
                          Navigator.pop(context);
                          _addRecord(
                            selectedType,
                            amount,
                            selectedCategory!,
                            descController.text.trim().isEmpty ? null : descController.text.trim(),
                            chosenDate,
                          );
                        },
                        child: const Text(
                          "Saqlash",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  void _showAddPlannedPaymentBottomSheet() {
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
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(GlassTokens.radiusLg)),
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
                        const Text(
                          "Rejalashtirilgan to'lov",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title field
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "To'lov nomi (Masalan: Kredit to'lovi)",
                        labelStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(LucideIcons.pencil, color: Colors.blueAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Summa (UZS)",
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 16),
                        prefixIcon: const Icon(LucideIcons.banknote, color: Colors.blueAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Category Grid
                    const Text(
                      "Toifani tanlang",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blueAccent : Colors.white10,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat['icon'], 
                                  color: isSelected ? Colors.white : Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Har oy takrorlash",
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Har oy belgilangan sanada eslatiladi",
                              style: TextStyle(color: Colors.white54, fontSize: 11),
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
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => chosenDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Muddati: ${chosenDate.day}-${_getMonthNameUz(chosenDate.month)} ${chosenDate.year}-yil",
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 16),
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
                          final amount = double.tryParse(amountController.text.trim());
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Iltimos, to'lov nomini kiriting")),
                            );
                            return;
                          }
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Iltimos, to'g'ri summani kiriting")),
                            );
                            return;
                          }
                          if (selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Iltimos, toifani tanlang")),
                            );
                            return;
                          }
                          
                          Navigator.pop(context);
                          _addPlannedPayment(
                            title,
                            amount,
                            selectedCategory!,
                            chosenDate,
                            isRecurring,
                          );
                        },
                        child: const Text(
                          "Saqlash",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Mening moliyam',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMonthSelector(),
                _buildTabSelector(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _activeTab == 0 ? _buildAnalyticsTab() : _buildPlannedTab(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _activeTab == 0 ? _showAddTransactionBottomSheet : _showAddPlannedPaymentBottomSheet,
        child: const Icon(LucideIcons.plus, size: 24),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            "${_getMonthNameUz(_currentMonth.month)}, ${_currentMonth.year}",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, color: Colors.white),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Tahlil & Tarix",
                        style: TextStyle(
                          color: _activeTab == 0 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Rejali to'lovlar",
                        style: TextStyle(
                          color: _activeTab == 1 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBalanceCard(),
        if (_stats != null && _stats!.insight.isNotEmpty)
          _buildInsightCard(),
        if (_stats != null && _stats!.categoryStats.isNotEmpty) ...[
          _buildDonutChartWidget(),
          _buildCategoryBreakdown(),
        ],
        _buildTransactionsList(),
      ],
    );
  }

  Widget _buildPlannedTab() {
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
              const Text(
                "Kutilayotgan to'lovlar",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Jami: ${_plannedPayments.length} ta",
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _plannedPayments.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(LucideIcons.calendarCheck, size: 44, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        "Rejalashtirilgan to'lovlar yo'q",
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plannedPayments.length,
                  itemBuilder: (context, index) {
                    final item = _plannedPayments[index];
                    final isOverdue = item.dueDate.isBefore(today) && !item.isPaid;
                    final dueStr = "${item.dueDate.day}-${_getMonthNameUz(item.dueDate.month).substring(0, 3)} ${item.dueDate.year}";

                    Color statusColor = Colors.orangeAccent;
                    String statusText = "Kutilmoqda";
                    if (item.isPaid) {
                      statusColor = Colors.greenAccent;
                      statusText = "To'landi";
                    } else if (isOverdue) {
                      statusColor = Colors.redAccent;
                      statusText = "Muddati o'tdi";
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isOverdue 
                                  ? Colors.redAccent
                                  : Colors.white30,
                            ),
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
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.category,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(item.amount),
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.calendar, size: 14, color: Colors.white54),
                                  const SizedBox(width: 6),
                                  Text(
                                    dueStr,
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                  if (item.isRecurring) ...[
                                    const SizedBox(width: 12),
                                    const Icon(LucideIcons.repeat, size: 12, color: Colors.blueAccent),
                                    const SizedBox(width: 4),
                                    const Text("Obuna", style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
                                  ],
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
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
                                      foregroundColor: Colors.greenAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _markPlannedPaymentPaid(item),
                                    icon: const Icon(LucideIcons.check, size: 16),
                                    label: const Text("To'landi", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                                    onPressed: () => _deletePlannedPayment(item.id),
                                  ),
                                ),
                              ],
                            ),
                          ]
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

  Widget _buildBalanceCard() {
    final income = _stats?.totalIncome ?? 0.0;
    final expense = _stats?.totalExpense ?? 0.0;
    final balance = _stats?.balance ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white30),
            ),
            child: Column(
          children: [
            const Text(
              "Jami Balans",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatCurrency(balance),
              style: TextStyle(
                color: balance >= 0 ? Colors.white : Colors.redAccent,
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
                              color: Colors.greenAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowDownLeft, color: Colors.greenAccent, size: 14),
                          ),
                          const SizedBox(width: 6),
                          const Text("Daromad", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(income),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowUpRight, color: Colors.redAccent, size: 14),
                          ),
                          const SizedBox(width: 6),
                          const Text("Xarajat", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(expense),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
            ),
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.lightbulb, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _stats!.insight,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildDonutChartWidget() {
    final expense = _stats?.totalExpense ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: DonutChartPainter(_stats!.categoryStats, _chartColors),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Jami Xarajat", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _formatCurrency(expense),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildCategoryBreakdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Xarajatlar ulushi",
            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stats!.categoryStats.length,
            itemBuilder: (context, index) {
              final cat = _stats!.categoryStats[index];
              final color = _chartColors[index % _chartColors.length];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.category,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      "${cat.percentage.toStringAsFixed(1)}%",
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      _formatCurrency(cat.amount),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildTransactionsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Oxirgi amallar",
            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _records.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  child: const Text(
                    "Tranzaksiyalar mavjud emas",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final item = _records[index];
                    final isExpense = item.type == "expense";
                    final dateStr = "${item.date.day}-${_getMonthNameUz(item.date.month).substring(0, 3)}";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isExpense 
                                  ? Colors.redAccent.withOpacity(0.2)
                                  : Colors.greenAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                              color: isExpense ? Colors.redAccent : Colors.greenAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description ?? dateStr,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
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
                                "${isExpense ? '-' : '+'}${_formatCurrency(item.amount)}",
                                style: TextStyle(
                                  color: isExpense ? Colors.redAccent : Colors.greenAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                            onPressed: () => _deleteRecord(item.id),
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

class DonutChartPainter extends CustomPainter {
  final List<FinanceCategoryStat> stats;
  final List<Color> colors;

  DonutChartPainter(this.stats, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 8);

    double startAngle = -pi / 2;

    if (stats.isEmpty) {
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }

    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final sweepAngle = (stat.percentage / 100) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
