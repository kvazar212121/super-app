import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/lux_tokens.dart';
import '../../l10n/locale_controller.dart';
import '../../services/todo_local_service.dart';

class HabitTrackerWidget extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onChanged;

  const HabitTrackerWidget({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  State<HabitTrackerWidget> createState() => _HabitTrackerWidgetState();
}

class _HabitTrackerWidgetState extends State<HabitTrackerWidget> {
  final TodoLocalService _service = TodoLocalService();
  List<Map<String, dynamic>> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HabitTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _service.getHabitsForDate(widget.selectedDate);
    if (mounted) {
      setState(() {
        _habits = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHabit(String habitId) async {
    await _service.toggleHabitForDate(habitId, widget.selectedDate);
    await _loadData();
    widget.onChanged();
  }

  Future<void> _showAddHabitDialog() async {
    final titleCtrl = TextEditingController();
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
          'Yangi odat qo\'shish'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Masalan: 10,000 qadam yurish',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: LuxTokens.gold.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: LuxTokens.gold, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Bekor qilish'.tr),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await _service.addHabit(titleCtrl.text.trim(), 'target');
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadData();
                widget.onChanged();
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
    final dateStr = _service.formatDate(widget.selectedDate);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: LuxTokens.gold));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kunlik Odatlar va Ketma-ketlik:'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, color: LuxTokens.gold, size: 24),
                onPressed: _showAddHabitDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_habits.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? LuxTokens.surface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LuxTokens.border),
              ),
              child: Center(
                child: Text(
                  'Hali odatlar qo\'shilmadi. "+" tugmasini bosing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            Column(
              children: _habits.map<Widget>((habit) {
                final List completedDates = habit['completed_dates'] ?? [];
                final bool isCompleted = completedDates.contains(dateStr);
                final int streak = habit['streak'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? LuxTokens.surface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? LuxTokens.gold
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isCompleted ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCompleted
                            ? LuxTokens.gold.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      GestureDetector(
                        onTap: () => _toggleHabit(habit['id']),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: isCompleted
                              ? LuxTokens.goldBoxDecoration(radius: 8)
                              : BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                ),
                          child: isCompleted
                              ? const Icon(LucideIcons.check, color: Color(0xFF140D02), size: 18)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit['title'] ?? '',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCompleted ? 'Bugunga bajarildi ✨' : 'Bajarish kutilmoqda',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? LuxTokens.goldDim : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Streak Counter Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 13)),
                            Text(
                              '$streak kun',
                              style: const TextStyle(
                                color: Color(0xFF8A5D0B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
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
    );
  }
}
