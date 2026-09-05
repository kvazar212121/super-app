import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../services/step_tracker_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../calorie/calorie_profile_screen.dart';
import 'exercise_library_screen.dart';
import 'fitness_plan_setup_screen.dart';
import 'fitness_utils.dart';
import 'fitness_workout_day_screen.dart';
import '../../theme/lux_tokens.dart';

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

  // Energiya balansi
  final StepTrackerService _steps = StepTrackerService();
  Map<String, dynamic> _energy = {};
  bool _hasProfile = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initEnergy();
  }

  Future<void> _initEnergy() async {
    _steps.addListener(_onStepsChanged);
    await _steps.init();
    await _loadEnergy();
  }

  void _onStepsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadEnergy() async {
    try {
      await _steps.syncNow();
      final today = _formatDateForApi(DateTime.now());
      final energy = await _api.getActivitySummary(from: today, to: today);
      final profile = await _api.getNutritionProfile();
      if (mounted) {
        setState(() {
          _energy = energy;
          _hasProfile = profile != null && profile['weight_kg'] != null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _steps.removeListener(_onStepsChanged);
    super.dispose();
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
          from: _formatDateForApi(
            DateTime(weekStart.year, weekStart.month, weekStart.day),
          ),
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
    final weekdays =
        (plan['reminder_weekdays'] as List<dynamic>?)?.cast<int>() ??
        defaultWeekdaysFor(days.length);

    try {
      final updated = await _api.updateWorkoutPlan(plan['id'] as int, {
        'reminder_time': timeStr,
        'reminder_weekdays': weekdays,
      });
      if (!mounted) return;
      setState(() => _plan = updated);
      await syncWorkoutReminders(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Eslatma o\'rnatildi'.tr}: $timeStr')),
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
      final updated = await _api.updateWorkoutPlan(plan['id'] as int, {
        'reminder_time': null,
      });
      if (!mounted) return;
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
      title: 'Fitnes trener'.tr,
      actions: [
        IconButton(
          icon: Icon(LucideIcons.library),
          tooltip: 'Mashqlar kutubxonasi'.tr,
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

  /// Bugungi energiya kartasi: qadamlar + yoqilgan kaloriya (mashq + yurish).
  Widget _buildEnergyCard() {
    final steps = _steps.available && _steps.todaySteps > 0
        ? _steps.todaySteps
        : (_energy['steps'] as num?)?.toInt() ?? 0;
    final burned = (_energy['total_burned'] as num?)?.toDouble() ?? 0;
    final stepsCal = (_energy['steps_calories'] as num?)?.toDouble() ?? 0;
    final workoutCal = (_energy['workout_calories'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A102A43),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _energyStat(LucideIcons.footprints, '$steps', 'qadam'.tr),
              Container(width: 1, height: 40, color: Colors.white24),
              _energyStat(LucideIcons.flame, '${burned.round()}', 'kkal yoqildi'.tr),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${'Mashq'.tr}: ${workoutCal.round()} · ${'Yurish'.tr}: ${stepsCal.round()} kkal',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (!_hasProfile) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalorieProfileScreen(isFirstSetup: true),
                  ),
                );
                _loadEnergy();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Aniq hisob uchun bo\'y/vazningizni kiriting'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          if (steps == 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _enableSteps,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.footprints,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Qadam sanagichni yoqing'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _enableSteps() async {
    await _steps.enable();
    if (mounted) setState(() {});
  }

  Widget _energyStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildNoPlanState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEnergyCard(),
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
                  color: const Color(0xFF102A43).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.dumbbell,
                  size: 34,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Shaxsiy mashg\'ulot rejangizni tuzing'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GlassTokens.primaryText(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maqsadingiz va darajangizga mos haftalik reja: mashqlar, GIF ko\'rsatmalar va eslatmalar bilan.'
                    .tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTokens.secondaryText(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Reja tuzish'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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
        _buildEnergyCard(),
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
                      plan['name'] as String? ?? 'Mashg\'ulot rejasi'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: GlassTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'Bu hafta'.tr}: $completedCount/$daysPerWeek ${'mashg\'ulot bajarildi'.tr}',
                      style: TextStyle(
                        fontSize: 13,
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: _openSetup, child: Text('Yangi reja'.tr)),
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
              color: LuxTokens.goldSoft.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bedDouble, color: LuxTokens.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bugun dam olish kuni. Keyingi mashg\'ulotgacha kuch to\'plang! 😌'
                        .tr,
                    style: TextStyle(color: GlassTokens.primaryText(context)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Hafta kunlari
        Text(
          'Haftalik reja'.tr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: GlassTokens.primaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        ...byWeekday.entries.map(
          (entry) => _buildDayTile(entry.key, entry.value, entry.key == today),
        ),
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
          color: const Color(0xFF102A43),
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A102A43),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? LucideIcons.circleCheck : LucideIcons.play,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done
                        ? 'Bugungi mashg\'ulot bajarildi! 🎉'.tr
                        : 'Bugungi mashg\'ulot'.tr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercises.length} ${'ta mashq'.tr}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 24),
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
          color: isToday ? const Color(0xFF102A43) : GlassTokens.glassBorder(context),
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
                ? const Color(0xFF102A43)
                : const Color(0xFF102A43).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
              : Text(
                  kWeekdayShortNames[weekday - 1].tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
        ),
        title: Text(
          day['title'] as String? ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: GlassTokens.primaryText(context),
          ),
        ),
        subtitle: Text(
          '${kWeekdayFullNames[weekday - 1].tr} · ${(day['exercises'] as List<dynamic>? ?? []).length} ${'ta mashq'.tr}',
          style: TextStyle(
            fontSize: 12,
            color: GlassTokens.secondaryText(context),
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: GlassTokens.secondaryText(context),
        ),
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
            color: enabled ? const Color(0xFF102A43) : GlassTokens.secondaryText(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mashg\'ulot eslatmasi'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: GlassTokens.primaryText(context),
                  ),
                ),
                Text(
                  enabled
                      ? '${'Mashg\'ulot kunlari soat'.tr} $reminderTime ${'da'.tr}'
                      : 'O\'chirilgan'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            IconButton(
              onPressed: _disableReminder,
              icon: Icon(LucideIcons.x, size: 18),
              tooltip: 'O\'chirish'.tr,
            ),
          TextButton(
            onPressed: _pickReminderTime,
            child: Text(enabled ? 'O\'zgartirish'.tr : 'Yoqish'.tr),
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
                color: const Color(0xFF102A43).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.library,
                color: Color(0xFF102A43),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mashqlar kutubxonasi'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GlassTokens.primaryText(context),
                    ),
                  ),
                  Text(
                    '1300+ mashq: GIF va o\'zbekcha ko\'rsatmalar bilan'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlassTokens.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: GlassTokens.secondaryText(context),
            ),
          ],
        ),
      ),
    );
  }
}
