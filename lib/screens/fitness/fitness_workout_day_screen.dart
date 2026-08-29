import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../services/notification_helper.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'fitness_utils.dart';
import '../../theme/lux_tokens.dart';

/// Bir kunlik mashg'ulot: mashqlar ro'yxati, GIF'lar, bajarish belgilari.
class FitnessWorkoutDayScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> day;

  const FitnessWorkoutDayScreen({
    super.key,
    required this.plan,
    required this.day,
  });

  @override
  State<FitnessWorkoutDayScreen> createState() =>
      _FitnessWorkoutDayScreenState();
}

class _FitnessWorkoutDayScreenState extends State<FitnessWorkoutDayScreen> {
  final ApiService _api = ApiService();
  final Set<int> _completedIds = {};
  bool _isSaving = false;

  List<Map<String, dynamic>> get _exercises =>
      (widget.day['exercises'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  Future<void> _finishWorkout() async {
    setState(() => _isSaving = true);
    try {
      final res = await _api.logWorkout({
        'plan_id': widget.plan['id'],
        'day_index': widget.day['day_index'],
        'date': DateTime.now().toUtc().toIso8601String(),
        'completed_exercises': _completedIds.toList(),
      });
      final burned = (res['calories_burned'] as num?)?.round() ?? 0;
      await NotificationHelper().showNotification(
        9001,
        'Barakalla! 🎉'.tr,
        '${widget.day['title']} ${'mashg\'uloti yakunlandi. Shu zaylda davom eting!'.tr}',
      );
      if (mounted && burned > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFB8921F),
            content: Text('🔥 ~$burned ${'kkal yoqildi'.tr}'),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Mashg\'ulotni saqlashda xato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saqlab bo\'lmadi. Qayta urinib ko\'ring.'.tr),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises;
    final allDone =
        _completedIds.length == exercises.length && exercises.isNotEmpty;

    return GlassScaffold(
      showBackButton: true,
      title: widget.day['title'] as String? ?? 'Mashg\'ulot'.tr,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: exercises.length,
              itemBuilder: (ctx, index) =>
                  _buildExerciseCard(exercises[index], index),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allDone ? Colors.green : LuxTokens.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          LucideIcons.circleCheck,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    '${'Mashg\'ulotni yakunlash'.tr} (${_completedIds.length}/${exercises.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final exerciseId = exercise['exercise_id'] as int? ?? index;
    final done = _completedIds.contains(exerciseId);
    final gifUrl = exercise['gif_url'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GlassTokens.glassFill(context),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        border: Border.all(
          color: done ? Colors.green : GlassTokens.glassBorder(context),
          width: done ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => showExerciseDetailSheet(context, exerciseId: exerciseId),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: gifUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: gifUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _gifPlaceholder(),
                        errorWidget: (_, _, _) => _gifPlaceholder(),
                      )
                    : _gifPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name_uz'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: GlassTokens.primaryText(context),
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise['sets']} ${'yondashuv'.tr} × ${exercise['reps']} ${'takror'.tr} · ${'dam'.tr} ${exercise['rest_sec']}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: done,
                activeColor: Colors.green,
                shape: const CircleBorder(),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _completedIds.add(exerciseId);
                    } else {
                      _completedIds.remove(exerciseId);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gifPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: LuxTokens.goldSoft.withValues(alpha: 0.1),
      child: const Icon(LucideIcons.dumbbell, color: LuxTokens.gold, size: 26),
    );
  }
}
