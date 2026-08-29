import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/locale_controller.dart';
import '../../services/api_service.dart';
import '../../services/meal_reminder_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../theme/lux_tokens.dart';

/// Ozuqaviy profil: kunlik kaloriya maqsadini hisoblash uchun ma'lumotlar.
class CalorieProfileScreen extends StatefulWidget {
  final bool isFirstSetup;

  const CalorieProfileScreen({super.key, this.isFirstSetup = false});

  @override
  State<CalorieProfileScreen> createState() => _CalorieProfileScreenState();
}

class _CalorieProfileScreenState extends State<CalorieProfileScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  double? _computedGoal;
  bool _mealOn = MealReminderService().enabled;

  String _sex = 'male';
  String _activityLevel = 'light';
  String _goal = 'maintain';
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _manualGoalController = TextEditingController();

  static const _activityNames = {
    'sedentary': 'Kam harakat (ofis ishi)',
    'light': 'Yengil (haftada 1-2 mashq)',
    'moderate': 'O\'rtacha (haftada 3-4 mashq)',
    'active': 'Faol (haftada 5-6 mashq)',
    'very_active': 'Juda faol (har kuni og\'ir mashq)',
  };

  static const _goalNames = {
    'lose': 'Vazn yo\'qotish',
    'maintain': 'Vaznni saqlash',
    'gain': 'Vazn olish',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _manualGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.getNutritionProfile();
      if (profile != null && mounted) {
        setState(() {
          _sex = profile['sex'] as String? ?? 'male';
          _activityLevel = profile['activity_level'] as String? ?? 'light';
          _goal = profile['goal'] as String? ?? 'maintain';
          _ageController.text = (profile['age'] ?? '').toString();
          _heightController.text =
              ((profile['height_cm'] as num?)?.round() ?? '').toString();
          _weightController.text = (profile['weight_kg'] ?? '').toString();
          if (profile['manual_calorie_goal'] != null) {
            _manualGoalController.text = (profile['manual_calorie_goal'] as num)
                .round()
                .toString();
          }
          _computedGoal = (profile['daily_calorie_goal'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      debugPrint('Profil yuklashda xato: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final manualGoal = double.tryParse(_manualGoalController.text);
      final result = await _api.saveNutritionProfile({
        'sex': _sex,
        'age': int.parse(_ageController.text),
        'height_cm': double.parse(_heightController.text.replaceAll(',', '.')),
        'weight_kg': double.parse(_weightController.text.replaceAll(',', '.')),
        'activity_level': _activityLevel,
        'goal': _goal,
        if (manualGoal != null && manualGoal > 0)
          'manual_calorie_goal': manualGoal,
      });
      if (!mounted) return;
      final goal = (result['daily_calorie_goal'] as num?)?.round();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Saqlandi! Kunlik maqsad'.tr}: $goal ${'kkal'.tr}'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Profil saqlashda xato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saqlab bo\'lmadi. Ma\'lumotlarni tekshiring.'.tr),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateNumber(String? value, double min, double max, String label) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null) return '$label ${'kiriting'.tr}';
    if (parsed < min || parsed > max) {
      return '$min–$max ${'oralig\'ida bo\'lsin'.tr}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Ozuqaviy profil'.tr,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.isFirstSetup)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A227).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          GlassTokens.radiusSm,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            color: Color(0xFFC9A227),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kunlik kaloriya maqsadini hisoblash uchun o\'zingiz haqingizda ma\'lumot kiriting.'
                                  .tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: GlassTokens.primaryText(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_computedGoal != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GlassTokens.glassFill(context),
                        borderRadius: BorderRadius.circular(
                          GlassTokens.radiusMd,
                        ),
                        border: Border.all(
                          color: GlassTokens.glassBorder(context),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.flame,
                            color: Color(0xFFC9A227),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${'Kunlik maqsad'.tr}: ${_computedGoal!.round()} ${'kkal'.tr}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: GlassTokens.primaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildSectionLabel('Jins'.tr),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoice(
                          'male',
                          'Erkak'.tr,
                          _sex,
                          (v) => setState(() => _sex = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoice(
                          'female',
                          'Ayol'.tr,
                          _sex,
                          (v) => setState(() => _sex = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: GlassTokens.primaryText(context),
                          ),
                          decoration: _inputDecoration('Yosh'.tr),
                          validator: (v) =>
                              _validateNumber(v, 10, 100, 'Yosh'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: GlassTokens.primaryText(context),
                          ),
                          decoration: _inputDecoration('Bo\'y (sm)'.tr),
                          validator: (v) =>
                              _validateNumber(v, 100, 250, 'Bo\'y'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color: GlassTokens.primaryText(context),
                          ),
                          decoration: _inputDecoration('Vazn (kg)'.tr),
                          validator: (v) =>
                              _validateNumber(v, 25, 350, 'Vazn'.tr),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildSectionLabel('Faollik darajasi'.tr),
                  ..._activityNames.entries.map(
                    (entry) => RadioListTile<String>(
                      value: entry.key,
                      groupValue: _activityLevel,
                      dense: true,
                      activeColor: const Color(0xFFC9A227),
                      title: Text(
                        entry.value.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: GlassTokens.primaryText(context),
                        ),
                      ),
                      onChanged: (v) => setState(() => _activityLevel = v!),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildSectionLabel('Maqsad'.tr),
                  Row(
                    children: _goalNames.entries
                        .map(
                          (entry) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildChoice(
                                entry.key,
                                entry.value.tr,
                                _goal,
                                (v) => setState(() => _goal = v),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _manualGoalController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: GlassTokens.primaryText(context)),
                    decoration: _inputDecoration(
                      'Qo\'lda maqsad (kkal, ixtiyoriy)'.tr,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Aqlli ovqat-monitoring toggle — foydalanuvchi o'chira oladi.
                  Container(
                    decoration: BoxDecoration(
                      color: LuxTokens.surface,
                      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: SwitchListTile(
                      value: _mealOn,
                      activeThumbColor: const Color(0xFFC9A227),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      secondary: const Icon(
                        LucideIcons.bellRing,
                        color: Color(0xFFC9A227),
                      ),
                      title: Text(
                        'Ovqat eslatmalari'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Kuniga 3 marta "nima yedingiz?" deb eslatib turadi'.tr,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onChanged: (v) {
                        setState(() => _mealOn = v);
                        MealReminderService().setEnabled(v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A227),
                        elevation: 4,
                        shadowColor: const Color(0xFFC9A227).withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GlassTokens.radiusSm,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Saqlash'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: GlassTokens.primaryText(context),
        ),
      ),
    );
  }

  Widget _buildChoice(
    String value,
    String label,
    String groupValue,
    ValueChanged<String> onTap,
  ) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC9A227) : GlassTokens.glassFill(context),
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          border: Border.all(
            color: selected
                ? const Color(0xFFC9A227)
                : GlassTokens.glassBorder(context),
          ),
          boxShadow: GlassTokens.glassShadow(context),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : GlassTokens.primaryText(context),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
      ),
    );
  }
}
