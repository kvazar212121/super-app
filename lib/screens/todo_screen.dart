import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/daily_models.dart';
import '../services/api_service.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../theme/glass_tokens.dart';

import 'plan_history_screen.dart';

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
      return DateTime(today.year, today.month, today.day).add(Duration(days: index));
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
    const months = ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];
    return months[month - 1];
  }

  String _getMonthNameShort(int month) {
    const months = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun', 'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];
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
      setState(() {
        _plans = data.map((e) => PlanItem.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Error loading plans: $e");
    } finally {
      setState(() => _isLoading = false);
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
      // Revert if error
      setState(() {
        _plans[index] = item;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xatolik yuz berdi. Iltimos qayta urining.')),
      );
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
      setState(() => _plans = prev);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O'chirishda xatolik yuz berdi")),
      );
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
            return AlertDialog(
              backgroundColor: Colors.grey[900]?,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                side: BorderSide(color: Colors.white),
              ),
              title: const Text(
                "Yangi reja yaratish",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Reja nomi",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Tavsif (ixtiyoriy)",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Date picker row
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: chosenDate,
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setDialogState(() => chosenDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sana",
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Text(
                                    "${chosenDate.day}-${_getMonthName(chosenDate.month)} ${chosenDate.year}-yil",
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    // Time picker row
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: chosenTime,
                        );
                        if (picked != null) {
                          setDialogState(() => chosenTime = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.clock, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Vaqt",
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Text(
                                    "${chosenTime.hour.toString().padLeft(2, '0')}:${chosenTime.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 16),
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
                  child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                        const SnackBar(
                          content: Text("O'tib ketgan vaqtga reja qo'shib bo'lmaydi!"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    
                    try {
                      final res = await _api.createPlan(
                        title, 
                        due, 
                        descController.text.trim().isEmpty ? null : descController.text.trim()
                      );
                      final newPlan = PlanItem.fromJson(res);
                      
                      final selectedDateStr = formatDateForApi(_selectedDate);
                      final newPlanDateStr = formatDateForApi(newPlan.dueDate);
                      if (selectedDateStr == newPlanDateStr) {
                        setState(() {
                          _plans.add(newPlan);
                          _plans.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Reja ${newPlan.dueDate.day}-${_getMonthName(newPlan.dueDate.month)} kuniga qo'shildi!"),
                            action: SnackBarAction(
                              label: "O'tish",
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reja yaratishda xatolik yuz berdi")),
                      );
                    }
                  },
                  child: const Text("Saqlash", style: TextStyle(color: Colors.white)),
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
      title: 'Rejalarim',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.history),
          tooltip: 'Tarix',
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
                          ? "Bugun" 
                          : "${_selectedDate.day}-${_getMonthName(_selectedDate.month)}",
                      style: TextStyle(
                        color: GlassTokens.primaryText(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getWeekdayName(_selectedDate.weekday),
                      style: TextStyle(
                        color: GlassTokens.secondaryText(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Reja qo'shish tugmasi
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _showAddPlanDialog,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text(
                    "Reja qo'shish",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                              color: GlassTokens.secondaryText(context)
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Bu kunga rejalar yo'q",
                              style: TextStyle(
                                color: GlassTokens.secondaryText(context),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          final isToday = _isSameDay(date, DateTime.now());
          
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
                color: isSelected 
                    ? Colors.blueAccent
                    : isToday 
                        ? Colors.white
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? Colors.blueAccent
                      : isToday 
                          ? Colors.white
                          : Colors.white,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayNameShort(date.weekday),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : GlassTokens.secondaryText(context),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : GlassTokens.primaryText(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getMonthNameShort(date.month),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white
                          : GlassTokens.secondaryText(context),
                      fontSize: 10,
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
    final timeStr = "${item.dueDate.hour.toString().padLeft(2, '0')}:${item.dueDate.minute.toString().padLeft(2, '0')}";
    final hasDesc = item.description != null && item.description!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: hasDesc
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 8, right: 12, top: 4, bottom: 4),
                  leading: Checkbox(
                    value: item.isCompleted,
                    onChanged: (val) {
                      if (val != null) _togglePlan(item, val);
                    },
                    activeColor: Colors.blueAccent,
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
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 13, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.blueAccent,
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
                        color: GlassTokens.secondaryText(context)
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                        onPressed: () => _deletePlan(item.id),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 56.0, right: 16.0, bottom: 16.0),
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
              contentPadding: const EdgeInsets.only(left: 8, right: 12, top: 4, bottom: 4),
              leading: Checkbox(
                value: item.isCompleted,
                onChanged: (val) {
                  if (val != null) _togglePlan(item, val);
                },
                activeColor: Colors.blueAccent,
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
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 13, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                onPressed: () => _deletePlan(item.id),
              ),
            ),
    );
  }
}
