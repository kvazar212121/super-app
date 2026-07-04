import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/api_service.dart';
import '../../theme/glass_tokens.dart';
import '../../widgets/glass/glass_scaffold.dart';
import 'calorie_home_screen.dart';

/// Taom rasmini AI orqali tahlil qilish va natijani tahrirlab saqlash ekrani.
class CalorieAnalyzeScreen extends StatefulWidget {
  final File imageFile;

  const CalorieAnalyzeScreen({super.key, required this.imageFile});

  @override
  State<CalorieAnalyzeScreen> createState() => _CalorieAnalyzeScreenState();
}

class _CalorieAnalyzeScreenState extends State<CalorieAnalyzeScreen> {
  final ApiService _api = ApiService();

  bool _isAnalyzing = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _photoUrl;
  double? _confidence;
  String _mealType = 'snack';

  final _nameController = TextEditingController();
  final _portionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mealType = _guessMealType();
    _analyze();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  String _guessMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 16) return 'lunch';
    if (hour >= 18 && hour < 23) return 'dinner';
    return 'snack';
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    try {
      final result = await _api.analyzeFoodPhoto(widget.imageFile.path);
      if (!mounted) return;
      setState(() {
        _photoUrl = result['photo_url'] as String?;
        _confidence = (result['confidence'] as num?)?.toDouble();
        _nameController.text = result['dish_name_uz'] as String? ?? '';
        _portionController.text = ((result['portion_grams'] as num?)?.round() ?? '').toString();
        _caloriesController.text = ((result['calories'] as num?)?.round() ?? 0).toString();
        _proteinController.text = ((result['protein_g'] as num?)?.round() ?? 0).toString();
        _fatController.text = ((result['fat_g'] as num?)?.round() ?? 0).toString();
        _carbsController.text = ((result['carbs_g'] as num?)?.round() ?? 0).toString();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      setState(() {
        if (status == 422) {
          _errorMessage = 'Rasmda taom aniqlanmadi. Boshqa rasm olib ko\'ring.';
        } else {
          _errorMessage = (e.response?.data is Map ? e.response?.data['detail'] as String? : null) ??
              'AI bilan bog\'lanib bo\'lmadi. Qayta urinib ko\'ring.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Xatolik yuz berdi. Qayta urinib ko\'ring.');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  double _parseNum(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final portion = _parseNum(_portionController);
      await _api.logMeal({
        'meal_type': _mealType,
        'dish_name': _nameController.text.trim(),
        if (portion > 0) 'portion_grams': portion,
        'calories': _parseNum(_caloriesController),
        'protein_g': _parseNum(_proteinController),
        'fat_g': _parseNum(_fatController),
        'carbs_g': _parseNum(_carbsController),
        if (_photoUrl != null) 'photo_url': _photoUrl,
        if (_confidence != null) 'ai_confidence': _confidence,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Saqlashda xato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saqlab bo\'lmadi. Qayta urinib ko\'ring.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      showBackButton: true,
      title: 'Taom tahlili',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
            child: Image.file(
              widget.imageFile,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing)
            _buildAnalyzingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else
            _buildResultForm(),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'AI taomni aniqlamoqda…',
            style: TextStyle(fontWeight: FontWeight.w700, color: GlassTokens.primaryText(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu bir necha soniya olishi mumkin',
            style: TextStyle(fontSize: 13, color: GlassTokens.secondaryText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(LucideIcons.imageOff, size: 48, color: Colors.orangeAccent),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: GlassTokens.primaryText(context)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(LucideIcons.camera),
                label: const Text('Boshqa rasm'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _analyze,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                label: const Text('Qayta urinish', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_confidence != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Taxminiy baho (ishonch: ${(_confidence! * 100).round()}%). Kerak bo\'lsa tahrirlang.',
                    style: TextStyle(fontSize: 12, color: GlassTokens.secondaryText(context)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Taom nomi', LucideIcons.utensils),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_portionController, 'Porsiya (g)', LucideIcons.scale, isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_caloriesController, 'Kaloriya (kkal)', LucideIcons.flame, isNumber: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_proteinController, 'Oqsil (g)', LucideIcons.beef, isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_fatController, 'Yog\' (g)', LucideIcons.droplet, isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_carbsController, 'Uglevod (g)', LucideIcons.wheat, isNumber: true)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Qaysi ovqat?',
          style: TextStyle(fontWeight: FontWeight.w700, color: GlassTokens.primaryText(context)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: kMealTypeNames.entries.map((entry) {
            final selected = _mealType == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              selectedColor: Colors.redAccent,
              labelStyle: TextStyle(
                color: selected ? Colors.white : GlassTokens.primaryText(context),
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _mealType = entry.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlassTokens.radiusSm)),
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Saqlash', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: GlassTokens.primaryText(context)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(GlassTokens.radiusSm)),
      ),
    );
  }
}
