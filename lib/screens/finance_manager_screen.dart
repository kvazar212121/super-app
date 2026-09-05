import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/finance_models.dart';
import '../services/api_service.dart';
import '../widgets/friendly_error.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../l10n/locale_controller.dart';
import 'family_finance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'finance/finance_month_selector.dart';
import 'finance/finance_tab_selector.dart';
import 'finance/finance_balance_card.dart';
import 'finance/finance_insight_card.dart';
import 'finance/finance_donut_chart.dart';
import 'finance/finance_category_breakdown.dart';
import 'finance/finance_transactions_list.dart';
import 'finance/finance_planned_tab.dart';
import 'finance/finance_sheets.dart';
import '../theme/lux_tokens.dart';

class FinanceManagerScreen extends StatefulWidget {
  const FinanceManagerScreen({super.key});

  @override
  State<FinanceManagerScreen> createState() => _FinanceManagerScreenState();
}

class _FinanceManagerScreenState extends State<FinanceManagerScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();
  int _activeTab =
      0; // 0: Analytics & History, 1: Planned Payments & Debt Reminders

  FinanceStats? _stats;
  List<FinanceRecord> _records = [];
  List<PlannedPayment> _plannedPayments = [];

  List<String> _customExpenseCategories = [];
  List<String> _customIncomeCategories = [];

  final List<Color> _chartColors = [
    const Color(0xFF102A43),
    const Color(0xFF244E77),
    const Color(0xFF334E68),
    const Color(0xFF486581),
    const Color(0xFF627D98),
    const Color(0xFF829AB1),
    const Color(0xFF9FB3C8),
    const Color(0xFFBCCCDC),
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
    _loadData();
  }

  Future<void> _loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _customExpenseCategories =
            prefs.getStringList('customExpenseCategories') ?? [];
        _customIncomeCategories =
            prefs.getStringList('customIncomeCategories') ?? [];
      });
    } catch (e) {
      debugPrint("SharedPreferences error: $e");
    }
  }

  String _getMonthStr(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final monthStr = _getMonthStr(_currentMonth);
    try {
      final statsData = await _api.getFinanceStats(month: monthStr);
      final recordsData = await _api.getFinanceRecords(month: monthStr);
      final plannedData = await _api.getPlannedPayments();

      if (!mounted) return;
      setState(() {
        _stats = FinanceStats.fromJson(statsData);
        _records = (recordsData)
            .map((e) => FinanceRecord.fromJson(e))
            .toList();
        _plannedPayments = (plannedData)
            .map((e) => PlannedPayment.fromJson(e))
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading finance data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + offset,
      );
    });
    _loadData();
  }

  Future<void> _addRecord(
    String type,
    double amount,
    String category,
    String? description,
    DateTime date,
  ) async {
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
      if (!mounted) return;
      // FriendlyError: internet/server xatolarini konkret ko'rsatadi.
      showFriendlyErrorSnack(context, e);
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
      if (!mounted) return;
      setState(() {
        _records = prevRecords;
      });
      showFriendlyErrorSnack(context, e);
    }
  }

  Future<void> _addPlannedPayment(
    String title,
    double amount,
    String category,
    DateTime dueDate,
    bool isRecurring,
  ) async {
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
      if (!mounted) return;
      showFriendlyErrorSnack(context, e);
    }
  }

  Future<void> _markPlannedPaymentPaid(PlannedPayment payment) async {
    try {
      await _api.updatePlannedPayment(payment.id, isPaid: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            payment.isRecurring
                ? "To'lov tasdiqlandi va keyingi oyga ko'chirildi".tr
                : "To'lov bajarilgan deb belgilandi".tr,
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      showFriendlyErrorSnack(context, e);
    }
  }

  Future<void> _deletePlannedPayment(int id) async {
    try {
      await _api.deletePlannedPayment(id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      showFriendlyErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Mening moliyam'.tr,
      actions: [
        IconButton(
          tooltip: 'Oilaviy byudjet'.tr,
          icon: const Icon(LucideIcons.users),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyFinanceScreen()),
            );
            _loadData();
          },
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                FinanceMonthSelector(
                  currentMonth: _currentMonth,
                  onPrev: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                ),
                FinanceTabSelector(
                  activeTab: _activeTab,
                  onChanged: (tab) => setState(() => _activeTab = tab),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _activeTab == 0
                        ? _buildAnalyticsTab()
                        : FinancePlannedTab(
                            plannedPayments: _plannedPayments,
                            onMarkPaid: _markPlannedPaymentPaid,
                            onDelete: _deletePlannedPayment,
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _activeTab == 0
            ? () => showAddTransactionSheet(
                context,
                customExpenseCategories: _customExpenseCategories,
                customIncomeCategories: _customIncomeCategories,
                onSubmit: _addRecord,
                onCategoriesChanged: () => setState(() {}),
              )
            : () => showAddPlannedPaymentSheet(
                context,
                onSubmit: _addPlannedPayment,
              ),
        child: const Icon(LucideIcons.plus, size: 24),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceBalanceCard(stats: _stats),
        if (_stats != null && _stats!.insight.isNotEmpty)
          FinanceInsightCard(insight: _stats!.insight),
        if (_stats != null && _stats!.categoryStats.isNotEmpty) ...[
          FinanceDonutChart(stats: _stats!, chartColors: _chartColors),
          FinanceCategoryBreakdown(stats: _stats!, chartColors: _chartColors),
        ],
        FinanceTransactionsList(records: _records, onDelete: _deleteRecord),
      ],
    );
  }
}
