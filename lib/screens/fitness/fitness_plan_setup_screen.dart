import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'fitness_utils.dart';
import '../../theme/lux_tokens.dart';

/// Shaxsiy mashg'ulot rejasini tuzish: 4 savollik wizard + natija ko'rinishi.
class FitnessPlanSetupScreen extends StatefulWidget {
  const FitnessPlanSetupScreen({super.key});

  @override
  State<FitnessPlanSetupScreen> createState() => _FitnessPlanSetupScreenState();
}

class _FitnessPlanSetupScreenState extends State<FitnessPlanSetupScreen> {
  final ApiService _api = ApiService();

  String _goal = 'general_fit';
  String _level = 'beginner';
  int _daysPerWeek = 3;
  String _equipmentMode = 'home';

  bool _isGenerating = false;
  Map<String, dynamic>? _generatedPlan;

  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  static const _goalOptions = {
    'weight_loss': ('Vazn yo\'qotish', LucideIcons.flame),
    'muscle_gain': ('Mushak o\'stirish', LucideIcons.bicepsFlexed),
    'general_fit': ('Umumiy fitnes', LucideIcons.heartPulse),
  };

  static const _levelOptions = {
    'beginner': 'Boshlang\'ich',
    'intermediate': 'O\'rta',
    'advanced': 'Yuqori',
  };

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final plan = await _api.generateWorkoutPlan({
        'goal': _goal,
        'level': _level,
        'days_per_week': _daysPerWeek,
        'equipment_mode': _equipmentMode,
      });
      if (mounted) setState(() => _generatedPlan = plan);
    } catch (e) {
      debugPrint('Reja tuzishda xato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reja tuzib bo\'lmadi. Qayta urinib ko\'ring.'.tr),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _start() async {
    final plan = _generatedPlan;
    if (plan == null) return;

    if (_reminderEnabled) {
      final timeStr =
          '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
      try {
        final updated = await _api.updateWorkoutPlan(plan['id'] as int, {
          'reminder_time': timeStr,
          'reminder_weekdays': defaultWeekdaysFor(
            (plan['days'] as List<dynamic>).length,
          ),
        });
        await syncWorkoutReminders(updated);
      } catch (e) {
        debugPrint('Eslatma sozlashda xato: $e');
      }
    } else {
      await syncWorkoutReminders(plan);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Reja tuzish'.tr,
      body: _generatedPlan == null ? _buildWizard() : _buildResult(),
    );
  }

  Widget _buildWizard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionLabel('1. Maqsadingiz nima?'.tr),
        ..._goalOptions.entries.map((entry) {
          final selected = _goal == entry.key;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _goal = entry.key),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? LuxTokens.gold
                      : GlassTokens.glassFill(context),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                  border: Border.all(
                    color: selected
                        ? LuxTokens.gold
                        : GlassTokens.glassBorder(context),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      entry.value.$2,
                      color: selected ? Colors.white : LuxTokens.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value.$1.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : GlassTokens.primaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        SizedBox(height: 16),
        _buildSectionLabel('2. Darajangiz?'.tr),
        Row(
          children: _levelOptions.entries
              .map(
                (entry) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(
                      entry.value.tr,
                      _level == entry.key,
                      () => setState(() => _level = entry.key),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 24),
        _buildSectionLabel('3. Haftasiga necha kun shug\'ullanasiz?'.tr),
        Row(
          children: [2, 3, 4, 5, 6]
              .map(
                (d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(
                      '$d',
                      _daysPerWeek == d,
                      () => setState(() => _daysPerWeek = d),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 24),
        _buildSectionLabel('4. Qayerda shug\'ullanasiz?'.tr),
        Row(
          children: [
            Expanded(
              child: _buildChip(
                '🏠 Uyda'.tr,
                _equipmentMode == 'home',
                () => setState(() => _equipmentMode = 'home'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChip(
                '🏋️ Zalda'.tr,
                _equipmentMode == 'gym',
                () => setState(() => _equipmentMode = 'gym'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxTokens.gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
              ),
            ),
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
            label: Text(
              _isGenerating ? 'Tuzilmoqda…'.tr : 'Reja tuzish'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final plan = _generatedPlan!;
    final days = (plan['days'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final weekdays = defaultWeekdaysFor(days.length);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [LuxTokens.gold, LuxTokens.goldDim],
            ),
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.circleCheck,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'] as String? ?? 'Rejangiz tayyor!'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${'Haftasiga'.tr} ${days.length} ${'kun'.tr} · ${_levelOptions[_level]!.tr} ${'daraja'.tr}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...days.asMap().entries.map((entry) {
          final day = entry.value;
          final weekday = entry.key < weekdays.length
              ? weekdays[entry.key]
              : null;
          final exercises = (day['exercises'] as List<dynamic>? ?? []);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GlassTokens.glassFill(context),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
              border: Border.all(color: GlassTokens.glassBorder(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LuxTokens.goldSoft.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    weekday != null
                        ? kWeekdayShortNames[weekday - 1].tr
                        : '${entry.key + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: LuxTokens.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day['title'] as String? ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      Text(
                        '${exercises.length} ${'ta mashq'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          color: GlassTokens.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _reminderEnabled,
          activeThumbColor: LuxTokens.gold,
          title: Text(
            'Mashg\'ulot kunlari eslatma'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: GlassTokens.primaryText(context),
            ),
          ),
          subtitle: Text(
            '${'Soat'.tr} ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')} ${'da'.tr}',
            style: TextStyle(
              fontSize: 12,
              color: GlassTokens.secondaryText(context),
            ),
          ),
          secondary: IconButton(
            icon: const Icon(LucideIcons.clock, color: LuxTokens.gold),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
              );
              if (picked != null) setState(() => _reminderTime = picked);
            },
          ),
          onChanged: (v) => setState(() => _reminderEnabled = v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _start,
            style: ElevatedButton.styleFrom(
              backgroundColor: LuxTokens.gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
              ),
            ),
            child: Text(
              'Boshlash 💪'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isGenerating ? null : _generate,
          child: Text('Boshqa variant tuzish'.tr),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: GlassTokens.primaryText(context),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? LuxTokens.gold : GlassTokens.glassFill(context),
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          border: Border.all(
            color: selected ? LuxTokens.gold : GlassTokens.glassBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : GlassTokens.primaryText(context),
          ),
        ),
      ),
    );
  }
}
