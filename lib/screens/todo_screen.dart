import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/todo_local_service.dart';
import '../theme/lux_tokens.dart';
import '../l10n/locale_controller.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/todo/todo_voice_mic_button.dart';
import '../widgets/todo/water_tracker_widget.dart';
import '../widgets/todo/habit_tracker_widget.dart';
import '../widgets/todo/pill_reminder_widget.dart';
import '../widgets/todo/voice_notes_widget.dart';
import 'plan_history_screen.dart';

/// "Mening Rejalarim" (Life OS Hub) — 24K Oltin Shaxsiy Boshqaruv Markazi.
/// Offlayn lokal baza, jonli ovozli mikrofon, Suv Balansi, Odatlar, Dorilar
/// va Ovozli Qaydlarni yagona modul tizimida birlashtiradi.
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  final TodoLocalService _service = TodoLocalService();
  late final TabController _tabController;
  late final ScrollController _calendarScrollController;
  late final List<DateTime> _calendarDays;

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _calendarScrollController = ScrollController();

    // 45 kunlik taqvim lentasi
    final today = DateTime.now();
    _calendarDays = List.generate(45, (index) {
      return DateTime(today.year, today.month, today.day).add(Duration(days: index - 7));
    });

    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final list = await _service.getTasksForDate(_selectedDate);
    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTask(String taskId, bool currentDone) async {
    await _service.toggleTask(taskId, !currentDone);
    await _loadTasks();
  }

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '12:00');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? LuxTokens.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: LuxTokens.gold.withValues(alpha: 0.6), width: 1.5),
        ),
        title: Text(
          'Yangi reja qo\'shish'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Reja nomi (masalan: Usta bilan ko\'rishish)',
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeCtrl,
              decoration: InputDecoration(
                hintText: 'Vaqti (masalan: 14:30)',
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Bekor qilish'.tr),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await _service.addTask({
                  'id': 'task_${DateTime.now().millisecondsSinceEpoch}',
                  'date': _service.formatDate(_selectedDate),
                  'title': titleCtrl.text.trim(),
                  'time': timeCtrl.text.trim(),
                  'is_done': false,
                  'category': 'reja',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadTasks();
              }
            },
            child: Text('Qo\'shish'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      title: 'Mening Rejalarim'.tr,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.history, color: LuxTokens.gold),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlanHistoryScreen()),
            );
          },
        ),
      ],
      body: SafeArea(
        child: Column(
          children: [
            // 1. JONLI OVOZLI MIKROFON TUGMASI (AI Voice Input)
            TodoVoiceMicButton(
              onDataChanged: _loadTasks,
            ),

            // 2. 45 KUNLIK INTERAKTIV TAQVIM LENTASI
            _buildCalendarStrip(isDark),
            const SizedBox(height: 10),

            // 3. 24K WHITE+GOLD TAB BAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? LuxTokens.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LuxTokens.gold.withValues(alpha: 0.5), width: 1.2),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: LuxTokens.gold,
                indicatorWeight: 3,
                labelColor: isDark ? LuxTokens.gold : const Color(0xFF8A5D0B),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Vazifalar'),
                  Tab(text: 'Suv Balansi'),
                  Tab(text: 'Odatlar'),
                  Tab(text: 'Dorilar'),
                  Tab(text: 'Ovozli Qaydlar'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. TAB SAHIFALARI
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Vazifalar va Taqvim Arxivi
                  _buildTasksTab(isDark),

                  // Tab 2: Suv Balansi
                  WaterTrackerWidget(
                    selectedDate: _selectedDate,
                    onChanged: _loadTasks,
                  ),

                  // Tab 3: Odatlar
                  HabitTrackerWidget(
                    selectedDate: _selectedDate,
                    onChanged: _loadTasks,
                  ),

                  // Tab 4: Dorilar
                  PillReminderWidget(
                    selectedDate: _selectedDate,
                    onChanged: _loadTasks,
                  ),

                  // Tab 5: Ovozli Qaydlar
                  VoiceNotesWidget(
                    onChanged: _loadTasks,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStrip(bool isDark) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _calendarDays.length,
        itemBuilder: (context, index) {
          final date = _calendarDays[index];
          final isSelected = _service.formatDate(date) == _service.formatDate(_selectedDate);
          final isToday = _service.formatDate(date) == _service.formatDate(DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadTasks();
            },
            child: Container(
              width: 54,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? LuxTokens.goldGradient : null,
                color: isSelected
                    ? null
                    : (isDark ? LuxTokens.surface : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFC9A227)
                      : (isToday
                          ? LuxTokens.gold
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  width: isSelected || isToday ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayNameShort(date.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF140D02)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? const Color(0xFF140D02)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
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

  Widget _buildTasksTab(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: LuxTokens.gold));
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kunlik Vazifalar:'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _service.formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LuxTokens.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? LuxTokens.surface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LuxTokens.border),
                ),
                child: Center(
                  child: Text(
                    'Bu kunda vazifalar yo\'q. Paqirdan "+" tugmasini bosing.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _tasks.map<Widget>((task) {
                  final bool isDone = task['is_done'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? LuxTokens.surface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                            : LuxTokens.gold.withValues(alpha: 0.6),
                        width: isDone ? 1.0 : 1.3,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleTask(task['id'], isDone),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: isDone
                                ? LuxTokens.goldBoxDecoration(radius: 8)
                                : BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                  ),
                            child: isDone
                                ? const Icon(LucideIcons.check, color: Color(0xFF140D02), size: 18)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone
                                      ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task['time'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LuxTokens.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),

        // Floating Add Button
        Positioned(
          right: 20,
          bottom: 160,
          child: FloatingActionButton(
            backgroundColor: LuxTokens.gold,
            foregroundColor: const Color(0xFF140D02),
            onPressed: _showAddTaskDialog,
            child: const Icon(LucideIcons.plus, size: 28),
          ),
        ),
      ],
    );
  }

  String _getDayNameShort(int day) {
    const days = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
    return days[day - 1];
  }
}
