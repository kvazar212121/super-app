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

  Future<void> _deleteTask(String taskId) async {
    await _service.deleteTask(taskId);
    await _loadTasks();
  }

  /// Kategoriyaga mos urg'u rangi — kartaning chap chetidagi belgi uchun.
  Color _categoryColor(String? category) {
    switch (category) {
      case 'xarid':
        return const Color(0xFF16A34A);
      case 'xizmat':
        return const Color(0xFF2563EB);
      case 'ish':
        return const Color(0xFF9333EA);
      case 'sogliq':
        return const Color(0xFFDC2626);
      default:
        return LuxTokens.gold;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'xarid':
        return LucideIcons.shoppingBag;
      case 'xizmat':
        return LucideIcons.wrench;
      case 'ish':
        return LucideIcons.briefcase;
      case 'sogliq':
        return LucideIcons.heartPulse;
      default:
        return LucideIcons.calendarCheck;
    }
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
            color: const Color(0xFF0F172A),
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
                unselectedLabelColor: const Color(0xFF64748B),
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
      height: 76,
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
              width: 58,
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? LuxTokens.goldGradient : null,
                color: isSelected
                    ? null
                    : (isDark ? LuxTokens.surface : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFC9A227)
                      : (isToday
                          ? LuxTokens.gold
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  width: isSelected || isToday ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? LuxTokens.gold.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayNameShort(date.weekday),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF140D02)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? const Color(0xFF140D02)
                          : const Color(0xFF0F172A),
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

    final int doneCount = _tasks.where((t) => t['is_done'] == true).length;
    final int totalCount = _tasks.length;
    final double progress = totalCount == 0 ? 0 : doneCount / totalCount;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
          children: [
            // ── Sarlavha + sana + progress ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kunlik Vazifalar:'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LuxTokens.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _service.formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: LuxTokens.goldDim,
                    ),
                  ),
                ),
              ],
            ),

            if (totalCount > 0) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFEDE3C7),
                        valueColor: const AlwaysStoppedAnimation(LuxTokens.gold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$doneCount/$totalCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            if (_tasks.isEmpty)
              _buildEmptyState(isDark)
            else
              Column(
                children: _tasks.map<Widget>((task) => _buildTaskCard(task, isDark)).toList(),
              ),
          ],
        ),

        // Floating Add Button
        Positioned(
          right: 20,
          bottom: 160,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LuxTokens.gold.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: LuxTokens.gold,
              foregroundColor: const Color(0xFF140D02),
              elevation: 0,
              onPressed: _showAddTaskDialog,
              child: const Icon(LucideIcons.plus, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? LuxTokens.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LuxTokens.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: LuxTokens.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.calendarPlus, color: LuxTokens.gold, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Bu kunda vazifa yo\'q'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yangi reja qo\'shish uchun "+" tugmasini bosing yoki ovozli buyruq bering.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isDark) {
    final bool isDone = task['is_done'] == true;
    final Color catColor = _categoryColor(task['category'] as String?);

    return Dismissible(
      key: ValueKey(task['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        _deleteTask(task['id']);
        return true;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? LuxTokens.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                : LuxTokens.gold.withValues(alpha: 0.55),
            width: isDone ? 1.0 : 1.3,
          ),
          boxShadow: isDone
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTask(task['id'], isDone),
              child: Container(
                width: 30,
                height: 30,
                decoration: isDone
                    ? LuxTokens.goldBoxDecoration(radius: 9)
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
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
                          ? const Color(0xFF94A3B8)
                          : (const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: LuxTokens.gold.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        task['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: LuxTokens.goldDim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Kategoriya belgisi
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(task['category'] as String?), size: 17, color: catColor),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayNameShort(int day) {
    const days = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
    return days[day - 1];
  }
}
