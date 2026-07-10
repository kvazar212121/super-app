import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../services/notification_helper.dart';
import '../../theme/glass_tokens.dart';

/// Workout eslatma bildirishnomalari ID diapazoni: 7100 + ISO weekday.
const int kWorkoutReminderBaseId = 7100;

const List<String> kWeekdayShortNames = [
  'Du',
  'Se',
  'Ch',
  'Pa',
  'Ju',
  'Sh',
  'Ya',
];
const List<String> kWeekdayFullNames = [
  'Dushanba',
  'Seshanba',
  'Chorshanba',
  'Payshanba',
  'Juma',
  'Shanba',
  'Yakshanba',
];

/// Haftasiga N kunlik reja uchun standart mashg'ulot kunlari (ISO weekday).
List<int> defaultWeekdaysFor(int daysPerWeek) {
  switch (daysPerWeek) {
    case 2:
      return [1, 4];
    case 3:
      return [1, 3, 5];
    case 4:
      return [1, 2, 4, 5];
    case 5:
      return [1, 2, 3, 4, 5];
    default:
      return [1, 2, 3, 4, 5, 6];
  }
}

/// Reja kunlarini hafta kunlariga biriktirish: weekday -> day (JSONB element).
Map<int, Map<String, dynamic>> planDaysByWeekday(Map<String, dynamic> plan) {
  final days = (plan['days'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  final reminderWeekdays = (plan['reminder_weekdays'] as List<dynamic>?)
      ?.cast<int>();
  final weekdays =
      (reminderWeekdays != null && reminderWeekdays.length == days.length)
      ? reminderWeekdays
      : defaultWeekdaysFor(days.length);

  final result = <int, Map<String, dynamic>>{};
  for (var i = 0; i < days.length && i < weekdays.length; i++) {
    result[weekdays[i]] = days[i];
  }
  return result;
}

/// Rejaning eslatmalarini lokal bildirishnomalar bilan sinxronlash.
Future<void> syncWorkoutReminders(Map<String, dynamic>? plan) async {
  final helper = NotificationHelper();
  await helper.cancelRange(
    kWorkoutReminderBaseId + 1,
    kWorkoutReminderBaseId + 7,
  );

  if (plan == null) return;
  final reminderTime = plan['reminder_time'] as String?;
  if (reminderTime == null || reminderTime.isEmpty) return;

  final parts = reminderTime.split(':');
  final hour = int.tryParse(parts[0]) ?? 19;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

  final byWeekday = planDaysByWeekday(plan);
  for (final entry in byWeekday.entries) {
    await helper.scheduleWeekly(
      kWorkoutReminderBaseId + entry.key,
      'Bugun mashg\'ulot kuni! 💪'.tr,
      entry.value['title'] as String? ?? 'Mashg\'ulot vaqti keldi'.tr,
      weekday: entry.key,
      hour: hour,
      minute: minute,
    );
  }
}

/// Mashq tafsilotlari bottom sheet: GIF, mushaklar, bajarish ko'rsatmalari.
/// [exercise] berilmasa [exerciseId] orqali backenddan yuklanadi.
Future<void> showExerciseDetailSheet(
  BuildContext context, {
  Map<String, dynamic>? exercise,
  int? exerciseId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: GlassTokens.glassFill(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GlassTokens.radiusLg),
      ),
    ),
    builder: (ctx) =>
        _ExerciseDetailSheet(exercise: exercise, exerciseId: exerciseId),
  );
}

class _ExerciseDetailSheet extends StatefulWidget {
  final Map<String, dynamic>? exercise;
  final int? exerciseId;

  const _ExerciseDetailSheet({this.exercise, this.exerciseId});

  @override
  State<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<_ExerciseDetailSheet> {
  Map<String, dynamic>? _exercise;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    if (_exercise == null && widget.exerciseId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final detail = await ApiService().getExerciseDetail(widget.exerciseId!);
      if (mounted) setState(() => _exercise = detail);
    } catch (e) {
      debugPrint('Mashq tafsilotini yuklashda xato: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        if (_isLoading || exercise == null) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final gifUrl = exercise['gif_url'] as String? ?? '';
        final instructions =
            (exercise['instructions_uz'] as List<dynamic>? ?? [])
                .cast<String>();

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: GlassTokens.glassBorder(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              exercise['name_uz'] as String? ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                exercise['body_part_uz'] ?? exercise['body_part'],
                exercise['target_uz'] ?? exercise['target'],
                exercise['equipment_uz'] ?? exercise['equipment'],
              ].whereType<String>().join(' · '),
              style: TextStyle(
                fontSize: 13,
                color: GlassTokens.secondaryText(context),
              ),
            ),
            const SizedBox(height: 16),
            if (gifUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: gifUrl,
                  height: 240,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 240,
                    color: Colors.tealAccent.withValues(alpha: 0.08),
                    child: const Icon(
                      LucideIcons.dumbbell,
                      size: 56,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Bajarish tartibi'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: GlassTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            ...instructions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
