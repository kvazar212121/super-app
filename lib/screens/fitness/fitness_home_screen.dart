import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/api_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'exercise_library_screen.dart';
import 'fitness_plan_setup_screen.dart';
import 'fitness_utils.dart';
import 'fitness_workout_day_screen.dart';

/// Fitnes trener — aktiv reja, bugungi mashg'ulot, progress va eslatmalar.
class FitnessHomeScreen extends StatefulWidget {
  const FitnessHomeScreen({super.key});

  @override
  State<FitnessHomeScreen> createState() => _FitnessHomeScreenState();
}

class _FitnessHomeScreenState extends State<FitnessHomeScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _plan;
  List<dynamic> _weekLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plan = await _api.getActiveWorkoutPlan();
      List<dynamic> logs = [];
      if (plan != null) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        logs = await _api.getWorkoutLogs(
          from: _formatDateForApi(DateTime(weekStart.year, weekStart.month, weekStart.day)),
        );
      }
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _weekLogs = logs;
      });
      await syncWorkoutReminders(plan);
    } catch (e) {
      debugPrint('Fitnes ma\'lumotlarini yuklashda xato: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openSetup() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FitnessPlanSetupScreen()),
    );
    if (created == true) _loadData();
  }

  Future<void> _openDay(Map<String, dynamic> day) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FitnessWorkoutDayScreen(plan: _plan!, day: day),
      ),
    );
    if (completed == true) _loadData();
  }

  bool _isDayCompletedThisWeek(int dayIndex) {
    return _weekLogs.any((log) => log['day_index'] == dayIndex);
  }

  Future<void> _pickReminderTime() async {
    final plan = _plan;
    if (plan == null) return;

    final currentTime = plan['reminder_time'] as String?;
    TimeOfDay initial = const TimeOfDay(hour: 19, minute: 0);
    if (currentTime != null && currentTime.contains(':')) {
      final parts = currentTime.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 19,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final days = (plan['days'] as List<dynamic>? ?? []);
    final weekdays = (plan['reminder_weekdays'] as List<dynamic>?)?.cast<int>() ??
        defaultWeekdaysFor(days.length);

    try {
      final updated = await _api.updateWorkoutPlan(plan['id'] as int, {
        'reminder_time': timeStr,
        'reminder_weekdays': weekdays,
      });
      setState(() => _plan = updated);
      await syncWorkoutReminders(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eslatma o\'rnatildi: $timeStr')),
        );
      }
    } catch (e) {
      debugPrint('Eslatma saqlashda xato: $e');
    }
  }

  Future<void> _disableReminder() async {
    final plan = _plan;
    if (plan == null) return;
    try {
      final updated = await _api.updateWorkoutPlan(plan['id'] as int, {'reminder_time': null});
      setState(() => _plan = updated);
      await syncWorkoutReminders(updated);
    } catch (e) {
      debugPrint('Eslatmani o\'chirishda xato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Fitnes trener',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.library),
          tooltip: 'Mashqlar kutubxonasi',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            );
          },
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _plan == null ? _buildNoPlanState() : _buildPlanView(),
            ),
    );
  }

  Widget _buildNoPlanState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GlassTokens.glassFill(context),
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
            border: Border.all(color: GlassTokens.glassBorder(context)),
            boxShadow: GlassTokens.glassShadow(context),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.dumbbell, size: 34, color: Colors.teal),
              ),
              const SizedBox(height: 16),
              Text(
                'Shaxsiy mashg\'ulot rejangizni tuzing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maqsadingiz va darajangizga mos haftalik reja: mashqlar, GIF ko\'rsatmalar va eslatmalar bilan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                  label: const Text(
                    'Reja tuzish',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLibraryCard(),
      ],
    );
  }

  Widget _buildPlanView() {
    final plan = _plan!;
    final byWeekday = planDaysByWeekday(plan);
    final today = DateTime.now().weekday;
    final todayDay = byWeekday[today];
    final completedCount = (plan['days'] as List<dynamic>? ?? [])
        .where((d) => _isDayCompletedThisWeek(d['day_index'] as int))
        .length;
    final daysPerWeek = plan['days_per_week'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Reja sarlavhasi + progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GlassTokens.glassFill(context),
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
            border: Border.all(color: GlassTokens.glassBorder(context)),
            boxShadow: GlassTokens.glassShadow(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'] as String? ?? 'Mashg\'ulot rejasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bu hafta: $completedCount/$daysPerWeek mashg\'ulot bajarildi',
                      style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openSetup,
                child: const Text('Yangi reja'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bugungi mashg'ulot
        if (todayDay != null)
          _buildTodayCard(todayDay)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bedDouble, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bugun dam olish kuni. Keyingi mashg\'ulotgacha kuch to\'plang! 😌',
                    style: TextStyle(color: GlassTokens.primaryText(context)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Hafta kunlari
        Text(
          'Haftalik reja',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: GlassTokens.primaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        ...byWeekday.entries.map((entry) => _buildDayTile(entry.key, entry.value, entry.key == today)),
        const SizedBox(height: 16),

        // Eslatma sozlamalari
        _buildReminderCard(plan),
        const SizedBox(height: 16),
        _buildLibraryCard(),
      ],
    );
  }

  Widget _buildTodayCard(Map<String, dynamic> day) {
    final exercises = (day['exercises'] as List<dynamic>? ?? []);
    final done = _isDayCompletedThisWeek(day['day_index'] as int);
    return InkWell(
      onTap: () => _openDay(day),
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: done
                ? [Colors.green.shade600, Colors.teal.shade700]
                : [Colors.teal.shade500, Colors.teal.shade800],
          ),
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(done ? LucideIcons.circleCheck : LucideIcons.play, color: Colors.white, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? 'Bugungi mashg\'ulot bajarildi! 🎉' : 'Bugungi mashg\'ulot',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day['title'] as String? ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercises.length} ta mashq',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(int weekday, Map<String, dynamic> day, bool isToday) {
    final done = _isDayCompletedThisWeek(day['day_index'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
        border: Border.all(
          color: isToday ? Colors.teal : GlassTokens.glassBorder(context),
          width: isToday ? 1.6 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => _openDay(day),
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.tealAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(LucideIcons.check, color: Colors.green, size: 20)
              : Text(
                  kWeekdayShortNames[weekday - 1],
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.teal),
                ),
        ),
        title: Text(
          day['title'] as String? ?? '',
          style: TextStyle(fontWeight: FontWeight.w700, color: GlassTokens.primaryText(context)),
        ),
        subtitle: Text(
          '${kWeekdayFullNames[weekday - 1]} · ${(day['exercises'] as List<dynamic>? ?? []).length} ta mashq',
          style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context)),
        ),
        trailing: Icon(LucideIcons.chevronRight, size: 18, color: GlassTokens.secondaryText(context)),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> plan) {
    final reminderTime = plan['reminder_time'] as String?;
    final enabled = reminderTime != null && reminderTime.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        border: Border.all(color: GlassTokens.glassBorder(context)),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? LucideIcons.bellRing : LucideIcons.bellOff,
            color: enabled ? Colors.teal : GlassTokens.secondaryText(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mashg\'ulot eslatmasi',
                  style: TextStyle(fontWeight: FontWeight.w700, color: GlassTokens.primaryText(context)),
                ),
                Text(
                  enabled ? 'Mashg\'ulot kunlari soat $reminderTime da' : 'O\'chirilgan',
                  style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context)),
                ),
              ],
            ),
          ),
          if (enabled)
            IconButton(
              onPressed: _disableReminder,
              icon: const Icon(LucideIcons.x, size: 18),
              tooltip: 'O\'chirish',
            ),
          TextButton(
            onPressed: _pickReminderTime,
            child: Text(enabled ? 'O\'zgartirish' : 'Yoqish'),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
        );
      },
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlassTokens.glassFill(context),
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          border: Border.all(color: GlassTokens.glassBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.library, color: Colors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mashqlar kutubxonasi',
                    style: TextStyle(fontWeight: FontWeight.w700, color: GlassTokens.primaryText(context)),
                  ),
                  Text(
                    '1300+ mashq: GIF va o\'zbekcha ko\'rsatmalar bilan',
                    style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context)),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: GlassTokens.secondaryText(context)),
          ],
        ),
      ),
    );
  }
}
