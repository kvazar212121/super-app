import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/daily_models.dart';
import '../services/api_service.dart';
import '../widgets/friendly_error.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';
import '../l10n/locale_controller.dart';

import 'plan_history_screen.dart';
import '../theme/lux_tokens.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<PlanItem> _plans = [];
  DateTime _selectedDate = DateTime.now();

  late final ScrollController _calendarScrollController;
  late final List<DateTime> _calendarDays;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController();
    // Generate 45 days: starting from today
    final today = DateTime.now();
    _calendarDays = List.generate(45, (index) {
      return DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: index));
    });

    _loadPlans();

    // Scroll to today's date in calendar strip after frame layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarScrollController.hasClients) {
        _calendarScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  String formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _getMonthName(int month) {
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    return months[month - 1];
  }

  String _getMonthNameShort(int month) {
    const months = [
      'Yan',
      'Fev',
      'Mar',
      'Apr',
      'May',
      'Iyun',
      'Iyul',
      'Avg',
      'Sen',
      'Okt',
      'Noy',
      'Dek',
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Dushanba',
      'Seshanba',
      'Chorshanba',
      'Payshanba',
      'Juma',
      'Shanba',
      'Yakshanba',
    ];
    return days[weekday - 1];
  }

  String _getWeekdayNameShort(int weekday) {
    const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return days[weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getPlans(date: formatDateForApi(_selectedDate));
      if (!mounted) return;
      setState(() {
        _plans = data.map((e) => PlanItem.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Error loading plans: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlan(PlanItem item, bool val) async {
    final index = _plans.indexWhere((e) => e.id == item.id);
    if (index == -1) return;

    final updatedItem = PlanItem(
      id: item.id,
      title: item.title,
      description: item.description,
      dueDate: item.dueDate,
      isCompleted: val,
    );

    setState(() {
      _plans[index] = updatedItem;
    });

    try {
      await _api.updatePlan(item.id, isCompleted: val);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plans[index] = item;
      });
      showFriendlyErrorSnack(context, e);
    }
  }

  Future<void> _deletePlan(int id) async {
    final prev = List<PlanItem>.from(_plans);
    setState(() {
      _plans.removeWhere((e) => e.id == id);
    });
    try {
      await _api.deletePlan(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _plans = prev);
      showFriendlyErrorSnack(context, e);
    }
  }

  Future<void> _showAddPlanDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime chosenDate = _selectedDate;
    TimeOfDay chosenTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            const inputBg = Color(0xFFF1F5F9);
            const textPrimary = Color(0xFF0F172A);
            const textSecondary = Color(0xFF64748B);

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: LuxTokens.gold.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              title: Text(
                "Yangi reja yaratish".tr,
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: "Reja nomi".tr,
                        hintStyle: const TextStyle(
                          color: textSecondary,
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: LuxTokens.gold,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Tavsif (ixtiyoriy)".tr,
                        hintStyle: const TextStyle(
                          color: textSecondary,
                        ),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: LuxTokens.gold,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Date picker row
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: chosenDate,
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFC99427),
                                  onPrimary: Color(0xFF140D02),
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0F172A),
                                ),
                                dialogBackgroundColor: Colors.white,
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF8A5D0B),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => chosenDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              color: LuxTokens.gold,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sana".tr,
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "${chosenDate.day}-${_getMonthName(chosenDate.month).tr} ${chosenDate.year}-${'yil'.tr}",
                                    style: const TextStyle(
                                      color: textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      color: Color(0xFFE2E8F0),
                      height: 16,
                    ),
                    // Time picker row
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: chosenTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFC99427),
                                  onPrimary: Color(0xFF140D02),
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0F172A),
                                  secondary: Color(0xFFC99427),
                                  onSecondary: Color(0xFF140D02),
                                ),
                                dialogBackgroundColor: Colors.white,
                                timePickerTheme: const TimePickerThemeData(
                                  backgroundColor: Colors.white,
                                  hourMinuteColor: Color(0xFFF1F5F9),
                                  hourMinuteTextColor: Color(0xFF0F172A),
                                  dayPeriodColor: Color(0xFFF1F5F9),
                                  dayPeriodTextColor: Color(0xFF0F172A),
                                  dialBackgroundColor: Color(0xFFF8FAFC),
                                  dialHandColor: Color(0xFFC99427),
                                  dialTextColor: Color(0xFF0F172A),
                                  entryModeIconColor: Color(0xFF8A5D0B),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF8A5D0B),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => chosenTime = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 8.0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              color: LuxTokens.gold,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Vaqt".tr,
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "${chosenTime.hour.toString().padLeft(2, '0')}:${chosenTime.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      color: textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Bekor qilish".tr,
                    style: const TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final due = DateTime(
                        chosenDate.year,
                        chosenDate.month,
                        chosenDate.day,
                        chosenTime.hour,
                        chosenTime.minute,
                      );

                      if (due.isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "O'tib ketgan vaqtga reja qo'shib bo'lmaydi!".tr,
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final res = await _api.createPlan(
                          title,
                          due,
                          descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                        );
                        final newPlan = PlanItem.fromJson(res);

                        final selectedDateStr = formatDateForApi(_selectedDate);
                        final newPlanDateStr = formatDateForApi(newPlan.dueDate);
                        if (selectedDateStr == newPlanDateStr) {
                          if (!mounted) return;
                          setState(() {
                            _plans.add(newPlan);
                            _plans.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                          });
                        } else {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                "${'Reja'.tr} ${newPlan.dueDate.day}-${_getMonthName(newPlan.dueDate.month).tr} ${"kuniga qo'shildi!".tr}",
                              ),
                              action: SnackBarAction(
                                label: "O'tish".tr,
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = newPlan.dueDate;
                                  });
                                  _loadPlans();
                                },
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text("Reja yaratishda xatolik yuz berdi".tr),
                          ),
                        );
                      }
                    },
                    child: Text(
                      "Saqlash".tr,
                      style: const TextStyle(
                        color: Color(0xFF140D02),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isSelectedToday = _isSameDay(_selectedDate, today);

    return GlassScaffold(
      showBackButton: true,
      title: 'Rejalarim'.tr,
      actions: [
        IconButton(
          icon: Icon(LucideIcons.history),
          tooltip: 'Tarix'.tr,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlanHistoryScreen()),
            );
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gorizontal Kalendar Lentasi
          _buildCalendarStrip(),

          // Tanlangan kun sarlavhasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSelectedToday
                          ? "Bugun".tr
                          : "${_selectedDate.day}-${_getMonthName(_selectedDate.month).tr}",
                      style: TextStyle(
                        color: GlassTokens.primaryText(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getWeekdayName(_selectedDate.weekday).tr,
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Reja qo'shish tugmasi
                Container(
                  decoration: BoxDecoration(
                    gradient: LuxTokens.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showAddPlanDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.plus,
                              size: 18,
                              color: Color(0xFF140D02),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Reja qo'shish".tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF140D02),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rejalar ro'yxati
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _plans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.calendarX2,
                          size: 48,
                          color: GlassTokens.secondaryText(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Bu kunga rejalar yo'q".tr,
                          style: TextStyle(
                            color: GlassTokens.secondaryText(context),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final item = _plans[index];
                      return _buildPlanCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return SizedBox(
      height: 94,
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: _calendarDays.length,
        itemBuilder: (context, index) {
          final date = _calendarDays[index];
          final isSelected = _isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _loadPlans();
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? LuxTokens.goldGradient : null,
                color: isSelected ? null : GlassTokens.glassFill(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? LuxTokens.gold
                      : GlassTokens.glassBorder(context),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayNameShort(date.weekday).tr,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF332205)
                          : GlassTokens.secondaryText(context),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF140D02)
                          : GlassTokens.primaryText(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getMonthNameShort(date.month).tr,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF332205)
                          : GlassTokens.secondaryText(context),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(PlanItem item) {
    final timeStr =
        "${item.dueDate.hour.toString().padLeft(2, '0')}:${item.dueDate.minute.toString().padLeft(2, '0')}";
    final hasDesc = item.description != null && item.description!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTokens.glassBorder(context)),
      ),
      child: hasDesc
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.only(
                    left: 8,
                    right: 12,
                    top: 4,
                    bottom: 4,
                  ),
                  leading: Checkbox(
                    value: item.isCompleted,
                    onChanged: (val) {
                      if (val != null) _togglePlan(item, val);
                    },
                    activeColor: LuxTokens.goldSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: GlassTokens.primaryText(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: LuxTokens.goldSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: LuxTokens.goldSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: GlassTokens.secondaryText(context),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: () => _deletePlan(item.id),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 56.0,
                        right: 16.0,
                        bottom: 16.0,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            color: GlassTokens.secondaryText(context),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListTile(
              contentPadding: const EdgeInsets.only(
                left: 8,
                right: 12,
                top: 4,
                bottom: 4,
              ),
              leading: Checkbox(
                value: item.isCompleted,
                onChanged: (val) {
                  if (val != null) _togglePlan(item, val);
                },
                activeColor: LuxTokens.goldSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  color: GlassTokens.primaryText(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 13,
                      color: LuxTokens.goldSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: LuxTokens.goldSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  LucideIcons.trash2,
                  color: Colors.redAccent,
                  size: 18,
                ),
                onPressed: () => _deletePlan(item.id),
              ),
            ),
    );
  }
}
